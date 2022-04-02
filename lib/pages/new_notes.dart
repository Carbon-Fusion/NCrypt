import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:aes_crypt_null_safe/aes_crypt_null_safe.dart';
import 'package:encryptF/helpers/compression_helper.dart';
import 'package:encryptF/helpers/misc_helper.dart';
import 'package:encryptF/helpers/notes_helper.dart';
import 'package:encryptF/model/file_info.dart';
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

import '../widgets/dialog_builder.dart';

class NewNotes extends StatefulWidget {
  final Directory? note;
  const NewNotes({Key? key, this.note}) : super(key: key);

  @override
  State<NewNotes> createState() => _NewNotesState();
}

class _NewNotesState extends State<NewNotes> {
  bool _isLoading = false;
  String _currStatus = '...';
  String _newTitle = '...';
  String? password;
  late NotesHelper _notesHelper;
  final _useColor = const Color.fromRGBO(253, 253, 253, 1);
  final _help = MiscHelper();
  final resultNameFieldController = TextEditingController();
  final _resultNameFormKey = GlobalKey<FormState>();
  final passwordFieldController = TextEditingController();
  final _passwordFormKey = GlobalKey<FormState>();
  final FocusNode _focusNode = FocusNode();
  List<File> attachments = [];
  Set<String> includedAttachmentPaths = {};
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
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: attachments.length,
                  itemBuilder: (context, index) {
                    return Dismissible(
                        key: Key(attachments[index].path),
                        onDismissed: (DismissDirection direction) async {
                          setState(() {
                            attachments.removeAt(index);
                          });
                          final newNotesHelper = NotesHelper(
                              tempDirectory: (await getTemporaryDirectory()),
                              resultName: title);
                          newNotesHelper
                              .removeAsset([File(attachments[index].path)]);
                        },
                        child: _containerForAttachment(attachments[index]));
                  },
                ),
              ],
            ),
          );
  }

  PreferredSizeWidget _getAppBar() {
    return AppBar(
      title: FlutterText.Text(
        title,
        style: TextStyle(color: _useColor),
      ),
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
              } else if (!validatePass(value)) {
                return 'Please use 1 Upper Case\n 5 Lower case \n 2 Symbols \n 2 Numbers\n';
              } else {
                return null;
              }
            },
          ),
          ElevatedButton(
              onPressed: () {
                setState(() {
                  if (_passwordFormKey.currentState!.validate()) {
                    password = passwordFieldController.text;
                    Navigator.of(context).pop();
                  }
                });
              },
              child: const FlutterText.Text('Set!'))
        ],
      ),
    );
  }

  Widget changeResultNameDialog() {
    return DialogBuilder(
        dialogBoxTitle: 'Change Result File Name',
        widgetToShow: changeNameField());
  }

  Widget setPasswordDialog() {
    return DialogBuilder(
        dialogBoxTitle: 'Set Password', widgetToShow: setPasswordField());
  }

  Widget renameButton() {
    return IconButton(
        onPressed: () async {
          showDialog(
              context: context, builder: (_) => changeResultNameDialog());
        },
        icon: Icon(
          Icons.drive_file_rename_outline_rounded,
          color: _useColor,
        ));
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
              List<File> addedFiles = [];
              for (var pickedFiles in value.files) {
                setState(() {
                  if (!includedAttachmentPaths.contains(pickedFiles.path!)) {
                    attachments.add(File(pickedFiles.path!));
                    addedFiles.add(File(pickedFiles.path!));
                    includedAttachmentPaths.add(pickedFiles.path!);
                  }
                });
              }
              await newNotesHelper.addAsset(addedFiles);
            }
          });
        },
        icon: Icon(
          Icons.attach_file_rounded,
          color: _useColor,
        ));
  }

  Widget shareButton() {
    return IconButton(
        onPressed: () async {
          await _saveSteps();
          await encrypt().then((value) => Share.shareFiles([value.path]));
        },
        icon: Icon(
          Icons.lock,
          color: _useColor,
        ));
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
        icon: Icon(
          Icons.save_rounded,
          color: _useColor,
        ));
  }

  Future<void> _saveSteps() async {
    final newNoteHelper = NotesHelper(
        tempDirectory: (await getTemporaryDirectory()), resultName: title);
    final documentJson = jsonEncode(_controller!.document.toDelta().toJson());
    await newNoteHelper.prepareToSaveNote(documentJson);
    if (password == null) {
      await showDialog(context: context, builder: (_) => setPasswordDialog());
    }
  }

  bool validatePass(String pass) {
    String pattern =
        r'^(?=.*?[A-Z])(?=.*?[a-z]{5,}.*)(?=.*?[0-9]{2,}.*)(?=.*?[!@#\$&*~]{2,}.*).{8,}$';
    RegExp regExp = RegExp(pattern);
    return regExp.hasMatch(pass);
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

  Widget _containerForAttachment(File file) {
    final name = file.path.split('/').last;
    return ListTile(
      leading: FileIcon(name),
      title: FlutterText.Text(
        name,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white),
      ),
      onLongPress: () {
        showDialog(
            context: context,
            builder: (_) => BackdropFilter(
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
                            name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          IntrinsicWidth(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ElevatedButton.icon(
                                    onPressed: () {
                                      Share.shareFiles([file.path]);
                                    },
                                    icon: const Icon(Icons.share_rounded),
                                    label: const FlutterText.Text('Share')),
                                const SizedBox(
                                  height: 15,
                                ),
                                ElevatedButton.icon(
                                    onPressed: () async {
                                      final params = SaveFileDialogParams(
                                          sourceFilePath: file.path);
                                      final filePath =
                                          await FlutterFileDialog.saveFile(
                                              params: params);
                                    },
                                    icon: const Icon(Icons.download_rounded),
                                    label: const FlutterText.Text('Download')),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ));
      },
    );
  }

  Widget _loadingScreen() {
    return Scaffold(
      body: Column(
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
      ),
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
      showCameraButton: false,
      showImageButton: false,
      showVideoButton: false,
      showLeftAlignment: false,
      showRightAlignment: false,
      showHeaderStyle: false,
      showColorButton: false,
      showIndent: false,
      showCodeBlock: false,
      showClearFormat: false,
      showBackgroundColorButton: false,
      showInlineCode: false,
      showQuote: false,
      showBoldButton: false,
      showItalicButton: false,
      showListCheck: false,
      showAlignmentButtons: false,
      showStrikeThrough: false,
      showCenterAlignment: false,
      showDividers: false,
      showDirection: false,
      showLink: false,
      showListBullets: false,
      showListNumbers: false,
      showUnderLineButton: false,
      showJustifyAlignment: false,
      showSmallButton: false,

      /// Intentionally Don't provide
      // onImagePickCallback: _onImagePickCallBack,
      // onVideoPickCallback: _onVideoPickCallBack,
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

  Future<void> _loadAssets() async {
    final newNotesHelper = NotesHelper(
        tempDirectory: (await getTemporaryDirectory()), resultName: title);
    final assetFolder = Directory(newNotesHelper.getAssetFolderPath());
    if (assetFolder.existsSync()) {
      for (var entity in assetFolder.listSync()) {
        if (entity is File) {
          setState(() {
            attachments.add(entity);
          });
        }
      }
    }
  }

  Future<void> _loadPage() async {
    var newDoc = Document()..insert(0, 'Empty');

    if (widget.note != null) {
      final configFile = File(widget.note!.path + '/${_help.configFileName}');
      if (!configFile.existsSync()) {
        throw Exception('No Config FILE found fatal!');
      }
      final fileInfo =
          FileInfo.fromJson(jsonDecode(configFile.readAsStringSync()));

      setState(() {
        title = fileInfo.fileName;
      });

      final documentFile =
          File(widget.note!.path + '/${_help.fileFolderName}/document');
      if (documentFile.existsSync()) {
        newDoc = Document.fromJson(jsonDecode(documentFile.readAsStringSync()));
      }
    }
    _notesHelper = NotesHelper(
        tempDirectory: (await getTemporaryDirectory()), resultName: title);

    if (widget.note != null) {
      await _notesHelper.setupNoteEncryptDir(
          isNew: true, inputDirPath: widget.note!.path);
    } else {
      await _notesHelper.setupNoteEncryptDir();
    }
    setState(() {
      _controller = QuillController(
          document: newDoc,
          selection: const TextSelection.collapsed(offset: 0));
    });

    if (widget.note != null) {
      _loadAssets();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPage();
  }
}
