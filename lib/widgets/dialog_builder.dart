import 'dart:ui';

import 'package:flutter/material.dart';

class DialogBuilder extends StatefulWidget {
  final String dialogBoxTitle;
  final Widget widgetToShow;
  const DialogBuilder(
      {Key? key, required this.dialogBoxTitle, required this.widgetToShow})
      : super(key: key);

  @override
  State<DialogBuilder> createState() => _DialogBuilderState();
}

class _DialogBuilderState extends State<DialogBuilder> {
  @override
  Widget build(BuildContext context) {
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
              Text(
                widget.dialogBoxTitle,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(
                height: 15,
              ),
              widget.widgetToShow,
            ],
          ),
        ),
      ),
    );
  }
}
