import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localsend_app/model/cross_file.dart';
import 'package:localsend_app/model/device.dart';
import 'package:localsend_app/model/dto/file_dto.dart';
import 'package:localsend_app/model/dto/info_dto.dart';
import 'package:localsend_app/model/dto/send_request_dto.dart';
import 'package:localsend_app/model/file_status.dart';
import 'package:localsend_app/model/file_type.dart';
import 'package:localsend_app/model/send_mode.dart';
import 'package:localsend_app/model/state/send/send_session_state.dart';
import 'package:localsend_app/model/state/send/sending_file.dart';
import 'package:localsend_app/model/session_status.dart';
import 'package:localsend_app/pages/home_page.dart';
import 'package:localsend_app/pages/progress_page.dart';
import 'package:localsend_app/pages/send_page.dart';
import 'package:localsend_app/provider/device_info_provider.dart';
import 'package:localsend_app/provider/dio_provider.dart';
import 'package:localsend_app/provider/progress_provider.dart';
import 'package:localsend_app/provider/selection/selected_sending_files_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/util/api_route_builder.dart';
import 'package:localsend_app/util/cache_helper.dart';
import 'package:routerino/routerino.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// The provider for **sending** files.
/// The opposite of [serverProvider].
final sendProvider = StateNotifierProvider<SendNotifier, Map<String, SendSessionState>>((ref) {
  return SendNotifier(ref);
});

class SendNotifier extends StateNotifier<Map<String, SendSessionState>> {
  final Ref _ref;

  SendNotifier(this._ref) : super({});

  /// Starts a session.
  /// If [background] is true, then the session closes itself on success and no pages will be open
  /// If [background] is false, then this method will open pages by itself and waits for user input to close the session.
  Future<void> startSession({
    required Device target,
    required List<CrossFile> files,
    required bool background,
  }) async {
    final requestDio = _ref.read(dioProvider(DioType.longLiving));
    final uploadDio = _ref.read(dioProvider(DioType.longLiving));
    final cancelToken = CancelToken();
    final sessionId = _uuid.v4();

    final requestState = SendSessionState(
      sessionId: sessionId,
      background: background,
      status: SessionStatus.waiting,
      target: target,
      files: Map.fromEntries(await Future.wait(files.map((file) async {
        final id = _uuid.v4();
        return MapEntry(
          id,
          SendingFile(
            file: FileDto(
              id: id,
              fileName: file.name,
              size: file.size,
              fileType: file.fileType,
              preview: files.length == 1 && files.first.fileType == FileType.text && files.first.bytes != null
                  ? utf8.decode(files.first.bytes!) // send simple message by embedding it into the preview
                  : null,
            ),
            status: FileStatus.queue,
            token: null,
            asset: file.asset,
            path: file.path,
            bytes: file.bytes,
            errorMessage: null,
          ),
        );
      }))),
      startTime: null,
      endTime: null,
      cancelToken: cancelToken,
      errorMessage: null,
    );

    final originDevice = _ref.read(deviceInfoProvider);
    final requestDto = SendRequestDto(
      info: InfoDto(
        alias: originDevice.alias,
        deviceModel: originDevice.deviceModel,
        deviceType: originDevice.deviceType,
      ),
      files: {
        for (final file in requestState.files.values) file.file.id: file.file,
      },
    );

    state = state.updateSession(
      sessionId: sessionId,
      state: (_) => requestState,
    );

    if (!background) {
      // ignore: use_build_context_synchronously
      Routerino.context.push(() => SendPage(sessionId: sessionId), transition: RouterinoTransition.fade);
    }

    final Response response;
    try {
      response = await requestDio.post(
        ApiRoute.sendRequest.target(target),
        data: requestDto.toJson(),
        cancelToken: cancelToken,
      );
    } catch (e) {
      if (e is DioError && e.response?.statusCode == 403) {
        state = state.updateSession(
          sessionId: sessionId,
          state: (s) => s?.copyWith(
            status: SessionStatus.declined,
          ),
        );
      } else if (e is DioError && e.response?.statusCode == 409) {
        state = state.updateSession(
          sessionId: sessionId,
          state: (s) => s?.copyWith(
            status: SessionStatus.recipientBusy,
          ),
        );
      } else {
        state = state.updateSession(
          sessionId: sessionId,
          state: (s) => s?.copyWith(
            status: SessionStatus.finishedWithErrors,
            errorMessage: e.humanErrorMessage,
          ),
        );
      }
      return;
    }

    final responseMap = response.data as Map;
    if (responseMap.isEmpty) {
      // receiver has nothing selected

      if (state[sessionId]?.background == false) {
        // ignore: use_build_context_synchronously
        Routerino.context.pushRootImmediately(() => const HomePage(appStart: false));
      }

      state = state.removeSession(_ref, sessionId);
      return;
    }

    final sendingFiles = {
      for (final file in requestState.files.values)
        file.file.id:
            responseMap.containsKey(file.file.id) ? file.copyWith(token: responseMap[file.file.id]) : file.copyWith(status: FileStatus.skipped),
    };

    if (state[sessionId]?.background == false) {
      final background = _ref.read(settingsProvider.select((s) => s.sendMode == SendMode.multiple));

      // ignore: use_build_context_synchronously
      Routerino.context.pushAndRemoveUntilImmediately(
        removeUntil: SendPage,
        builder: () => ProgressPage(
          showAppBar: background,
          closeSessionOnClose: !background,
          sessionId: sessionId,
        ),
      );
    }

    state = state.updateSession(
      sessionId: sessionId,
      state: (s) => s?.copyWith(
        status: SessionStatus.sending,
        files: sendingFiles,
      ),
    );

    await _send(sessionId, uploadDio, target, sendingFiles);
  }

  Future<void> _send(String sessionId, Dio dio, Device target, Map<String, SendingFile> files) async {
    bool hasError = false;

    state = state.updateSession(
      sessionId: sessionId,
      state: (s) => s?.copyWith(startTime: DateTime.now().millisecondsSinceEpoch),
    );

    for (final file in files.values) {
      final token = file.token;
      if (token == null) {
        continue;
      }

      print('Sending ${file.file.fileName}');
      state = state.updateSession(
        sessionId: sessionId,
        state: (s) => s?.withFileStatus(file.file.id, FileStatus.sending, null),
      );

      String? fileError;
      try {
        final cancelToken = CancelToken();
        state = state.updateSession(
          sessionId: sessionId,
          state: (s) => s?.copyWith(cancelToken: cancelToken),
        );
        await dio.post(
          ApiRoute.send.target(target, query: {
            'fileId': file.file.id,
            'token': token,
          }),
          options: Options(
            headers: {
              'Content-Length': file.file.size,
            },
          ),
          data: file.path != null ? File(file.path!).openRead() : Stream.fromIterable([file.bytes!]),
          onSendProgress: (curr, total) {
            _ref.read(progressProvider.notifier).setProgress(
                  sessionId: sessionId,
                  fileId: file.file.id,
                  progress: curr / total,
                );
          },
          cancelToken: cancelToken,
        );
      } catch (e, st) {
        fileError = e.humanErrorMessage;
        hasError = true;
        print(e);
        print(st);
      }

      state = state.updateSession(
        sessionId: sessionId,
        state: (s) => s?.withFileStatus(file.file.id, fileError != null ? FileStatus.failed : FileStatus.finished, fileError),
      );
    }

    if (state[sessionId]?.background == true) {
      state = state.removeSession(_ref, sessionId);
    } else {
      state = state.updateSession(
        sessionId: sessionId,
        state: (s) => s?.copyWith(
          status: hasError ? SessionStatus.finishedWithErrors : SessionStatus.finished,
          endTime: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }

    print('Files sent successfully.');
  }

  /// Closes the send-session and sends a cancel event to the receiver.
  void cancelSession(String sessionId) {
    final sessionState = state[sessionId];
    if (sessionState == null) {
      return;
    }
    final target = sessionState.target;
    sessionState.cancelToken?.cancel(); // cancel current request
    state = state.removeSession(_ref, sessionId);
    if (sessionState.status == SessionStatus.finished && _ref.read(settingsProvider.select((s) => s.sendMode == SendMode.single))) {
      // clear selected files
      _ref.read(selectedSendingFilesProvider.notifier).reset();
      clearCache();
    }

    // notify the receiver
    _ref.read(dioProvider(DioType.discovery)).post(ApiRoute.cancel.target(target)).then((_) {}).catchError((e) {
      print(e);
    });
  }

  void setBackground(String sessionId, bool background) {
    state = state.updateSession(sessionId: sessionId, state: (s) => s?.copyWith(background: background));
  }
}

extension on Map<String, SendSessionState> {
  Map<String, SendSessionState> updateSession({
    required String sessionId,
    required SendSessionState? Function(SendSessionState? old) state,
  }) {
    final newState = state(this[sessionId]);
    if (newState == null) {
      // no change
      return this;
    }
    return {
      ...this,
      sessionId: newState,
    };
  }

  Map<String, SendSessionState> removeSession(Ref ref, String sessionId) {
    ref.read(progressProvider.notifier).removeSession(sessionId);
    return {...this}..remove(sessionId);
  }
}

extension on SendSessionState {
  SendSessionState withFileStatus(String fileId, FileStatus status, String? errorMessage) {
    return copyWith(
      files: {...files}..update(
          fileId,
          (file) => file.copyWith(
            status: status,
            errorMessage: errorMessage,
          ),
        ),
    );
  }
}

extension on Object {
  String get humanErrorMessage {
    final e = this;
    if (e is DioError && e.response != null) {
      final body = e.response!.data;
      String message;
      try {
        message = (body as Map)['message'];
      } catch (_) {
        message = body;
      }
      return '[${e.response!.statusCode}] $message';
    }

    return e.toString();
  }
}
