import 'package:encryptF/pages/file_encrypt_page.dart';
import 'package:encryptF/widgets/loading_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  bool _shouldEncrypt = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Encrypt!"),
        ),
        body: _isLoading
            ? const Center(
                child: LoadingWidget(),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  logo(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [encryptFileButton(), decryptFileButton()],
                  )
                ],
              ),
      ),
    );
  }

  Widget logo() => Image.asset('assets/logo.webp');
  Widget encryptFileButton() => ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _isLoading = true;
            _shouldEncrypt = true;
          });
          encryptDecryptFile();
        },
        icon: const Icon(Icons.enhanced_encryption_rounded),
        label: const Text(
          'Encrypt',
          style: TextStyle(fontSize: 25),
        ),
      );

  Widget decryptFileButton() => ElevatedButton.icon(
      onPressed: () {
        setState(() {
          _isLoading = true;
          _shouldEncrypt = false;
        });
        encryptDecryptFile();
      },
      icon: const Icon(Icons.lock_open_rounded),
      label: const Text('Decrypt', style: TextStyle(fontSize: 25)));
  void encryptDecryptFile() async {
    FilePicker.platform
        .pickFiles(allowMultiple: false)
        .then((FilePickerResult? value) async {
      if (value != null) {
        await Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => FileEncryptPage(
                  pickedFile: value,
                  shouldEncrypt: _shouldEncrypt,
                )));
      }
    }).whenComplete(() => {
              setState(() {
                _isLoading = false;
              })
            });
  }
}
