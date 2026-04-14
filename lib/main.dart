import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/session/session_manager.dart';
import 'core/session/session_model.dart';
import 'core/services/token_refresh_service.dart';
import 'data/order_data.dart';
import 'firebase_options.dart';
import 'modules/admin/main_screen.dart';
import 'modules/auth/login_screen.dart';
import 'modules/auth/splash_screen.dart';
import 'modules/distributor/distributor_screen.dart';
import 'modules/salesman/salesman_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SessionManager.instance.init();
  TokenRefreshService.instance.start();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OrderData()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BizAdmin',
      theme: _buildTheme(),
      home: const AuthWrapper(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ─── AuthWrapper ─────────────────────────────────────────────────────────────
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SessionModel?>(
      stream: SessionManager.instance.sessionStream,
      builder: (context, snapshot) {

        // Still waiting for first emit.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final session = snapshot.data;

        if (session == null) {
          return const LoginScreen();
        }

        return _screenForRole(session.role);
      },
    );
  }

  Widget _screenForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const MainScreen();
      case UserRole.salesman:
        return const SalesmanScreen();
      case UserRole.distributor:
        return const DistributorScreen();
      case UserRole.user:
      case UserRole.unknown:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SessionManager.instance.signOut();
        });
        return const LoginScreen();
    }
  }
}