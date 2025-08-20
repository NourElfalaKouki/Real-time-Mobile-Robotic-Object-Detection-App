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
import 'features/home/object_detection_socket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Check authentication status
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // Initialize providers
  final objectDetected = ObjectDetected();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ObjectDetected>.value(value: objectDetected),
        ChangeNotifierProvider(
          create: (_) => SocketService(objectDetected)..initSocket(),
        ),
      ],
      child: MaterialApp(
        title: 'Object Detection App',
        theme: AppTheme.DarkThemeMode,
        // Show LoginPage if not authenticated, MainPage if authenticated
        home: isLoggedIn ? const MainPage() : const LoginPage(),
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}

/*
void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Check authentication status
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // Initialize providers
  final objectDetected = ObjectDetected();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ObjectDetected>.value(value: objectDetected),
        ChangeNotifierProvider(
          create: (_) => SocketService(objectDetected)..initSocket(),
        ),
      ],
      child: MaterialApp(
        title: 'Object Detection App',
        theme: AppTheme.DarkThemeMode,
        // Show LoginPage if not authenticated, MainPage if authenticated
        home: const MainPage() ,
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}
*/