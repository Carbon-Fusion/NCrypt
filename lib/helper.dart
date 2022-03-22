import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class Helper {
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
  Future<File> saveFile(String file) async {
    Directory? appStorage = await getExternalStorageDirectory();
    var fileName = (file.split('/').last);
    final newFile = ('${appStorage!.path}/$fileName');

    return File(file).copy(newFile);
  }

}