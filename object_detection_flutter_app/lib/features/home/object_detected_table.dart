import 'package:flutter/material.dart';
import 'package:object_detection_flutter_app/core/theme/app_palette.dart';
import 'package:object_detection_flutter_app/features/home/object_detected.dart';
import 'package:provider/provider.dart';
import 'package:object_detection_flutter_app/features/home/table_row.dart';


class ObjectDetectedTable extends StatefulWidget {
  const ObjectDetectedTable({super.key});

  @override
  State<ObjectDetectedTable> createState() => _ObjectDetectedTableState();
}

class _ObjectDetectedTableState extends State<ObjectDetectedTable> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: Consumer<ObjectDetected>(
        builder: (context, objectDetected, _) {
          final rowObjects = objectDetected.objects;
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TableRowWidget(
                      label: "label",
                      location: "location",
                      timestamp: "Time",
                      color: const Color.fromARGB(0, 235, 107, 107),
                      borderColor: Palette.whiteColor,
                    ),
                ...rowObjects.map((obj) {
                  return TableRowWidget(
                    label: obj['label'],
                    location: obj['location'].toString(),
                    timestamp: DateTime.now().toString().toString(),
                    color: Palette.transparentColor,
                    borderColor: Palette.whiteColor,
                  );
          }).toList(),]
        ),
      ),
    ));
        },
      ),    
    );
  }
  }