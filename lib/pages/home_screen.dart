import 'package:encryptF/pages/file_encrypt_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Encrypt!"),
        ),
        body: _isLoading
            ? const Text("Loading..")
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [encryptFile(), decryptFile()],
              ),
      ),
    );
  }

  Widget encryptFile() => IconButton(
      onPressed: () {
        setState(() {
          _isLoading = true;
        });
        FilePicker.platform
            .pickFiles(allowMultiple: false)
            .then((FilePickerResult? value) async {
          if (value != null) {
            await Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => FileEncryptPage(
                      pickedFile: value,
                    )));
          }
        }).whenComplete(() => {
                  setState(() {
                    _isLoading = false;
                  })
                });
      },
      icon: const Icon(Icons.enhanced_encryption_rounded));

  Widget decryptFile() => IconButton(
      onPressed: () => {}, icon: const Icon(Icons.clear_all_rounded));
}
