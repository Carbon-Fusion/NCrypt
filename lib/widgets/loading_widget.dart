import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingWidget extends StatefulWidget {
  const LoadingWidget({Key? key}) : super(key: key);

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SpinKitCircle(
        size: 200,
        itemBuilder: (context, index) {
          final colors = [const Color.fromRGBO(255, 223, 54, 0.5), Colors.cyan];
          final color = colors[index % colors.length];
          final shapes = [BoxShape.rectangle, BoxShape.circle];
          return DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              shape: shapes[index % 2],
            ),
          );
        },
      ),
    );
  }
}
