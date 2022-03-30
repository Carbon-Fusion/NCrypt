// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FileInfo _$FileInfoFromJson(Map<String, dynamic> json) => FileInfo(
      fileType: json['fileType'] as String,
      jsonVersion: json['jsonVersion'] as String,
      fileName: json['fileName'] as String,
    );

Map<String, dynamic> _$FileInfoToJson(FileInfo instance) => <String, dynamic>{
      'fileType': instance.fileType,
      'jsonVersion': instance.jsonVersion,
      'fileName': instance.fileName,
    };
