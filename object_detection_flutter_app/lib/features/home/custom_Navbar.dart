import 'package:flutter/material.dart';
import 'package:object_detection_flutter_app/core/theme/app_palette.dart';

class CustomNavbar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomNavbar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onTap,

      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
      backgroundColor: Palette.backgroundColorNavbar,

      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.map),
          label: 'Map',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.table_chart),
          label: 'Object Detected Table',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}
