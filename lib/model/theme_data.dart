import 'package:flutter/material.dart';

class AppTheme {
  static final darkTheme = ThemeData(
    primarySwatch: Colors.grey,
    primaryColor: const Color.fromRGBO(193, 193, 193, 1),
    brightness: Brightness.dark,
    dividerColor: Colors.black12,
    scaffoldBackgroundColor: const Color.fromRGBO(33, 33, 33, 1),
    appBarTheme: const AppBarTheme(color: Color.fromRGBO(48, 48, 48, 1)),
    colorScheme:
        const ColorScheme.dark(primary: Color.fromRGBO(193, 193, 193, 1)),
  );
}
