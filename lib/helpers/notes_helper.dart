import 'dart:convert';
import 'dart:io';

import 'package:encryptF/helpers/misc_helper.dart';

import '../model/file_info.dart';

class NotesHelper {
  final _help = MiscHelper();

  final Directory tempDirectory;
  final String resultName;
  NotesHelper({required this.tempDirectory, required this.resultName});

  /// Cleans up any old data and creates a fresh Directory
  /// This directory resides at
  /// ~/cache/EnrcyptTemp/folders/[result_name]
  Future<Directory> setupNoteEncryptDir() async {
    String baseDir = getEncryptTempDir();
    Directory storageDirectory = Directory(baseDir + '/$resultName');

    if (storageDirectory.existsSync()) {
      storageDirectory.deleteSync(recursive: true);
    }
    Directory(storageDirectory.path + '/${_help.fileFolderName}')
        .createSync(recursive: true);
    Directory(storageDirectory.path + '/${_help.assetFolderName}')
        .createSync(recursive: true);
    final configFileContent = json.encode(
        FileInfo(fileType: 'note', jsonVersion: _help.jsonVersion).toJson());
    File(storageDirectory.path + '/' + _help.configFileName)
        .writeAsString(configFileContent);
    return storageDirectory;
  }

  /// returns ~/cache/EncryptTemp/folders
  String getEncryptTempDir() {
    return '${tempDirectory.path}/${_help.encryptTempFolderName}/${_help.encryptTempSubDirName}';
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
      Directory(newPath).deleteSync();
    }
    currDir.rename(newPath);
  }

  Future<String> prepareToSaveNote() async {
    String currPath = '${getEncryptTempDir()}/$resultName';
    final configFilePath = '$currPath/${_help.configFileName}';
    if (!File(configFilePath).existsSync()) {
      throw Exception('Config file! does not exist!');
    } else {
      final File resultFile =
          File('${getEncryptTempDir()}/$resultName.${_help.extensionName}');
      if (resultFile.existsSync()) {
        resultFile.deleteSync();
      }
    }
    return '$tempDirectory/${_help.encryptTempFolderName}/$resultName';
  }
}

class RenameObject {
  final String oldName;
  final String newName;
  RenameObject({required this.oldName, required this.newName});
}
