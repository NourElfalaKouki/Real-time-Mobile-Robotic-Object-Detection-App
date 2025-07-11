import 'package:flutter/material.dart';
import 'package:object_detection_flutter_app/core/theme/theme.dart';
import 'package:object_detection_flutter_app/features/authentification/login_page.dart';
import 'package:object_detection_flutter_app/features/authentification/signup_page.dart';
//import 'package:object_detection_flutter_app/features/authentification/login_page.dart';
//import 'package:object_detection_flutter_app/features/authentification/signup_page.dart';
import 'package:object_detection_flutter_app/features/home/map_page.dart';
import 'package:object_detection_flutter_app/features/home/object_detected_table.dart';
import 'package:provider/provider.dart';
import 'features/home/object_detected.dart';
import 'features/home/main_page.dart';


void main() => runApp(
      ChangeNotifierProvider(
        create: (_) => ObjectDetected(),
        child: MaterialApp(
          title: 'Flutter Demo',
          theme: AppTheme.DarkThemeMode,
          home: const MyApp(),
        ),
      ),
    );

/*
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ObjectDetected(),
      child: MyApp(),
    ),
  );
}*/

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: AppTheme.DarkThemeMode,
      home:  SignupPage(
        //markersData: markersData,
      ),
      //home: const MapPage(),
      //home: const MarkerTable(markersData: markersData),
      //home: const LoginPage(),
    );
  }
}

