import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localsend_app/model/state/network_state.dart';
import 'package:localsend_app/util/platform_check.dart';
import 'package:network_info_plus/network_info_plus.dart' as plugin;

final networkStateProvider = NotifierProvider<NetworkStateNotifier, NetworkState>(() {
  return NetworkStateNotifier();
});

StreamSubscription? _subscription;

class NetworkStateNotifier extends Notifier<NetworkState> {
  NetworkStateNotifier();

  @override
  NetworkState build() {
    // ignore: discarded_futures
    init();

    return const NetworkState(
      localIps: [],
      initialized: false,
    );
  }

  Future<void> init() async {
    if (!kIsWeb) {
      // ignore: unawaited_futures
      _subscription?.cancel();

      if (checkPlatform([TargetPlatform.windows])) {
        // https://github.com/localsend/localsend/issues/12
        _subscription = Stream.periodic(const Duration(seconds: 5), (_) {}).listen((_) async {
          state = NetworkState(
            localIps: await _getIp(),
            initialized: true,
          );
        });
      } else {
        _subscription = Connectivity().onConnectivityChanged.listen((_) async {
          state = NetworkState(
            localIps: await _getIp(),
            initialized: true,
          );
        });
      }
    }

    state = NetworkState(
      localIps: await _getIp(),
      initialized: true,
    );
  }

  Future<List<String>> _getIp() async {
    final info = plugin.NetworkInfo();
    String? ip;
    try {
      ip = await info.getWifiIP();
    } catch (e) {
      print(e);
    }

    List<String> nativeResult = [];
    if (!kIsWeb) {
      try {
        // fallback with dart:io NetworkInterface
        final result = (await NetworkInterface.list()).map((networkInterface) => networkInterface.addresses).expand((ip) => ip);
        nativeResult = result.where((ip) => ip.type == InternetAddressType.IPv4).map((address) => address.address).toList();
      } catch (e, st) {
        print(e);
        print(st);
      }
    }

    print('New network state: $ip');

    return rankIpAddresses(nativeResult, ip);
  }
}

List<String> rankIpAddresses(List<String> nativeResult, String? thirdPartyResult) {
  if (thirdPartyResult == null) {
    // only take the list
    return nativeResult._rankIpAddresses(null);
  } else if (nativeResult.isEmpty) {
    // only take the first IP from third party library
    return [thirdPartyResult];
  } else if (thirdPartyResult.endsWith('.1')) {
    // merge
    return {thirdPartyResult, ...nativeResult}.toList()._rankIpAddresses(null);
  } else {
    // merge but prefer result from third party library
    return {thirdPartyResult, ...nativeResult}.toList()._rankIpAddresses(thirdPartyResult);
  }
}

/// Sorts Ip addresses with first being the most likely primary local address
/// Currently,
/// - sorts ending with ".1" last
/// - primary is always first
extension ListIpExt on List<String> {
  List<String> _rankIpAddresses(String? primary) {
    return sorted((a, b) {
      int scoreA = a == primary ? 10 : (a.endsWith('.1') ? 0 : 1);
      int scoreB = b == primary ? 10 : (b.endsWith('.1') ? 0 : 1);
      return scoreB.compareTo(scoreA);
    });
  }
}
