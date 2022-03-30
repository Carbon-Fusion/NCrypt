import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:encryptF/helpers/misc_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../model/file_info.dart';
import 'compression_helper.dart';

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
      {required bool isAsset, required bool createConfigFile}) async {
    Directory storageDirectory = _setUpDirs(getEncryptTempDir);
    await compute(_copyFiles,
        EncryptedDirObject(pickedFiles.files, storageDirectory, isAsset));
    log.info('Copied over Files');
    if (createConfigFile) {
      final configFileContent = json.encode(FileInfo(
              fileType: _help.fileTypeFile,
              jsonVersion: _help.jsonVersion,
              fileName: resultName)
          .toJson());
      File(storageDirectory.path + '/' + _help.configFileName)
          .writeAsString(configFileContent);
      log.info('Created config files');
    }
    return storageDirectory;
  }

  Future<void> setupDecryptedDirectory() async {
    _delOldDir(getDecryptTempDir());
  }

  Directory _delOldDir(String baseDirPath) {
    Directory storageDirectory = Directory('$baseDirPath/$resultName');
    if (storageDirectory.existsSync()) {
      storageDirectory.deleteSync(recursive: true);
    }
    return storageDirectory;
  }

  Directory _setUpDirs(String Function() getRespectiveTempDir) {
    String baseDirPath = getRespectiveTempDir();
    Directory storageDirectory = _delOldDir(baseDirPath);
    storageDirectory.createSync(recursive: true);

    final fileDir =
        Directory(storageDirectory.path + '/${_help.fileFolderName}');
    final assetDir =
        Directory(storageDirectory.path + '/${_help.assetFolderName}');
    if (!fileDir.existsSync()) {
      fileDir.createSync(recursive: true);
    }
    if (!assetDir.existsSync()) {
      assetDir.createSync(recursive: true);
    }
    log.info('Created Assets and files folder');
    return storageDirectory;
  }

  Future<void> _copyFiles(EncryptedDirObject dirObject) async {
    log.info('The Asset Folder is at ${getAssetFolderPath()}');
    log.info('The File Folder is at ${getFileFolderPath()}');

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

  Future<Archive?> checkDecryptionFile(String pathToCheck) async {
    final ncryptFile = await CompressionHelper().zipView(pathToCheck);
    bool found = false;
    for (var files in ncryptFile) {
      if (files.name == _help.configFileName) {
        found = true;
        break;
      }
    }
    if (!found) {
      return null;
    }
    return ncryptFile;
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

  /// returns ~/cache/EncryptTemp/folders
  String getDecryptTempDir() {
    return getEncryptTempDir();
  }
}

class EncryptedDirObject {
  final List<PlatformFile> files;
  final Directory storageDirectoryPath;
  final bool isAsset;
  const EncryptedDirObject(this.files, this.storageDirectoryPath, this.isAsset);
}
