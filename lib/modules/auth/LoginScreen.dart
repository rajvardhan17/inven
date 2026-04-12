import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'RegisterScreen.dart';
import 'SplashScreen.dart'; // 🔥 IMPORTANT
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    // 🔍 Validation
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 🔐 Firebase Login
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      String uid = userCredential.user!.uid;

      // 📦 Fetch user data
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!mounted) return;

      if (!userDoc.exists) {
        throw "User data not found";
      }

      var data = userDoc.data() as Map<String, dynamic>;

      // 🚫 Block inactive users
      if (data['isActive'] == false) {
        throw "Account disabled. Contact admin.";
      }

      // ✅ SUCCESS → Go to Splash (Router)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SplashScreen()),
      );

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = "Login failed";

      switch (e.code) {
        case 'user-not-found':
          message = "No user found";
          break;
        case 'wrong-password':
          message = "Incorrect password";
          break;
        case 'invalid-email':
          message = "Invalid email";
          break;
        case 'too-many-requests':
          message = "Too many attempts. Try later.";
          break;
        default:
          message = e.message ?? "Login error";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
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

              // 🔹 TITLE
              Column(
                children: const [
                  Icon(Icons.store, size: 60, color: Colors.deepPurple),
                  SizedBox(height: 10),
                  Text(
                    "BizAdmin",
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Login to continue",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // 🔹 EMAIL
              CustomTextField(
                controller: emailController,
                hintText: "Email",
                prefixIcon: Icons.email,
              ),

              const SizedBox(height: 15),

              // 🔹 PASSWORD
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

              // 🔹 REGISTER
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