import 'package:json_annotation/json_annotation.dart';

part 'file_info.g.dart';

@JsonSerializable()
class FileInfo {
  final String fileType;
  final String jsonVersion;

  const FileInfo({required this.fileType, required this.jsonVersion});

  factory FileInfo.fromJson(Map<String, dynamic> json) =>
      _$FileInfoFromJson(json);
  Map<String, dynamic> toJson() => _$FileInfoToJson(this);
}
