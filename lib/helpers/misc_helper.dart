import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:encryptF/model/file_info.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

final log = Logger('MiscHelper');
const useColor = Color.fromRGBO(193, 193, 193, 1);
const buttonGrey = Color.fromRGBO(48, 48, 48, 1);
const buttonBlue = Color.fromRGBO(59, 90, 168, 1);

class MiscHelper {
  final String jsonVersion = "0.0.1";
  final String configFileName = ".devutNCrypt";
  final String assetFolderName = 'assets';
  final String fileFolderName = 'files';
  final String extensionName = 'ncrypt';
  final String encryptTempFolderName = 'EncryptTemp';
  final String encryptTempSubDirName = 'folders';
  final String newNoteName = 'New Note';
  final String fileTypeNote = 'note';
  final String fileTypeFile = 'file';
  Future<bool> requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      var status = await permission.request();
      if (status.isGranted) {
        return true;
      }
      return false;
    }
  }

  Future<File> saveFile(String src) async {
    Directory? appStorage = await getExternalStorageDirectory();
    var fileName = (src.split('/').last);
    final newFile = ('${appStorage!.path}/$fileName');

    return File(src).copySync(newFile);
  }

  Future<String> readJsonFile(String srcPath) async {
    return await File(srcPath).readAsString();
  }

  Future<FileInfo?> checkValidity(Directory src) async {
    String filePath = src.path + '/' + configFileName;
    if (!File(filePath).existsSync()) {
      return null;
    } else {
      final configContent = await compute(readJsonFile, filePath);
      return FileInfo.fromJson(json.decode(configContent));
    }
  }
}

Future<void> deleteDirectory(Directory toDel) async {
  if (toDel.existsSync()) {
    toDel.delete(recursive: true);
  }
}

Future<void> copyFiles(EncryptedDirObject dirObject) async {
  log.info('The Asset Folder is at ${dirObject.assetFolderPath}');
  log.info('The File Folder is at ${dirObject.fileFolderPath}');

  if (dirObject.pickedFiles.isNotEmpty) {
    for (var file in dirObject.pickedFiles) {
      String newPath = dirObject.isAsset
          ? dirObject.assetFolderPath + '/' + file.name
          : dirObject.fileFolderPath + '/' + file.name;
      File oldFile = File(file.path!);
      try {
        await oldFile.rename(newPath);
      } on FileSystemException catch (e) {
        log.warning(
            'File renaming failed trying copying now, error = ${e.toString()}');
        oldFile.copy(newPath);
        await oldFile.delete();
      }
      log.info('Copy Success');
    }
  } else {
    for (var file in dirObject.copyFiles) {
      if (file is File) {
        final filePath = file.path;
        final fileName = filePath.split('/').last;
        String newPath = dirObject.isAsset
            ? dirObject.assetFolderPath + '/' + fileName
            : dirObject.fileFolderPath + '/' + fileName;
        File oldFile = File(filePath);
        try {
          await oldFile.rename(newPath);
        } on FileSystemException catch (e) {
          log.warning(
              'File renaming failed trying copying now, error = ${e.toString()}');
          oldFile.copy(newPath);
          await oldFile.delete();
        }
        log.info('Copy Success');
      }
    }
  }
}

class EncryptedDirObject {
  final List<PlatformFile> pickedFiles;
  final List<FileSystemEntity> copyFiles;
  final String assetFolderPath;
  final String fileFolderPath;
  final bool isAsset;
  const EncryptedDirObject(
      {required this.pickedFiles,
      required this.copyFiles,
      required this.assetFolderPath,
      required this.fileFolderPath,
      required this.isAsset});
}
