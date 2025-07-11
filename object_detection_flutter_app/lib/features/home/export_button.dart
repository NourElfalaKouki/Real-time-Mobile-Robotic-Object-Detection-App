import 'package:flutter/material.dart';
import 'package:object_detection_flutter_app/core/theme/app_palette.dart';

class ExportButton extends StatelessWidget {
  final void Function(String format) onExport;

  const ExportButton({super.key, required this.onExport});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Palette.gradient1,
            Palette.gradient2,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        offset: const Offset(0, 60), 
        onSelected: (value) => onExport(value),
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
        child: ElevatedButton(
          onPressed: null, 
          style: ElevatedButton.styleFrom(
            fixedSize: const Size(395, 55),
            backgroundColor: Palette.transparentColor,
            shadowColor: Palette.transparentColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          child: const Text(
            'Export',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
