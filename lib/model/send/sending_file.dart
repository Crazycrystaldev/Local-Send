import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:localsend_app/model/dto/file_dto.dart';
import 'package:localsend_app/model/file_status.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

part 'sending_file.freezed.dart';

@freezed
class SendingFile with _$SendingFile {
  const factory SendingFile({
    required FileDto file,
    required FileStatus status,
    required String? token,
    required AssetEntity? asset, // for thumbnails
    required String? path, // android, iOS, desktop
    required List<int>? bytes, // web
    required String? errorMessage, // when status == failed
  }) = _SendingFile;
}
