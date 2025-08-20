import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';

class ObjectDetected with ChangeNotifier {
  List<Map<String, dynamic>> _markersData = [];
  final List<String> _labels = [];
  final List<Map<String, dynamic>> _objects = [];

  List<Map<String, dynamic>> get markersData => _markersData;
  List<String> get labels => _labels;
  List<Map<String, dynamic>> get objects => _objects;

  void updateFromGeoJson(Map<String, dynamic> geoJson) {
    debugPrint('🔍 ObjectDetected: Starting updateFromGeoJson');
    debugPrint('📊 Input GeoJSON: $geoJson');

    _markersData.clear();
    debugPrint('🧹 Cleared markersData, count: ${markersData.length}');

    if (geoJson['features'] is List) {
      debugPrint('✅ Features is a List with ${geoJson['features'].length} items');

      for (var feature in geoJson['features']) {
        debugPrint('🔄 Processing feature: $feature');
        final geometry = feature['geometry'];
        final properties = feature['properties'];
        debugPrint('📍 Geometry: $geometry');
        debugPrint('🏷️ Properties: $properties');

        final coordinates = geometry['coordinates'] as List<dynamic>;
        final label = properties['label'] as String;
        final timestamp = properties['timestamp'] as String;
        debugPrint('📌 Coordinates: $coordinates');
        debugPrint('🏷️ Label: $label');
        debugPrint('⏰ Timestamp: $timestamp');

        final longitude = coordinates[0] as double;
        final latitude = coordinates[1] as double;
        // Extract altitude if available (coordinates[2])
        final altitude = coordinates.length > 2 ? coordinates[2] as double? : null;
        
        debugPrint('🌐 Parsed - Longitude: $longitude, Latitude: $latitude, Altitude: $altitude');

        final markerData = {
          'label': label,
          'location': LatLng(latitude, longitude),
          'altitude': altitude,
          'timestamp': timestamp,
        };
        debugPrint('📊 Created marker data: $markerData');
        _markersData.add(markerData);
        debugPrint('📍 Added to markersData, new count: ${markersData.length}');

        // Check for duplicates in _objects based on label and location
        final newLocation = LatLng(latitude, longitude);
        bool isDuplicate = _objects.any((obj) =>
            obj['label'] == label &&
            obj['location'].latitude == newLocation.latitude &&
            obj['location'].longitude == newLocation.longitude);

        if (!isDuplicate) {
          _objects.add({
            'label': label,
            'location': newLocation,
            'altitude': altitude,
            'timestamp': timestamp,
          });
          debugPrint('📦 Added to objects, new count: ${objects.length}');
        } else {
          debugPrint('📦 Object already exists in _objects, skipping');
        }

        if (!_labels.contains(label)) {
          _labels.add(label);
          debugPrint('🏷️ Added new label: $label, labels count: ${_labels.length}');
        } else {
          debugPrint('🏷️ Label already exists: $label');
        }
      }
    } else {
      debugPrint('❌ Features is not a List or is null');
    }

    debugPrint('📊 Final counts:');
    debugPrint(' - markersData: ${markersData.length}');
    debugPrint(' - objects: ${objects.length}');
    debugPrint(' - labels: ${labels.length}');
    debugPrint(' - Labels: $_labels');

    notifyListeners();
    debugPrint('🔔 Notified listeners');
  }
}