import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/session/session_manager.dart';
import 'core/session/session_model.dart';
import 'core/services/token_refresh_service.dart';
import 'core/theme_provider.dart'; // ✅ ADDED
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
        ChangeNotifierProvider(create: (_) => ThemeProvider()), // ✅ ADDED
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>( // ✅ WRAPPED
      builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'BizAdmin',

          // ✅ DARK MODE SUPPORT
          themeMode:
              themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,

          theme: _buildTheme(isDark: false),
          darkTheme: _buildTheme(isDark: true),

          home: const AuthWrapper(),
        );
      },
    );
  }

  // 🔥 UI UPGRADE (ENTERPRISE LOOK)
  ThemeData _buildTheme({required bool isDark}) {
    final base = isDark ? ThemeData.dark() : ThemeData.light();

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),

      useMaterial3: true,

      scaffoldBackgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F6FB),

      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? Colors.grey.shade900 : Colors.black87,
        contentTextStyle: const TextStyle(color: Colors.white),
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor:
            isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor:
            isDark ? Colors.white : Colors.black,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SessionModel?>(
      stream: SessionManager.instance.sessionStream,
      builder: (context, snapshot) {
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