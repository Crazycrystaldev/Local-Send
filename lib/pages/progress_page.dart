import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/dto/file_dto.dart';
import 'package:localsend_app/model/file_status.dart';
import 'package:localsend_app/model/session_status.dart';
import 'package:localsend_app/pages/home_page.dart';
import 'package:localsend_app/provider/network/send_provider.dart';
import 'package:localsend_app/provider/network/server_provider.dart';
import 'package:localsend_app/provider/progress_provider.dart';
import 'package:localsend_app/util/file_size_helper.dart';
import 'package:localsend_app/util/file_speed_helper.dart';
import 'package:localsend_app/util/platform_check.dart';
import 'package:localsend_app/widget/custom_progress_bar.dart';
import 'package:localsend_app/widget/dialogs/cancel_session_dialog.dart';
import 'package:open_filex/open_filex.dart';
import 'package:routerino/routerino.dart';
import 'package:wakelock/wakelock.dart';

class ProgressPage extends ConsumerStatefulWidget {
  const ProgressPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends ConsumerState<ProgressPage> {
  int _totalBytes = double.maxFinite.toInt();
  List<FileDto> _files = []; // also contains declined files (files without token)
  Set<String> _filesWithToken = {};

  bool _advanced = false;

  @override
  void initState() {
    super.initState();

    // init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        Wakelock.enable();
      } catch (_) {}

      final receiveState = ref.read(serverProvider.select((state) => state?.receiveState));
      if (receiveState != null) {
        _files = receiveState.files.values.map((f) => f.file).toList();
        _filesWithToken = receiveState.files.values.where((f) => f.token != null).map((f) => f.file.id).toSet();
      } else {
        final sendState = ref.read(sendProvider);
        if (sendState != null) {
          _files = sendState.files.values.map((f) => f.file).toList();
          _filesWithToken = sendState.files.values.where((f) => f.token != null).map((f) => f.file.id).toSet();
        }
      }

      _totalBytes = _files.where((f) => _filesWithToken.contains(f.id)).fold(0, (prev, curr) => prev + curr.size);
    });
  }

  @override
  void dispose() {
    super.dispose();
    try {
      Wakelock.disable();
    } catch (_) {}
  }

  Future<bool> _askCancelConfirmation(SessionStatus status) async {
    final bool result = status == SessionStatus.sending ? await context.pushBottomSheet(() => const CancelSessionDialog()) : true;
    if (result) {
      final receiveState = ref.read(serverProvider.select((s) => s?.receiveState));
      final sendState = ref.read(sendProvider);

      if (receiveState != null) {
        ref.read(serverProvider.notifier).cancelSession();
      } else if (sendState != null) {
        ref.read(sendProvider.notifier).cancelSession();
      }
      ref.read(progressProvider.notifier).reset();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final ProgressNotifier progressNotifier = ref.watch(progressProvider);
    final currBytes = _files.fold<int>(0, (prev, curr) => prev + ((progressNotifier.getProgress(curr.id) * curr.size).round()));

    final receiveState = ref.watch(serverProvider.select((s) => s?.receiveState));
    final sendState = ref.watch(sendProvider);

    final SessionStatus? status = receiveState?.status ?? sendState?.status;
    if (status == null) {
      return Scaffold(
        body: Container(),
      );
    }

    final startTime = receiveState?.startTime ?? sendState?.startTime;
    final endTime = receiveState?.endTime ?? sendState?.endTime;
    final int? speedInBytes;
    final String? remainingTime;
    if (startTime != null && currBytes >= 500 * 1024) {
      speedInBytes = getFileSpeed(start: startTime, end: endTime ?? DateTime.now().millisecondsSinceEpoch, bytes: currBytes);
      remainingTime = getRemainingTime(bytesPerSeconds: speedInBytes, remainingBytes: _totalBytes - currBytes);
    } else {
      speedInBytes = null;
      remainingTime = null;
    }

    return WillPopScope(
      onWillPop: () => _askCancelConfirmation(status),
      child: Scaffold(
        body: Stack(
          children: [
            ListView.builder(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                bottom: 150,
                left: 15,
                right: 30,
              ),
              itemCount: _files.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  // title
                  return Text(
                    receiveState != null ? t.progressPage.titleReceiving : t.progressPage.titleSending,
                    style: Theme.of(context).textTheme.headline6,
                  );
                }

                final file = _files[index - 1];
                final fileStatus = receiveState?.files[file.id]?.status ?? sendState!.files[file.id]!.status;
                final savedToGallery = receiveState?.files[file.id]?.savedToGallery ?? false;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: InkWell(
                    splashColor: Colors.transparent,
                    splashFactory: NoSplash.splashFactory,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    onTap: fileStatus == FileStatus.finished && receiveState != null && !savedToGallery
                        ? () => OpenFilex.open(receiveState.files[file.id]!.path)
                        : null,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(file.fileType.icon, size: 46),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      file.fileName,
                                      style: const TextStyle(fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(' (${file.size.asReadableFileSize})', style: const TextStyle(fontSize: 16)),
                                ],
                              ),
                              if (fileStatus == FileStatus.sending)
                                Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: CustomProgressBar(
                                    progress: progressNotifier.getProgress(file.id),
                                  ),
                                )
                              else
                                Text(
                                  savedToGallery ? t.progressPage.savedToGallery : fileStatus.label,
                                  style: TextStyle(color: fileStatus.getColor(context)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 5, top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            status.getLabel(
                              remainingTime: remainingTime ?? '-',
                            ),
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 5),
                          CustomProgressBar(
                            progress: _totalBytes == 0 ? 0 : currBytes / _totalBytes,
                            borderRadius: 5,
                            color: Theme.of(context).colorScheme.tertiaryContainer,
                          ),
                          AnimatedCrossFade(
                            crossFadeState: _advanced ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 200),
                            alignment: Alignment.topLeft,
                            firstChild: Container(),
                            secondChild: Padding(
                              padding: const EdgeInsets.only(top: 10, bottom: 5),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.progressPage.total.count(
                                    curr: progressNotifier.getFinishedCount(),
                                    n: _filesWithToken.length,
                                  )),
                                  Text(t.progressPage.total.size(
                                    curr: currBytes.asReadableFileSize,
                                    n: _totalBytes == double.maxFinite.toInt() ? '-' : _totalBytes.asReadableFileSize,
                                  )),
                                  if (speedInBytes != null)
                                    Text(t.progressPage.total.speed(
                                      speed: speedInBytes.asReadableFileSize,
                                    )),
                                  if (checkPlatformWithFileSystem() && receiveState != null)
                                    Text('${t.settingsTab.receive.destination}: ${receiveState.destinationDirectory}'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onSurface),
                                onPressed: () {
                                  setState(() => _advanced = !_advanced);
                                },
                                icon: const Icon(Icons.info),
                                label: Text(_advanced ? t.general.hide : t.general.advanced),
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onSurface),
                                onPressed: () async {
                                  final result = await _askCancelConfirmation(status);
                                  if (result && mounted) {
                                    context.pushRootImmediately(() => const HomePage());
                                  }
                                },
                                icon: Icon(status == SessionStatus.sending ? Icons.close : Icons.check_circle),
                                label: Text(status == SessionStatus.sending ? t.general.cancel : t.general.done),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on FileStatus {
  String get label {
    switch (this) {
      case FileStatus.queue:
        return t.general.queue;
      case FileStatus.skipped:
        return t.general.skipped;
      case FileStatus.sending:
        return ''; // progress bar will be showed here
      case FileStatus.failed:
        return t.general.error;
      case FileStatus.finished:
        return t.general.done;
    }
  }

  Color getColor(BuildContext context) {
    switch (this) {
      case FileStatus.queue:
        return Theme.of(context).colorScheme.tertiaryContainer;
      case FileStatus.skipped:
        return Colors.grey;
      case FileStatus.sending:
        return Theme.of(context).colorScheme.tertiaryContainer;
      case FileStatus.failed:
        return Colors.orange;
      case FileStatus.finished:
        return Theme.of(context).colorScheme.tertiaryContainer;
    }
  }
}

extension on SessionStatus {
  String getLabel({required String remainingTime}) {
    switch (this) {
      case SessionStatus.sending:
        return t.progressPage.total.title.sending(
          time: remainingTime,
        );
      case SessionStatus.finished:
        return t.general.finished;
      case SessionStatus.finishedWithErrors:
        return t.progressPage.total.title.finishedError;
      case SessionStatus.canceledBySender:
        return t.progressPage.total.title.canceledSender;
      case SessionStatus.canceledByReceiver:
        return t.progressPage.total.title.canceledReceiver;
      default:
        print(this);
        return '';
    }
  }
}
