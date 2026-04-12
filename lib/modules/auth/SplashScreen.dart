import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/LoginScreen.dart';
import '../admin/MainScreen.dart';
import '../salesman/SalesmanScreen.dart';
import '../distributor/DistributorScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    checkUser();
  }

  void checkUser() async {
    await Future.delayed(const Duration(seconds: 2));

    User? user = FirebaseAuth.instance.currentUser;

    // ❌ Not logged in
    if (user == null) {
      goTo(const LoginScreen());
      return;
    }

    try {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) throw "User not found";

      var data = doc.data() as Map<String, dynamic>;

      if (data['isActive'] == false) {
        throw "Account disabled";
      }

      String role = data['role']
        .toString()
        .trim()
        .toLowerCase();

      // 🔥 ROLE-BASED NAVIGATION
      // 🔥 ROLE-BASED NAVIGATION
      if (role == 'admin') {
        goTo(const MainScreen());
      } else if (role == 'salesman') {
        goTo(SalesmanScreen());
      } else if (role == 'distributor') {
        goTo(DistributorScreen());
      } else {
        print("INVALID ROLE → $role");
        goTo(const LoginScreen());
      }


    } catch (e) {
      goTo(const LoginScreen());
    }
  }

  void goTo(Widget screen) {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.store, size: 90, color: Colors.white),
            SizedBox(height: 20),
            Text(
              "BizAdmin",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Manage your business smartly",
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}