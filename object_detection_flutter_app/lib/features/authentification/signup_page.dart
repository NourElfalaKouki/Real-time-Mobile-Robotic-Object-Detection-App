import 'package:flutter/material.dart';
import 'package:object_detection_flutter_app/features/authentification/Password_widget.dart';
import 'package:object_detection_flutter_app/features/authentification/auth_button.dart';
import 'package:object_detection_flutter_app/features/authentification/login_page.dart';
import 'package:object_detection_flutter_app/core/theme/app_palette.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
  nameController.dispose();
  passwordController.dispose();
  super.dispose();
  formKey.currentState!.validate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Align(
  alignment: const Alignment(0, -0.5),
  child: Form(
    key: formKey,
    child:Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text(
        'Sign Up',
        style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 40),
      TextFormField(
        controller: nameController,
        validator: (val) {
            if(val!.trim().isEmpty){
              return 'Please enter your name';
            }
            return null;
          },
        decoration: InputDecoration(
          labelText: 'Account Name',
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 20),
      PasswordField(controller: passwordController, labelText: 'Password'),
      
      const SizedBox(height: 20),
      PasswordField(controller: confirmPasswordController, labelText: 'Confirm Password'),
      const SizedBox(height: 20),
      AuthButton(
                      buttonText: 'Sign up',
                      onTap: () async {
                      },
                    ),
      const SizedBox(height: 20),
                    GestureDetector(
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
                              text: 'log In',
                              style: TextStyle(
                                color: Palette.gradient2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
    )],
  ),),
),

          );
  }
}