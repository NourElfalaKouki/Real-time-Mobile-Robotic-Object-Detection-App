import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:object_detection_flutter_app/core/theme/app_palette.dart';
import 'package:object_detection_flutter_app/features/home/object_detected.dart';
import 'package:object_detection_flutter_app/features/home/object_detection_socket_service.dart';
import 'package:provider/provider.dart';
import 'package:object_detection_flutter_app/features/home/object_detection_socket_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Set<String> _selectedLabels = {}; // Will be initialized from provider

  void _showFilterDialog(BuildContext context, List<String> availableLabels) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filter Objects'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: availableLabels.map((label) {
                    return CheckboxListTile(
                      title: Text(label),
                      value: _selectedLabels.contains(label),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedLabels.add(label);
                          } else {
                            _selectedLabels.remove(label);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {}); // Refresh the main widget
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SocketService>(
        builder: (context, socketService,_ ) {
          // Initialize selected labels with all available labels if empty
          if (_selectedLabels.isEmpty) {
            _selectedLabels = Set<String>.from(socketService.objectDetected.labels);
          }
          
          // Get all markers and filter based on selected labels
          final allMarkers = socketService.objectDetected.markersData;
          final filteredMarkers = allMarkers
              .where((marker) => _selectedLabels.contains(marker['label']))
              .toList();

          return FlutterMap(
            options: MapOptions(
              initialCenter: filteredMarkers.isNotEmpty
                  ? filteredMarkers.first['location']
                  : const LatLng(36.8065, 10.1815), // Fallback to Tunis center, change as you want
              initialZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.yourapp',
              ),
              MarkerLayer(
                markers: filteredMarkers.map((data) {
                  return Marker(
                    width: 80,
                    height: 80,
                    point: data['location'],
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${data['label']}\n${data['location']}',
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
      ),
      floatingActionButton: Consumer<ObjectDetected>(
        builder: (context, objectDetected, _) {
          return FloatingActionButton(
            onPressed: () => _showFilterDialog(context, objectDetected.labels),
            backgroundColor: Palette.robotMarkerColor,
            child: const Icon(Icons.filter_list),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}