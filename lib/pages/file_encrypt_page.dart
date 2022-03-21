import 'dart:io';

import 'package:aes_crypt_null_safe/aes_crypt_null_safe.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FileEncryptPage extends StatefulWidget {
  final FilePickerResult pickedFile;
  const FileEncryptPage({
    Key? key,
    required this.pickedFile,
  }) : super(key: key);
  @override
  State<FileEncryptPage> createState() => _FileEncryptPageState();
}

class _FileEncryptPageState extends State<FileEncryptPage> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final passwordFieldController = TextEditingController();
  String? passwordToBeSet;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        child: Scaffold(
      appBar: AppBar(
        title: Text(widget.pickedFile.files.first.name),
      ),
      body: inputPassword(),
    ));
  }

  Widget inputPassword() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: passwordFieldController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the password';
              }
              return null;
            },
          ),
          submitPasswordButton(),
        ],
      ),
    );
  }

  Widget submitPasswordButton() => ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            passwordToBeSet = passwordFieldController.text;
            encryptFile();
          }
        },
        child: const Text('Encrypt!'),
      );
  Future<bool> _requestPermission(Permission permission) async {
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

  void encryptFile() async {
    setState(() {
      _isLoading = true;
    });
    if (!await _requestPermission(Permission.storage)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Denied Permission")));
      setState(() {
        _isLoading = false;
      });
      return;
    }
    var fileCrypt = AesCrypt(passwordFieldController.text);
    fileCrypt.setOverwriteMode(AesCryptOwMode.rename);
    String filePath;
    try {
      filePath = fileCrypt.encryptFileSync(widget.pickedFile.paths.first!);
      if (kDebugMode) {
        print("The Encryption completed");
        print("Encrypted file : $filePath");
        print(await saveFile(filePath));
      }
    } on AesCryptException {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error in Encryption!')));
    }
  }
}
