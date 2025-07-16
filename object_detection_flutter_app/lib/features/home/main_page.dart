import 'package:flutter/material.dart';
import 'package:object_detection_flutter_app/features/home/custom_Navbar.dart';
import 'package:object_detection_flutter_app/features/home/map_page.dart';
import 'package:object_detection_flutter_app/features/home/object_detected_table.dart';
import 'package:object_detection_flutter_app/features/home/setting_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [MapPage(), ObjectDetectedTable(), SettingPage()];
  }

  void _onIconTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
        child: _pages[_selectedIndex],
      ), // Display selected page
      bottomNavigationBar: CustomNavbar(
        selectedIndex: _selectedIndex,
        onTap: _onIconTap,
      ),
    );
  }
}
