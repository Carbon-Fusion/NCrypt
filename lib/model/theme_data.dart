import 'package:flutter/material.dart';

class AppTheme {
  static final darkTheme = ThemeData(
    primarySwatch: Colors.amber,
    primaryColor: Colors.black,
    brightness: Brightness.dark,
    dividerColor: Colors.black12,
    appBarTheme: const AppBarTheme(color: Color.fromRGBO(255, 223, 54, 0.5)),
    colorScheme:
        const ColorScheme.dark(primary: Color.fromRGBO(255, 223, 54, 0.5)),
  );
}
