import 'package:aes_crypt_null_safe/aes_crypt_null_safe.dart';
import 'package:encryptF/model/helper.dart';
import 'package:encryptF/pages/landing_page.dart';
import 'package:encryptF/widgets/loading_widget.dart';
import 'package:file_icon/file_icon.dart';
import 'package:file_picker/file_picker.dart';
import 'package:filesize/filesize.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  bool _isPasswordHidden = false;
  String _currStatus = "...";
  final _goldColor = const Color.fromRGBO(255, 223, 54, 0.5);
  final _formKey = GlobalKey<FormState>();
  final passwordFieldController = TextEditingController();
  String? passwordToBeSet;
  final help = Helper();
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

  Widget inputPassword() {
    return Form(
      key: _formKey,
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

  Widget submitPasswordButton() => ElevatedButton(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            passwordToBeSet = passwordFieldController.text;
            encryptFile();
          }
        },
        child: widget.shouldEncrypt
            ? const Text(
                'Encrypt!',
                style: TextStyle(color: Colors.white, fontSize: 15),
              )
            : const Text(
                'Decrypt',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
      );
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

  Widget fileInfoBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          widget.pickedFile.files.first.name,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(
          height: 10,
          width: double.infinity,
        ),
        Text(filesize(widget.pickedFile.files.first.size),
            style: const TextStyle(fontSize: 15)),
      ],
    );
  }

  void encryptFile() async {
    setState(() {
      _isLoading = true;
      _currStatus = "Beginning Encryption";
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
    if (widget.shouldEncrypt) {
      try {
        setState(() {
          _currStatus = "Encrypting";
        });
        filePath = await compute(
            fileCrypt.encryptFile, widget.pickedFile.paths.first!);
        if (kDebugMode) {
          print('Encryption Completed');
          print('The file is at $filePath');
        }
        setState(() {
          _currStatus = "Encryption Completed";
          _isLoading = false;
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
      try {
        setState(() {
          _currStatus = "Decrypting";
        });
        filePath = await compute(
            fileCrypt.decryptFile, widget.pickedFile.paths.first!);
        if (kDebugMode) {
          print('Decryption Completed');
          print('The file is at $filePath');
        }
        setState(() {
          _currStatus = "Decryption Completed";
          _isLoading = false;
        });
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => LandingPage(
                  isEncryptedObject: true,
                  filePath: filePath,
                  wasSuccess: true,
                )));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error in Decryption!')));
        setState(() {
          _currStatus = "Error!";
          _isLoading = false;
        });

        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const LandingPage(
                  isEncryptedObject: false,
                  filePath: null,
                  wasSuccess: false,
                )));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    FilePicker.platform.clearTemporaryFiles();
  }
}
