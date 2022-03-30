import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:aes_crypt_null_safe/aes_crypt_null_safe.dart';
import 'package:encryptF/helpers/compression_helper.dart';
import 'package:encryptF/helpers/encrypt_helper.dart';
import 'package:encryptF/pages/landing_page.dart';
import 'package:encryptF/pages/new_notes.dart';
import 'package:encryptF/widgets/loading_widget.dart';
import 'package:file_icon/file_icon.dart';
import 'package:file_picker/file_picker.dart';
import 'package:filesize/filesize.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../helpers/misc_helper.dart';
import '../model/file_info.dart';

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
  bool _isPasswordHidden = false;
  String _currStatus = "...";
  String _resultName = "NCrypt";
  late AesCrypt fileCrypt;

  // final _goldColor = const Color.fromRGBO(255, 223, 54, 0.5);
  final _passwordFormKey = GlobalKey<FormState>();
  final _resultNameFormKey = GlobalKey<FormState>();
  final passwordFieldController = TextEditingController();
  final resultNameFieldController = TextEditingController();
  final log = Logger("FileEncryptPage");
  late EncryptHelper encryptHelper;
  String? passwordToBeSet;
  final _help = MiscHelper();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        child: Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.pickedFile.files.first.name),
      ),
      body: _isLoading
          ? loadingScreen()
          : SingleChildScrollView(
              child: Column(
                children: [
                  centerIcon(),
                  const SizedBox(
                    height: 20,
                    width: double.infinity,
                  ),
                  fileInfoBox(),
                  const SizedBox(
                    height: 20,
                    width: double.infinity,
                  ),
                  inputPassword(),
                ],
              ),
            ),
    ));
  }

  Widget centerIcon() {
    return Center(
        child: FileIcon(
      widget.pickedFile.files.first.name,
      size: 250,
    ));
  }

  Widget changeNameField() {
    return Form(
      key: _resultNameFormKey,
      child: Column(
        children: [
          TextFormField(
            maxLength: 20,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Colors.amberAccent)),
            ),
            controller: resultNameFieldController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the name';
              }
              return null;
            },
          ),
          ElevatedButton(
              onPressed: () {
                setState(() {
                  if (_resultNameFormKey.currentState!.validate()) {
                    _resultName = resultNameFieldController.text;
                  }
                  Navigator.of(context).pop();
                });
              },
              child: const Text('Change Name'))
        ],
      ),
    );
  }

  Widget changeResultNameDialog() {
    return BackdropFilter(
      filter: ImageFilter.blur(),
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 10,
                width: double.infinity,
              ),
              const Text(
                'Change Result File Name',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(
                height: 15,
              ),
              changeNameField(),
            ],
          ),
        ),
      ),
    );
  }

  void cleanOldEncryptFiles() async {
    Directory tempDir = Directory(((await getTemporaryDirectory()).path +
        '/${_help.encryptTempFolderName}/' +
        _help.encryptTempSubDirName));
    tempDir.createSync(recursive: true);
    var oldFile = File(tempDir.path + '/' + _resultName);
    if (oldFile.existsSync()) {
      oldFile.deleteSync(recursive: true);
    }
    oldFile =
        File(tempDir.path + '/' + _resultName + '.' + _help.extensionName);
    if (oldFile.existsSync()) {
      oldFile.delete(recursive: true);
    }
  }

  @override
  void dispose() {
    setState(() {
      _isLoading = false;
    });
    super.dispose();
  }

  void encryptionDecryptionHandler() async {
    setState(() {
      _isLoading = true;
      _currStatus = "Beginning Encryption";
    });
    if (!await _help.requestPermission(Permission.storage)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Denied Permission")));
      setState(() {
        _isLoading = false;
      });
      return;
    }
    fileCrypt = AesCrypt(passwordFieldController.text);
    fileCrypt.setOverwriteMode(AesCryptOwMode.rename);
    String filePath;
    if (widget.shouldEncrypt) {
      encryptHelper = EncryptHelper(
          pickedFiles: widget.pickedFile,
          resultName: _resultName,
          tempDirectory: (await getTemporaryDirectory()));
      try {
        setState(() {
          _currStatus = "Cleaning up old Files";
        });
        cleanOldEncryptFiles();
        setState(() {
          _currStatus = "Setting up new Files";
        });
        String tempDir = (await getTemporaryDirectory()).path;
        final encryptedFilePath =
            tempDir + '/' + _help.encryptTempFolderName + '/' + _resultName;
        Directory encryptedTempDir = await encryptHelper
            .setupEncryptedDirectory(isAsset: false, createConfigFile: true);
        log.info('Encrypted file path $encryptedFilePath');
        log.info('encryptedTempDir $encryptedTempDir');

        /// get Zip from ~/cache/EnrcyptTemp/folders/[result_name] and save it ~/cache/EncryptTemp/[result_name]
        await compute(CompressionHelper().dirToZip, <String, dynamic>{
          'encryptionTempDirectory': encryptedTempDir,
          'encryptedFilePath': encryptedFilePath,
        });
        setState(() {
          _currStatus = "Encrypting";
          log.info('Starting Encryption');
        });
        filePath = await compute(fileCrypt.encryptFile, encryptedFilePath);
        File resultFile = File(filePath);
        try {
          await resultFile.rename(
              filePath.substring(0, filePath.length - 3) + _help.extensionName);
        } on FileSystemException catch (e) {
          log.warning(
              'File renaming failed trying copying now, error = ${e.toString()}');
          final newFile = resultFile.copy(
              filePath.substring(0, filePath.length - 3) + _help.extensionName);
          resultFile.deleteSync();
          resultFile = (await newFile);
        }
        log.info('ResultFile Copy success');

        {
          log.info('Encryption Completed');
          log.info('The encryptedArchive is at ${resultFile.path}');
          log.info('The file is at ${resultFile.path}');
        }
        setState(() {
          _currStatus = "Finished!";
        });

        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => LandingPage(
                  isEncryptedObject: true,
                  filePath: filePath,
                  wasSuccess: true,
                )));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error in Encryption!')));
        setState(() {
          _currStatus = "Error!";
          _isLoading = false;
        });
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const LandingPage(
                  isEncryptedObject: true,
                  filePath: null,
                  wasSuccess: false,
                )));
      }
    } else {
      setState(() {
        _isLoading = true;
        _currStatus = 'Decrypting';
      });
      final fileName = widget.pickedFile.files.first.name;
      final decryptHelper = EncryptHelper(
          pickedFiles: widget.pickedFile,
          resultName: fileName,
          tempDirectory: (await getTemporaryDirectory()));
      fileCrypt.setPassword(passwordFieldController.text);
      fileCrypt.setOverwriteMode(AesCryptOwMode.rename);
      String resultFilePath;
      try {
        resultFilePath = await compute(
            fileCrypt.decryptFile, widget.pickedFile.files.first.path!);
      } catch (e) {
        showDialog(
            context: context, builder: (_) => decryptionError(e.toString()));
        return;
      }
      setState(() {
        _currStatus = 'Checking Files';
      });
      final archive = await decryptHelper.checkDecryptionFile(resultFilePath);
      if (archive == null) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('INVALID FILE')));
        return;
      }

      setState(() {
        _currStatus = 'Setting Files';
      });
      String filePath = decryptHelper.getDecryptTempDir() + '/$fileName';
      await CompressionHelper().archiveToDir(<String, dynamic>{
        'archive': archive,
        'outputPath': decryptHelper.getDecryptTempDir() + '/$fileName',
      });
      pageHandler(filePath);
      setState(() {
        _isLoading = false;
      });
    }
  }

  void pageHandler(String dirPath) {
    final configFilePath = dirPath + '/${_help.configFileName}';
    final configFile = File(configFilePath);
    if (configFile.existsSync()) {
      final fileInfo =
          FileInfo.fromJson(jsonDecode(configFile.readAsStringSync()));
      if (fileInfo.fileType == _help.fileTypeNote) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => NewNotes(note: Directory(dirPath))));
      } else if (fileInfo.fileType == _help.fileTypeFile) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => LandingPage(
                isEncryptedObject: false,
                filePath: dirPath,
                wasSuccess: true)));
      }
    }
  }

  Widget decryptionError(String error) {
    return AlertDialog(
      title: const Text("Error in decryption!"),
      content: Text(error),
      actions: [
        ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Ok')),
      ],
    );
  }

  Widget fileInfoBox() {
    return GestureDetector(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _resultName,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(
            height: 10,
            width: double.infinity,
          ),
          Text(filesize(widget.pickedFile.files.first.size),
              style: const TextStyle(fontSize: 15)),
        ],
      ),
      onTap: () {
        showDialog(context: context, builder: (_) => changeResultNameDialog());
      },
    );
  }

  @override
  void initState() {
    if (widget.pickedFile.files.length == 1) {
      setState(() {
        _resultName = widget.pickedFile.files.first.name;
      });
    }
    super.initState();
  }

  Widget inputPassword() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
            child: TextFormField(
              obscureText: _isPasswordHidden,
              maxLength: 20,
              decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.password_rounded),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(color: Colors.amberAccent)),
                  suffixIcon: IconButton(
                    icon: _isPasswordHidden
                        ? const Icon(Icons.visibility_off_rounded)
                        : const Icon(Icons.visibility_rounded),
                    onPressed: () {
                      setState(() {
                        _isPasswordHidden = !_isPasswordHidden;
                      });
                    },
                  )),
              controller: passwordFieldController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the password';
                }
                return null;
              },
            ),
          ),
          const SizedBox(
            height: 10,
            width: double.infinity,
          ),
          submitPasswordButton(),
        ],
      ),
    );
  }

  Widget loadingScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        const LoadingWidget(),
        Text(
          _currStatus,
          style: const TextStyle(fontSize: 30),
        ),
      ],
    );
  }

  Widget submitPasswordButton() {
    return ElevatedButton(
      onPressed: () async {
        if (_passwordFormKey.currentState!.validate()) {
          passwordToBeSet = passwordFieldController.text;
          WidgetsFlutterBinding.ensureInitialized();
          encryptionDecryptionHandler();
        }
      },
      child: widget.shouldEncrypt
          ? const Text(
              'Encrypt!',
              style: TextStyle(fontSize: 15),
            )
          : const Text(
              'Decrypt',
              style: TextStyle(fontSize: 15),
            ),
    );
  }
}
