import 'package:flutter/material.dart';
import 'package:object_detection_flutter_app/core/theme/app_palette.dart';

class AppTheme{
  static final DarkThemeMode = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: Palette.backgroundColor,
    inputDecorationTheme:const InputDecorationTheme(
      contentPadding:EdgeInsets.all(25) ,
      labelStyle: TextStyle(color: Palette.whiteColor),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Palette.blueColor, width: 2.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Palette.borderColor, width: 2.0),
      ),
    ),
    ); 
}