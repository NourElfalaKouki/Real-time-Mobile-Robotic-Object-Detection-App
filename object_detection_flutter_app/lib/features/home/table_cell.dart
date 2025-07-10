import 'package:flutter/material.dart';

class CustomTableCell extends StatelessWidget {
  final String text;
  final Color color;
  final Color borderColor;
  const CustomTableCell({super.key, required this.text, required this.color, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
            ),
          );
  }
}