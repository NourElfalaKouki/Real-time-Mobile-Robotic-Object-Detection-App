import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:object_detection_flutter_app/core/theme/app_palette.dart';
import 'package:object_detection_flutter_app/features/home/object_detected.dart';
import 'package:object_detection_flutter_app/features/home/object_detection_socket_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class ExportButton extends StatelessWidget {
  const ExportButton({super.key});

  Future<void> _onExport(BuildContext context, String format) async {
    final socketService = context.read<SocketService>();
    final objectDetected = socketService.objectDetected;
    final objects = objectDetected.objects;

    String exportData;
    if (format == 'csv') {
      exportData = _exportObjectsToCsv(objects);
    } else {
      exportData = _exportObjectsToGeoJson(objects);
    }

    // Request storage permission (Android)
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission denied')),
        );
        return;
      }
    }

    try {
      Directory? directory;

      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        // On Android, you may want to save in the 'Downloads' folder if possible.
        // But getExternalStorageDirectory() points to app-specific directory.
        // For simplicity, we use this directory.
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final path = directory?.path ?? '';
      final fileName = 'export_${DateTime.now().toIso8601String().replaceAll(':', '-')}.${format}';
      final file = File('$path/$fileName');

      await file.writeAsString(exportData);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('File Saved'),
          content: Text('Exported as $fileName\n Path:\n$path'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save file: $e')),
      );
    }
  }

  String _exportObjectsToCsv(List<Map<String, dynamic>> objects) {
    final buffer = StringBuffer('label,latitude,longitude,timestamp\n');
    for (var obj in objects) {
      final label = obj['label'];
      final location = obj['location'] as LatLng;
      final timestamp = obj['timestamp'];
      buffer.writeln('$label,${location.longitude},${location.latitude},$timestamp');
    }
    return buffer.toString();
  }

  String _exportObjectsToGeoJson(List<Map<String, dynamic>> objects) {
    final features = objects.map((obj) {
      final location = obj['location'] as LatLng;
      return {
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [location.longitude, location.latitude],
        },
        "properties": {
          "label": obj['label'],
          "timestamp": obj['timestamp'],
        },
      };
    }).toList();

    final geoJson = {
      "type": "FeatureCollection",
      "features": features,
    };

    return JsonEncoder.withIndent('  ').convert(geoJson);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Palette.gradient1, Palette.gradient2],
          begin: Alignment.centerLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        offset: const Offset(0, 60),
        onSelected: (value) async => await _onExport(context, value),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: 'csv',
            child: Text('Export as CSV'),
          ),
          PopupMenuItem(
            value: 'geojson',
            child: Text('Export as GeoJSON'),
          ),
        ],
        child: SizedBox(
          width: 395,
          height: 55,
          child: Center(
            child: Text(
              'Export',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
