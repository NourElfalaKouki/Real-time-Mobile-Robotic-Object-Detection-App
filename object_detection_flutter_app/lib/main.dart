import 'package:flutter/material.dart';
import 'package:object_detection_flutter_app/core/theme/theme.dart';
//import 'package:object_detection_flutter_app/features/authentification/login_page.dart';
//import 'package:object_detection_flutter_app/features/authentification/signup_page.dart';
import 'package:object_detection_flutter_app/features/home/map_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: AppTheme.DarkThemeMode,
      home: const MapPage(),
    );
  }
}
