import 'dart:convert';
import 'dart:io';

import 'package:encryptF/model/file_info.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class MiscHelper {
  final String jsonVersion = "0.0.1";
  final String configFileName = ".devutNCrypt";
  final String assetFolderName = 'assets';
  final String fileFolderName = 'files';
  final String extensionName = 'ncrypt';
  final String encryptTempFolderName = 'EncryptTemp';
  final String encryptTempSubDirName = 'folders';
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
