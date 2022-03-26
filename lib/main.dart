import 'package:encryptF/model/theme_data.dart';
import 'package:encryptF/pages/home_screen.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Encrypt!', theme: AppTheme.darkTheme, home: const HomeScreen());
  }
}
