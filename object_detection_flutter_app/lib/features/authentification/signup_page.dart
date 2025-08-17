import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:object_detection_flutter_app/features/authentification/Password_widget.dart';
import 'package:object_detection_flutter_app/features/authentification/auth_button.dart';
import 'package:object_detection_flutter_app/features/authentification/login_page.dart';
import 'package:object_detection_flutter_app/core/theme/app_palette.dart';
import 'package:object_detection_flutter_app/features/home/main_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final usernameController = TextEditingController(); // Changed from nameController
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      _showErrorSnackbar('Passwords do not match');
      return;
    }

    setState(() => isLoading = true);
    
    try {
      final url = Uri.parse("http://localhost:9000/signup");
      
      // Debug print for request
      print('Sending signup request to: $url');
      print('Username: ${usernameController.text.trim()}');
      print('Password: ${passwordController.text.trim()}');
      
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": usernameController.text.trim(), // Changed from "name" to "username"
          "password": passwordController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      // Debug print for response
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 201) {
        // Automatically log user in after successful signup
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signup successful!')),
        );
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainPage()),
        );
      } else {
        // Improved error handling
        final responseBody = jsonDecode(response.body);
        final error = responseBody['error'] ?? 'Signup failed (${response.statusCode})';
        _showErrorSnackbar(error);
      }
    } catch (e) {
      print('Signup error: $e');
      _showErrorSnackbar('Connection error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: const Alignment(0, -0.5),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sign Up',
                style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: usernameController, // Changed from nameController
                enabled: !isLoading,
                validator: (val) =>
                    val!.trim().isEmpty ? 'Please enter your username' : null, // Updated message
                decoration: const InputDecoration(
                  labelText: 'Username', // Changed from Account Name
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              PasswordField(
                controller: passwordController,
                labelText: 'Password',
                enabled: !isLoading,
              ),
              const SizedBox(height: 20),
              PasswordField(
                controller: confirmPasswordController,
                labelText: 'Confirm Password',
                enabled: !isLoading,
              ),
              const SizedBox(height: 20),
              if (isLoading)
                const CircularProgressIndicator()
              else
                AuthButton(
                  buttonText: 'Sign Up',
                  onTap: _signup,
                ),
              const SizedBox(height: 20),
              IgnorePointer(
                ignoring: isLoading,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: Theme.of(context).textTheme.titleMedium,
                      children: const [
                        TextSpan(
                          text: 'Log In',
                          style: TextStyle(
                            color: Palette.gradient2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}