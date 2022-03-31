import 'dart:convert';
import 'dart:io';

import 'package:encryptF/helpers/misc_helper.dart';
import 'package:flutter/foundation.dart';

import '../model/file_info.dart';

class NotesHelper {
  final _help = MiscHelper();

  final Directory tempDirectory;
  final String resultName;
  NotesHelper({required this.tempDirectory, required this.resultName});

  /// Cleans up any old data and creates a fresh Directory
  /// This directory resides at
  /// ~/cache/EnrcyptTemp/folders/[result_name]
  Future<Directory> setupNoteEncryptDir(
      {bool? isNew, String? inputDirPath}) async {
    String baseDir = getEncryptTempDir();
    Directory storageDirectory = Directory(baseDir + '/$resultName');
    if (storageDirectory.existsSync()) {
      storageDirectory.deleteSync(recursive: true);
    }
    Directory(storageDirectory.path + '/${_help.fileFolderName}')
        .createSync(recursive: true);
    Directory(storageDirectory.path + '/${_help.assetFolderName}')
        .createSync(recursive: true);
    final oldConfigFilePath = inputDirPath! + '/' + _help.configFileName;
    final oldConfigFile = File(oldConfigFilePath);
    if (isNew != null) {
      final newConfigFilePath =
          storageDirectory.path + '/${_help.configFileName}';
      // copy fileFolder
      compute(
          copyFiles,
          EncryptedDirObject(
              pickedFiles: [],
              copyFiles: Directory(inputDirPath + '/${_help.fileFolderName}')
                  .listSync(),
              assetFolderPath: getAssetFolderPath(),
              fileFolderPath: getFileFolderPath(),
              isAsset: false));
      // copy assets
      await compute(
          copyFiles,
          EncryptedDirObject(
              pickedFiles: [],
              copyFiles: Directory(inputDirPath + '/${_help.assetFolderName}')
                  .listSync(),
              assetFolderPath: getAssetFolderPath(),
              fileFolderPath: getFileFolderPath(),
              isAsset: true));
      // copy configFile
      oldConfigFile.copySync(newConfigFilePath);
    } else {
      final configFileContent = json.encode(FileInfo(
              fileType: _help.fileTypeFile,
              jsonVersion: _help.jsonVersion,
              fileName: resultName)
          .toJson());
      oldConfigFile.writeAsString(configFileContent);
    }
    return storageDirectory;
  }

  /// returns ~/cache/EncryptTemp/folders
  String getEncryptTempDir() {
    return '${tempDirectory.path}/${_help.encryptTempFolderName}/${_help.encryptTempSubDirName}';
  }

  /// returns ~/cache/EncryptTemp/folders/[result_name]/files
  String getFileFolderPath() {
    return getEncryptTempDir() + '/$resultName/${_help.fileFolderName}';
  }

  /// returns ~/cache/EncryptTemp/folders/[result_name]/assets
  String getAssetFolderPath() {
    return getEncryptTempDir() + '/$resultName/${_help.assetFolderName}';
  }

  Future<void> addFile(List<File> fileToAdd) async {
    for (var file in fileToAdd) {
      final fileName = file.path.split('/').last;
      final fileToBePath = getEncryptTempDir() +
          '/$resultName/' +
          '${_help.fileFolderName}/$fileName';
      final oldFile = File(fileToBePath);
      if (oldFile.existsSync()) {
        oldFile.deleteSync(recursive: true);
      }
      file.copy(fileToBePath);
    }
  }

  Future<void> removeFile(List<File> fileToRemove) async {
    for (var file in fileToRemove) {
      if (file.existsSync()) {
        file.delete(recursive: true);
      }
    }
  }

  Future<void> addAsset(List<File> assetToAdd) async {
    for (var asset in assetToAdd) {
      final assetName = asset.path.split('/').last;
      final assetToBePath = getEncryptTempDir() +
          '/$resultName/' +
          '${_help.assetFolderName}/$assetName';
      final oldFile = File(assetToBePath);
      if (oldFile.existsSync()) {
        oldFile.deleteSync(recursive: true);
      }
      asset.copy(assetToBePath);
    }
  }

  Future<void> removeAsset(List<File> assetToRemove) async {
    for (var asset in assetToRemove) {
      if (asset.existsSync()) {
        asset.delete(recursive: true);
      }
    }
  }

  Future<void> renameNote(RenameObject renameObject) async {
    final String currPath = '${getEncryptTempDir()}/${renameObject.oldName}';
    final String newPath = '${getEncryptTempDir()}/${renameObject.newName}';
    final Directory currDir = Directory(currPath);
    if (Directory(newPath).existsSync()) {
      Directory(newPath).deleteSync(recursive: true);
    }
    String newConfigFilePath =
        '${getEncryptTempDir()}/${renameObject.newName}/${_help.configFileName}';
    String oldConfigFilePath =
        '${getEncryptTempDir()}/${renameObject.oldName}/${_help.configFileName}';
    final newConfigFile = File(newConfigFilePath);
    final oldConfigFile = File(oldConfigFilePath);
    await currDir.rename(newPath);
    if (oldConfigFile.existsSync()) {
      final oldConfig =
          FileInfo.fromJson(jsonDecode(oldConfigFile.readAsStringSync()));
      final newConfig = FileInfo(
          fileType: oldConfig.fileType,
          jsonVersion: oldConfig.jsonVersion,
          fileName: renameObject.newName);
      if (newConfigFile.existsSync()) {
        newConfigFile.deleteSync();
      }
      newConfigFile.createSync(recursive: true);
      newConfigFile.writeAsStringSync(jsonEncode(newConfig.toJson()));
    }
  }

  String getConfigFilePath() {
    return '${getEncryptTempDir()}/$resultName/${_help.configFileName}';
  }

  Future<String> prepareToSaveNote(String jsonToSave) async {
    final configFilePath = getConfigFilePath();
    final configFile = File(configFilePath);
    if (configFile.existsSync()) {
      configFile.deleteSync();
    } else {
      final File resultFile =
          File('${getEncryptTempDir()}/$resultName.${_help.extensionName}');
      if (resultFile.existsSync()) {
        resultFile.deleteSync();
      }
    }
    configFile.writeAsString(jsonEncode(FileInfo(
            fileName: resultName,
            fileType: _help.fileTypeNote,
            jsonVersion: _help.jsonVersion)
        .toJson()));
    String documentPath = getEncryptTempDir() +
        '/$resultName/' +
        _help.fileFolderName +
        '/document';
    final oldDocument = File(getEncryptTempDir() +
        '/$resultName/' +
        _help.fileFolderName +
        '/document');
    if (oldDocument.existsSync()) {
      oldDocument.deleteSync();
    }
    File(documentPath).writeAsString(jsonToSave);
    return '$tempDirectory/${_help.encryptTempFolderName}/$resultName';
  }
}

class RenameObject {
  final String oldName;
  final String newName;
  RenameObject({required this.oldName, required this.newName});
}
