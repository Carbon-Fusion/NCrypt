import 'package:flutter/material.dart';

class AppTheme {
  static final darkTheme = ThemeData(
    primarySwatch: Colors.blue,
    primaryColor: Colors.white,
    brightness: Brightness.dark,
    dividerColor: Colors.black12,
    appBarTheme: const AppBarTheme(color: Color.fromRGBO(83, 156, 218, 1)),
    colorScheme:
        const ColorScheme.dark(primary: Color.fromRGBO(84, 157, 220, 1)),
  );
}
