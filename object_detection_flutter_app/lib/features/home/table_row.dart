import 'package:flutter/material.dart';
import 'package:object_detection_flutter_app/features/home/table_cell.dart';


class TableRowWidget extends StatelessWidget {
  final String label;
  final String location;
  final String timestamp;
  final Color color;
  final Color borderColor;

  const TableRowWidget({
    super.key,
    required this.label,
    required this.location,
    required this.timestamp,
    required this.color,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomTableCell(
            text: label,
            color: color,
            borderColor: borderColor,
          ),
        ),
        Expanded(
          child:  CustomTableCell(
            text: location,
            color: color,
            borderColor: borderColor,
          ),
        ),
        Expanded(
          child: CustomTableCell(
            text: timestamp,
            color: color,
            borderColor: borderColor,
          ),
        ),
      ],
    );
  }
}