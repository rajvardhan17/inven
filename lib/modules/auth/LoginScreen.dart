import 'package:flutter/material.dart';
import '../admin/MainScreen.dart';
import 'Register.dart';
import '../core/widgets/custom_button.dart';
import '../core/widgets/custom_textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  void login() {
    setState(() => isLoading = true);

    // Fake delay (simulate API)
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔹 APP TITLE
              Column(
                children: const [
                  Icon(Icons.store, size: 60, color: Colors.deepPurple),
                  SizedBox(height: 10),
                  Text(
                    "BizAdmin",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Login to continue",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // 🔹 EMAIL FIELD
              CustomTextField(
                controller: emailController,
                hintText: "Email",
                prefixIcon: Icons.email,
              ),

              const SizedBox(height: 15),

              // 🔹 PASSWORD FIELD
              CustomTextField(
                controller: passwordController,
                hintText: "Password",
                prefixIcon: Icons.lock,
                obscureText: true,
              ),

              const SizedBox(height: 25),

              // 🔹 LOGIN BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: CustomButton(
                  text: "Login",
                  isLoading: isLoading,
                  onPressed: login,
                ),
              ),

              const SizedBox(height: 15),

              // 🔹 REGISTER TEXT
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Register",
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
