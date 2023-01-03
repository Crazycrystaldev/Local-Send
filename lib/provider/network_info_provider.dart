import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localsend_app/model/network_info.dart';
import 'package:network_info_plus/network_info_plus.dart' as plugin;

final networkInfoProvider = StateNotifierProvider<NetworkInfoNotifier, NetworkInfo?>((ref) => NetworkInfoNotifier());

StreamSubscription<ConnectivityResult>? _subscription;

class NetworkInfoNotifier extends StateNotifier<NetworkInfo?> {
  NetworkInfoNotifier() : super(null) {
    init();
  }

  Future<void> init() async {
    if (!kIsWeb) {
      _subscription?.cancel();
      _subscription = Connectivity().onConnectivityChanged.listen((_) async  {
        state = await _getInfo();
      });
    }
    state = await _getInfo();
  }

  Future<NetworkInfo> _getInfo() async {
    final info = plugin.NetworkInfo();
    String? ip;
    String? mask;
    try {
      ip = await info.getWifiIP();
      mask = await info.getWifiSubmask();
    } catch (e) {
      print(e);
    }

    if (!kIsWeb && ip == null) {
      try {
        // fallback with dart:io NetworkInterface
        final result = (await NetworkInterface.list()).map((networkInterface) => networkInterface.addresses).expand((ip) => ip);
        ip = result.firstWhereOrNull((ip) => ip.type == InternetAddressType.IPv4)?.address;
      } catch (e, st) {
        print(e);
        print(st);
      }
    }

    print('New network state: $ip ($mask)');

    return NetworkInfo(
      localIp: ip,
      netMask: mask,
    );
  }
}
