import 'dart:io';

import 'package:aes_crypt_null_safe/aes_crypt_null_safe.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:encryptF/helper.dart';
import 'package:permission_handler/permission_handler.dart';

class FileEncryptPage extends StatefulWidget {
  final FilePickerResult pickedFile;
  final bool shouldEncrypt;
  const FileEncryptPage({
    Key? key,
    required this.pickedFile,
    required this.shouldEncrypt,
  }) : super(key: key);
  @override
  State<FileEncryptPage> createState() => _FileEncryptPageState();
}

class _FileEncryptPageState extends State<FileEncryptPage> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final passwordFieldController = TextEditingController();
  String? passwordToBeSet;
  final help = Helper();
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
        child: widget.shouldEncrypt ? const Text('Encrypt!') : const Text('Decrypt'),
      );

  void encryptFile() async {
    setState(() {
      _isLoading = true;
    });
    if (!await help.requestPermission(Permission.storage)) {
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
    if(widget.shouldEncrypt) {
      try {
        filePath = fileCrypt.encryptFileSync(widget.pickedFile.paths.first!);
        if (kDebugMode) {
          print("The Encryption completed");
          print("Encrypted file : $filePath");
          print(await help.saveFile(filePath));
        }
      } on AesCryptException {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error in Encryption!')));
      }
    }else{
      try {
        filePath = fileCrypt.decryptFileSync(widget.pickedFile.paths.first!);
        if (kDebugMode) {
          print("The Decryption completed");
          print("Decrypted file : $filePath");
          print(await help.saveFile(filePath));
        }
      } on AesCryptException {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error in Decryption!')));
      }
    }
  }
}
