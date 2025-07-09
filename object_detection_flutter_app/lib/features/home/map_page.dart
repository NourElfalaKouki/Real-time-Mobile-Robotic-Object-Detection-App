import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:object_detection_flutter_app/core/theme/app_palette.dart';
import 'package:object_detection_flutter_app/features/home/Markers.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // List of marker data
  

  // Method to add a new marker dynamically
  void addMarker(String label, LatLng location) {
    setState(() {
      Markers().markersData.add({
        'label': label,
        'location': location,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          initialCenter: Markers().markersData.first['location'], // Center on first marker (robot)
          initialZoom: 18.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.yourapp',
          ),

          MarkerLayer(
            markers: Markers().markersData.map((data) {
              return Marker(
                width: 80,
                height: 80,
                point: data['location'],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data['label'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Palette.mapTextColor,
                        backgroundColor: Palette.mapBackgroundColor,
                      ),
                    ),
                    Icon(
                      data['label'] == 'ROBOT' ? Icons.circle : Icons.location_pin,
                      size: 40,
                      color: data['label'] != 'ROBOT' ? Palette.restMarkerColor : Palette.robotMarkerColor,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}