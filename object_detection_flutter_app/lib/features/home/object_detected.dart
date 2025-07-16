import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';

class ObjectDetected with ChangeNotifier {
  List<Map<String, dynamic>> _markersData = [];
  final List<String> _labels = [];
  List<Map<String, dynamic>> get markersData => _markersData;
  List<String> get labels => _labels;
  List<Map<String, dynamic>> get objects => _objects;
  final List<Map<String, dynamic>> _objects = [];

  void updateFromGeoJson(Map<String, dynamic> geoJson) {
    debugPrint('🔍 ObjectDetected: Starting updateFromGeoJson');
    debugPrint('📊 Input GeoJSON: $geoJson');
    
    _markersData.clear();
    debugPrint('🧹 Cleared _markersData, count: ${_markersData.length}');
    
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
        debugPrint('🌐 Parsed - Longitude: $longitude, Latitude: $latitude');
        
        final markerData = {
          'label': label,
          'location': LatLng(latitude, longitude),
          'timestamp': timestamp,
        };
        debugPrint('📊 Created marker data: $markerData');
        
        _markersData.add(markerData);
        debugPrint('📍 Added to _markersData, new count: ${_markersData.length}');
        
        _objects.add({
          'label': label,
          'location': LatLng(latitude, longitude),
          'timestamp': timestamp,
        });
        debugPrint('📦 Added to _objects, new count: ${_objects.length}');
        
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
    debugPrint('   - _markersData: ${_markersData.length}');
    debugPrint('   - _objects: ${_objects.length}');
    debugPrint('   - _labels: ${_labels.length}');
    debugPrint('   - Labels: $_labels');
    
    notifyListeners();
    debugPrint('🔔 Notified listeners');
  }
}