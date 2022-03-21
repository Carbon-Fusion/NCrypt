import 'package:flutter/material.dart';

class AppTheme {
  static final darkTheme = ThemeData(
    primarySwatch: Colors.blue,
    primaryColor: Colors.black,
    brightness: Brightness.dark,
    dividerColor: Colors.black12,
    appBarTheme: const AppBarTheme(color: Color(0xFF0251a0)),
    colorScheme: const ColorScheme.dark(primary: Color(0xFF0251a0)),
  );
}
