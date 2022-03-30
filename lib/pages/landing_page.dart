import 'package:file_icon/file_icon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class LandingPage extends StatefulWidget {
  final bool isEncryptedObject;
  final bool wasSuccess;
  final String? filePath;
  final bool? isFile;
  const LandingPage(
      {Key? key,
      required this.isEncryptedObject,
      required this.filePath,
      required this.wasSuccess,
      this.isFile})
      : super(key: key);

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _hideResultMessage = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _hideResultMessage ? finalLanding() : resultMessageContainer(),
    );
  }

  Widget finalLanding() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        centerIcon(),
        const SizedBox(
          height: 20,
          width: double.infinity,
        ),
        shareButton(),
      ],
    );
  }

  Widget resultMessageContainer() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        centerResultIcon(),
        const SizedBox(
          height: 20,
          width: double.infinity,
        ),
        resultText(),
      ],
    );
  }

  Widget shareButton() {
    return IconButton(
        onPressed: () {
          Share.shareFiles([widget.filePath!]);
        },
        icon: const Icon(Icons.share_rounded));
  }

  Widget centerIcon() {
    return widget.isEncryptedObject
        ? const Icon(
            Icons.enhanced_encryption_rounded,
            size: 200,
            color: Colors.green,
          )
        : Center(
            child: FileIcon(
            getFileName(),
            size: 250,
          ));
  }

  Widget resultText() => Text(
        widget.wasSuccess ? "Success" : "Failure",
        style: const TextStyle(fontSize: 30),
      );

  Widget centerResultIcon() {
    return Center(
      child: widget.wasSuccess
          ? const Icon(
              Icons.check_circle_outline_rounded,
              size: 100,
              color: Colors.green,
            )
          : const Icon(
              Icons.cancel_outlined,
              size: 100,
              color: Colors.red,
            ),
    );
  }

  String getFileName() {
    return widget.filePath!.split('/').last;
  }

  void resultDuration() {
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        if (kDebugMode) {
          print("HiddenOver");
        }
        _hideResultMessage = true;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    resultDuration();
  }
}
