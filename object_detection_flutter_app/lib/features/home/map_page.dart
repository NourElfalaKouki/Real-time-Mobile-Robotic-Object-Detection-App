import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
//import 'package:latlong2/latlong.dart';
import 'package:object_detection_flutter_app/core/theme/app_palette.dart';
import 'package:object_detection_flutter_app/features/home/object_detected.dart';
import 'package:provider/provider.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // List of marker data

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ObjectDetected>(
        builder: (context, objectDetected, _){
          final mapMarkers = objectDetected.markersData;
          return FlutterMap(
            options: MapOptions(
          initialCenter: mapMarkers.first['location'], 
          initialZoom: 18.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.yourapp',
          ),

          MarkerLayer(
            markers: mapMarkers.map((data) {
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
      );
        },
      )
    );
  }
}