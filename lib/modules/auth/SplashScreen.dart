import 'package:flutter/material.dart';
import 'LoginScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // 🔹 Delay for 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            // 🔹 LOGO ICON
            Icon(Icons.store, size: 90, color: Colors.white),

            SizedBox(height: 20),

            // 🔹 APP NAME
            Text(
              "BizAdmin",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),

            SizedBox(height: 10),

            // 🔹 TAGLINE
            Text(
              "Manage your business smartly",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),

            SizedBox(height: 30),

            // 🔹 LOADING INDICATOR
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
