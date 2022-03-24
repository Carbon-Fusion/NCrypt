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
  Future<File> saveFile(String src) async {
    Directory? appStorage = await getExternalStorageDirectory();
    var fileName = (src.split('/').last);
    final newFile = ('${appStorage!.path}/$fileName');

    return File(src).copySync(newFile);
  }

}