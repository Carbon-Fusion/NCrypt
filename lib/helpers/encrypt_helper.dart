import 'dart:convert';
import 'dart:io';

import 'package:encryptF/helpers/misc_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../model/file_info.dart';

class EncryptHelper {
  final FilePickerResult pickedFiles;
  final String resultName;
  final Directory tempDirectory;
  final _help = MiscHelper();
  final log = Logger('EncryptHelper');
  EncryptHelper(
      {required this.pickedFiles,
      required this.resultName,
      required this.tempDirectory});

  /// Cleans up any old data and creates a fresh Directory
  /// This directory resides at
  /// ~/cache/EnrcyptTemp/folders/[result_name]
  Future<Directory> setupEncryptedDirectory(
      bool isAsset, bool createConfigFile) async {
    String baseDirPath = getEncryptTempDir();
    Directory storageDirectory = Directory('$baseDirPath/$resultName');
    if (await storageDirectory.exists()) {
      storageDirectory.delete(recursive: true);
    }
    storageDirectory.createSync(recursive: true);

    Directory(storageDirectory.path + '/${_help.fileFolderName}')
        .createSync(recursive: true);
    Directory(storageDirectory.path + '/${_help.assetFolderName}')
        .createSync(recursive: true);
    log.info('Created Assets and files folder');
    await compute(_copyFiles,
        EncryptedDirObject(pickedFiles.files, storageDirectory, isAsset));
    log.info('Copied over Files');
    if (createConfigFile) {
      final configFileContent = json.encode(
          FileInfo(fileType: 'file', jsonVersion: _help.jsonVersion).toJson());
      File(storageDirectory.path + '/' + _help.configFileName)
          .writeAsString(configFileContent);
      log.info('Created config files');
    }
    return storageDirectory;
  }

  Future<void> _copyFiles(EncryptedDirObject dirObject) async {
    log.info('The Asset Folder is at ${getAssetFolderPath()}');
    log.info('The Asset Folder is at ${getFileFolderPath()}');

    for (var file in dirObject.files) {
      String newPath = dirObject.isAsset
          ? getAssetFolderPath() + '/' + file.name
          : getFileFolderPath() + '/' + file.name;
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
  }

  /// returns ~/cache/EncryptTemp/folders/[result_name]/files
  String getFileFolderPath() {
    return getEncryptTempDir() + '/$resultName/${_help.fileFolderName}';
  }

  /// returns ~/cache/EncryptTemp/folders/[result_name]/assets
  String getAssetFolderPath() {
    return getEncryptTempDir() + '/$resultName/${_help.assetFolderName}';
  }

  /// returns ~/cache/EncryptTemp/folders
  String getEncryptTempDir() {
    return '${tempDirectory.path}/${_help.encryptTempFolderName}/${_help.encryptTempSubDirName}';
  }
}

class EncryptedDirObject {
  final List<PlatformFile> files;
  final Directory storageDirectoryPath;
  final bool isAsset;
  const EncryptedDirObject(this.files, this.storageDirectoryPath, this.isAsset);
}
