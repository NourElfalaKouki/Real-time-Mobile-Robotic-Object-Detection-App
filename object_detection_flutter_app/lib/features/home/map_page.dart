import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:object_detection_flutter_app/core/theme/app_palette.dart';
import 'package:object_detection_flutter_app/features/home/object_detected.dart';
import 'package:object_detection_flutter_app/features/home/object_detection_socket_service.dart';
import 'package:provider/provider.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final MapController _mapController;
  Set<String> _selectedLabels = {};

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

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
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {}); // Rebuild map markers
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
        builder: (context, socketService, _) {
          if (_selectedLabels.isEmpty) {
            _selectedLabels = Set<String>.from(
              socketService.objectDetected.labels,
            );
          }

          final allMarkers = socketService.objectDetected.markersData;
          final filteredMarkers = allMarkers
              .where((marker) => _selectedLabels.contains(marker['label']))
              .toList();

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: filteredMarkers.isNotEmpty
                  ? filteredMarkers.first['location']
                  : const LatLng(36.8065, 10.1815),
              initialZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.yourapp',
              ),
              MarkerLayer(
                markers: filteredMarkers.map((data) {
                  final timestamp = data['timestamp'].toString();
                  final timeOnly = timestamp.split('T').length > 1
                      ? timestamp.split('T')[1].split('.')[0] // '16:48:26'
                      : timestamp;

                  return Marker(
                    width: 200,
                    height: 200,
                    point: data['location'],
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '${data['label']}' +
                                '\nLon: ${data['location'].longitude.toStringAsFixed(5)}' +
                                '\nLat: ${data['location'].latitude.toStringAsFixed(5)}' +
                                '\nTime: $timeOnly',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Icon(
                          data['label'] == 'ROBOT'
                              ? Icons.circle
                              : Icons.location_pin,
                          size: 40,
                          color: data['label'] != 'ROBOT'
                              ? Palette.restMarkerColor
                              : Palette.robotMarkerColor,
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
