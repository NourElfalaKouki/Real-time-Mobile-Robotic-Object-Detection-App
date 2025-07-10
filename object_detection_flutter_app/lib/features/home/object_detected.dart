import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';

class ObjectDetected with ChangeNotifier {
  List<Map<String, dynamic>> _markersData = [
  {'label': 'ROBOT', 'location': LatLng(36.8065, 10.1815), 'timestamp': DateTime.now()},
  {'label': 'DOG', 'location': LatLng(36.8100, 10.1900), 'timestamp': DateTime.now()},
  {'label': 'CAR', 'location': LatLng(36.8000, 10.1700), 'timestamp': DateTime.now()},
  ];

  final List<String> _labels = ['ROBOT', 'DOG', 'CAR'];

  List<Map<String, dynamic>> get markersData => _markersData;
  set markersData(List<Map<String, dynamic>> value) {
    _markersData = value;
    notifyListeners(); 
  }

  List<String> get labels => _labels;
  List<Map<String, dynamic>> get objects => _objects;
  final List<Map<String, dynamic>> _objects = [{'label': 'ROBOT', 'location': LatLng(36.8065, 10.1815), 'timestamp': DateTime.now()},
  {'label': 'DOG', 'location': LatLng(36.8100, 10.1900), 'timestamp': DateTime.now()},
  {'label': 'CAR', 'location': LatLng(36.8000, 10.1700), 'timestamp': DateTime.now()},
  {'label': 'ROBOT', 'location': LatLng(36.8065, 10.1815), 'timestamp': DateTime.now()},
  {'label': 'DOG', 'location': LatLng(36.8100, 10.1900), 'timestamp': DateTime.now()},
  {'label': 'CAR', 'location': LatLng(36.8000, 10.1700), 'timestamp': DateTime.now()},
  {'label': 'ROBOT', 'location': LatLng(36.8065, 10.1815), 'timestamp': DateTime.now()},
  {'label': 'DOG', 'location': LatLng(36.8100, 10.1900), 'timestamp': DateTime.now()},
  {'label': 'CAR', 'location': LatLng(36.8000, 10.1700), 'timestamp': DateTime.now()},
  {'label': 'ROBOT', 'location': LatLng(36.8065, 10.1815), 'timestamp': DateTime.now()},
  {'label': 'DOG', 'location': LatLng(36.8100, 10.1900), 'timestamp': DateTime.now()},
  {'label': 'CAR', 'location': LatLng(36.8000, 10.1700), 'timestamp': DateTime.now()},
  {'label': 'ROBOT', 'location': LatLng(36.8065, 10.1815), 'timestamp': DateTime.now()},
  {'label': 'DOG', 'location': LatLng(36.8100, 10.1900), 'timestamp': DateTime.now()},
  {'label': 'CAR', 'location': LatLng(36.8000, 10.1700), 'timestamp': DateTime.now()},
  {'label': 'ROBOT', 'location': LatLng(36.8065, 10.1815), 'timestamp': DateTime.now()},
  {'label': 'DOG', 'location': LatLng(36.8100, 10.1900), 'timestamp': DateTime.now()},
  {'label': 'CAR', 'location': LatLng(36.8000, 10.1700), 'timestamp': DateTime.now()},
  {'label': 'ROBOT', 'location': LatLng(36.8065, 10.1815), 'timestamp': DateTime.now()},
  {'label': 'DOG', 'location': LatLng(36.8100, 10.1900), 'timestamp': DateTime.now()},
  {'label': 'CAR', 'location': LatLng(36.8000, 10.1700), 'timestamp': DateTime.now()},
  {'label': 'ROBOT', 'location': LatLng(36.8065, 10.1815), 'timestamp': DateTime.now()},
  {'label': 'DOG', 'location': LatLng(36.8100, 10.1900), 'timestamp': DateTime.now()},
  {'label': 'CAR', 'location': LatLng(36.8000, 10.1700), 'timestamp': DateTime.now()},
  {'label': 'ROBOT', 'location': LatLng(36.8065, 10.1815), 'timestamp': DateTime.now()},
  {'label': 'DOG', 'location': LatLng(36.8100, 10.1900), 'timestamp': DateTime.now()},
  {'label': 'CAR', 'location': LatLng(36.8000, 10.1700), 'timestamp': DateTime.now()},
  {'label': 'ROBOT', 'location': LatLng(36.8065, 10.1815), 'timestamp': DateTime.now()},
  {'label': 'DOG', 'location': LatLng(36.8100, 10.1900), 'timestamp': DateTime.now()},
  {'label': 'CAR', 'location': LatLng(36.8000, 10.1700), 'timestamp': DateTime.now()},];


  void addObjectDetected(String label, LatLng location) {
    _objects.add({
      'label': label,
      'location': location,
    });
    notifyListeners(); // Notify MapPage to rebuild
  }
}