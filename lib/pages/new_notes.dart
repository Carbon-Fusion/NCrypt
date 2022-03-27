import 'dart:io';
import 'dart:ui';

import 'package:aes_crypt_null_safe/aes_crypt_null_safe.dart';
import 'package:encryptF/helpers/compression_helper.dart';
import 'package:encryptF/helpers/misc_helper.dart';
import 'package:encryptF/helpers/notes_helper.dart';
import 'package:encryptF/widgets/loading_widget.dart';
import 'package:file_icon/file_icon.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/text.dart' as FlutterText;
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class NewNotes extends StatefulWidget {
  const NewNotes({Key? key}) : super(key: key);

  @override
  State<NewNotes> createState() => _NewNotesState();
}

class _NewNotesState extends State<NewNotes> {
  bool _isLoading = false;
  String _currStatus = '...';
  String _newTitle = '...';
  String? password;
  late NotesHelper _notesHelper;
  final _help = MiscHelper();
  final resultNameFieldController = TextEditingController();
  final _resultNameFormKey = GlobalKey<FormState>();
  final passwordFieldController = TextEditingController();
  final _passwordFormKey = GlobalKey<FormState>();
  final FocusNode _focusNode = FocusNode();
  List<Widget> attachments = [];
  QuillController? _controller;
  String title = 'New Note';
  @override
  Widget build(BuildContext context) {
    return (_controller == null || _isLoading)
        ? _loadingScreen()
        : Scaffold(
            appBar: _getAppBar(),
            body: Column(
              children: [
                _buildEditPage(),
                const SizedBox(
                  height: 5,
                ),
                ListView(
                  shrinkWrap: true,
                  children: attachments,
                ),
              ],
            ),
          );
  }

  PreferredSizeWidget _getAppBar() {
    return AppBar(
      title: FlutterText.Text(title),
      actions: [
        shareButton(),
        renameButton(),
        saveButton(),
        attachAsset(),
      ],
    );
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
              onPressed: () async {
                setState(() {
                  if (_resultNameFormKey.currentState!.validate()) {
                    _newTitle = resultNameFieldController.text;
                  } else {
                    return;
                  }
                  _isLoading = true;
                  _currStatus = 'Renaming!';
                });
                Navigator.of(context).pop();
                NotesHelper(
                        tempDirectory: (await getTemporaryDirectory()),
                        resultName: title)
                    .renameNote(
                        RenameObject(oldName: title, newName: _newTitle))
                    .then((value) {
                  setState(() {
                    title = _newTitle;
                    _isLoading = false;
                  });
                });
              },
              child: const FlutterText.Text('Change Name'))
        ],
      ),
    );
  }

  Widget setPasswordField() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        children: [
          TextFormField(
            maxLength: 20,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Colors.amberAccent)),
            ),
            controller: passwordFieldController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter password';
              }
              return null;
            },
          ),
          ElevatedButton(
              onPressed: () {
                setState(() {
                  if (_passwordFormKey.currentState!.validate()) {
                    password = passwordFieldController.text;
                  }
                  Navigator.of(context).pop();
                });
              },
              child: const FlutterText.Text('Set!'))
        ],
      ),
    );
  }

  Widget _buildDialog(
      {required String dialogBoxTitle, required Widget widgetToShow}) {
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
              FlutterText.Text(
                dialogBoxTitle,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(
                height: 15,
              ),
              widgetToShow,
            ],
          ),
        ),
      ),
    );
  }

  Widget changeResultNameDialog() {
    return _buildDialog(
        dialogBoxTitle: 'Change Result File Name',
        widgetToShow: changeNameField());
  }

  Widget setPasswordDialog() {
    return _buildDialog(
        dialogBoxTitle: 'Set Password', widgetToShow: setPasswordField());
  }

  Widget renameButton() {
    return IconButton(
        onPressed: () async {
          showDialog(
              context: context, builder: (_) => changeResultNameDialog());
        },
        icon: const Icon(Icons.drive_file_rename_outline_rounded));
  }

  Widget attachAsset() {
    return IconButton(
        onPressed: () async {
          final newNotesHelper = NotesHelper(
              tempDirectory: (await getTemporaryDirectory()),
              resultName: title);
          FilePicker.platform
              .pickFiles(allowMultiple: true)
              .then((value) async {
            if (value != null) {
              final saveTitle = title;
              setState(() {
                title = 'Loading ...';
              });
              List<File> addedFiles = [];
              for (var pickedFiles in value.files) {
                attachments.add(_containerForAttachment(pickedFiles));
                addedFiles.add(File(pickedFiles.path!));
              }
              await newNotesHelper.addAsset(addedFiles);
              setState(() {
                title = saveTitle;
              });
            }
          });
        },
        icon: const Icon(Icons.attach_file_rounded));
  }

  Widget shareButton() {
    return IconButton(
        onPressed: () {
          _saveSteps();
          encrypt().then((value) => Share.shareFiles([value.path]));
        },
        icon: const Icon(Icons.share_rounded));
  }

  Widget saveButton() {
    return IconButton(
        onPressed: () async {
          await _saveSteps();
          encrypt().then((resultEncryptedFile) async {
            final params =
                SaveFileDialogParams(sourceFilePath: resultEncryptedFile.path);
            final filePath = await FlutterFileDialog.saveFile(params: params);
          });
        },
        icon: const Icon(Icons.save_rounded));
  }

  Future<void> _saveSteps() async {
    final newNoteHelper = NotesHelper(
        tempDirectory: (await getTemporaryDirectory()), resultName: title);
    await newNoteHelper.prepareToSaveNote();
    if (password == null) {
      await showDialog(context: context, builder: (_) => setPasswordDialog());
    }
  }

  Future<File> encrypt() async {
    final fileCrypt = AesCrypt(password!);
    final newNotesHelper = NotesHelper(
        tempDirectory: (await getTemporaryDirectory()), resultName: title);
    String encryptedResultPath = newNotesHelper.getEncryptTempDir() + '/$title';
    String encryptedFilePath = newNotesHelper.tempDirectory.path +
        '/${_help.encryptTempFolderName}/$title';
    setState(() {
      _isLoading = true;
      _currStatus = 'Encrypting';
    });

    /// get Zip from ~/cache/EnrcyptTemp/folders/[result_name] and save it ~/cache/EncryptTemp/[result_name]
    await compute(CompressionHelper().dirToZip, <String, dynamic>{
      'encryptionTempDirectory': Directory(encryptedResultPath),
      'encryptedFilePath': encryptedFilePath,
    });
    String filePath = await compute(fileCrypt.encryptFile, encryptedFilePath);
    File resultFile = File(filePath);
    try {
      resultFile = await resultFile.rename(
          filePath.substring(0, filePath.length - 3) + _help.extensionName);
    } on FileSystemException catch (e) {
      final newFile = resultFile.copy(
          filePath.substring(0, filePath.length - 3) + _help.extensionName);
      resultFile.deleteSync();
      resultFile = (await newFile);
    }
    setState(() {
      _isLoading = false;
      _currStatus = 'Finished!';
    });
    return resultFile;
  }

  Widget _containerForAttachment(PlatformFile platformFile) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FileIcon(platformFile.name),
        const SizedBox(
          width: 5,
        ),
        FlutterText.Text(
          platformFile.name,
          style: const TextStyle(color: Colors.white),
        ),
        const Spacer(),
        IconButton(
            onPressed: () async {
              final newNotesHelper = NotesHelper(
                  tempDirectory: (await getTemporaryDirectory()),
                  resultName: title);
              newNotesHelper.removeAsset([File(platformFile.path!)]);
            },
            icon: const Icon(Icons.cancel_outlined))
      ],
    );
  }

  Widget _loadingScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const LoadingWidget(),
        const SizedBox(
          height: 15,
        ),
        FlutterText.Text(
          _currStatus,
          style: const TextStyle(fontSize: 20, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildEditPage() {
    final quillEditor = QuillEditor(
        controller: _controller!,
        focusNode: _focusNode,
        scrollController: ScrollController(),
        scrollable: true,
        padding: EdgeInsets.zero,
        autoFocus: true,
        readOnly: false,
        expands: true);
    final toolBar = QuillToolbar.basic(
      controller: _controller!,
      onImagePickCallback: _onImagePickCallBack,
      onVideoPickCallback: _onVideoPickCallBack,
    );

    return Expanded(
        child: Column(
      children: [
        toolBar,
        const SizedBox(
          height: 15,
        ),
        Expanded(
            child: Container(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: quillEditor))
      ],
    ));
  }

  Future<String> _onImagePickCallBack(File file) async {
    return file.path.toString();
  }

  Future<String> _onVideoPickCallBack(File file) async {
    return file.path.toString();
  }

  Future<void> _loadPage() async {
    final Document doc = Document()..insert(0, 'Empty');
    _notesHelper = NotesHelper(
        tempDirectory: (await getTemporaryDirectory()), resultName: title);
    _notesHelper.setupNoteEncryptDir();
    setState(() {
      _controller = QuillController(
          document: doc, selection: const TextSelection.collapsed(offset: 0));
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPage();
  }
}
