import 'package:flutter/material.dart';

class PasswordField extends StatefulWidget {
  final TextEditingController controller; 
  final String labelText;
  final bool enabled; // Add enabled parameter
  
  const PasswordField({
    super.key, 
    required this.controller,
    required this.labelText,
    this.enabled = true, // Set default value to true
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      enabled: widget.enabled, // Add this line to use the enabled parameter
      decoration: InputDecoration(
        labelText: widget.labelText,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: widget.enabled ? _toggleVisibility : null, // Disable toggle when field is disabled
        ),
      ),
    );
  }
}