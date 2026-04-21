import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/session/session_manager.dart';
import 'core/session/session_model.dart';
import 'core/services/token_refresh_service.dart';
import 'core/theme_provider.dart';
import 'data/order_data.dart';
import 'firebase_options.dart';

// ── Screens ───────────────────────────────────────────────
import 'modules/admin/main_screen.dart';
import 'modules/auth/login_screen.dart';
import 'modules/auth/splash_screen.dart';
import 'modules/salesman/salesman_shell.dart';
import 'modules/distributor/distributor_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SessionManager.instance.init();
  TokenRefreshService.instance.start();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OrderData()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// ══════════════════════════════════════════════════════════
//  ROOT APP
// ══════════════════════════════════════════════════════════
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (_, themeProvider, __) {
        // Always use dark — our design system is dark-first.
        // ThemeProvider toggle still respected if needed later.
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'BizAdmin',
          themeMode: ThemeMode.dark,
          theme: _buildTheme(isDark: false),
          darkTheme: _buildTheme(isDark: true),
          home: const AuthWrapper(),
        );
      },
    );
  }

  // ── Shared ThemeData (wraps AppTheme constants) ──────────
  ThemeData _buildTheme({required bool isDark}) {
    // Design tokens (mirrors app_theme.dart)
    const bg       = Color(0xFF0D0F14);
    const surface  = Color(0xFF161A23);
    const surface2 = Color(0xFF1E2330);
    const border   = Color(0xFF262C3A);
    const accent   = Color(0xFFE8B84B);
    const textPri  = Color(0xFFF0F2F7);
    const textSec  = Color(0xFF7A8299);

    final base = isDark ? ThemeData.dark() : ThemeData.light();

    return base.copyWith(
      useMaterial3: true,

      scaffoldBackgroundColor: isDark ? bg : const Color(0xFFF4F6FB),

      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: isDark ? Brightness.dark : Brightness.light,
        surface: isDark ? surface : Colors.white,
        background: isDark ? bg : const Color(0xFFF4F6FB),
        primary: accent,
        onPrimary: bg,
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: isDark ? surface : Colors.white,
        foregroundColor: isDark ? textPri : Colors.black87,
        titleTextStyle: TextStyle(
          color: isDark ? textPri : Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(
          color: isDark ? textPri : Colors.black87,
        ),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? surface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: isDark ? border : Colors.grey.shade200),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? surface2 : Colors.grey.shade100,
        labelStyle: TextStyle(
          color: isDark ? textSec : Colors.grey.shade600,
          fontSize: 13,
        ),
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF3D4459) : Colors.grey.shade400,
          fontSize: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: isDark ? border : Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: isDark ? border : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: accent,
          foregroundColor: bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.3),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: const BorderSide(color: accent),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: bg,
        elevation: 8,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: accent,
        unselectedLabelColor: textSec,
        indicatorColor: accent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        dividerColor: border,
      ),

      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: isDark ? surface2 : Colors.grey.shade100,
        selectedColor: const Color(0x33E8B84B),
        labelStyle: TextStyle(color: isDark ? textPri : Colors.black87, fontSize: 13),
        side: BorderSide(color: isDark ? border : Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? surface : Colors.white,
        modalBackgroundColor: isDark ? surface : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? surface : Colors.white,
        elevation: 24,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(
          color: isDark ? textPri : Colors.black87,
          fontSize: 18, fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(
          color: isDark ? textSec : Colors.grey.shade700,
          fontSize: 14,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? surface2 : Colors.black87,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 8,
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: MaterialStatePropertyAll(isDark ? surface2 : Colors.white),
          elevation: const MaterialStatePropertyAll(8),
          shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return accent;
          return isDark ? textSec : Colors.grey.shade400;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0x33E8B84B);
          }
          return isDark ? border : Colors.grey.shade200;
        }),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: border,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: textSec,
        titleTextStyle: TextStyle(color: isDark ? textPri : Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
        subtitleTextStyle: TextStyle(color: textSec, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  AUTH WRAPPER  — session-based role routing
// ══════════════════════════════════════════════════════════
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SessionModel?>(
      stream: SessionManager.instance.sessionStream,
      builder: (context, snapshot) {
        // ── Loading ──────────────────────────────────────
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final session = snapshot.data;

        // ── Unauthenticated ──────────────────────────────
        if (session == null) {
          return const LoginScreen();
        }

        // ── Role routing ─────────────────────────────────
        return _screenForRole(session.role);
      },
    );
  }

  Widget _screenForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const MainScreen();

      case UserRole.salesman:
        return const SalesmanShell();

      case UserRole.distributor:
        return const DistributorShell();

      case UserRole.user:
      case UserRole.unknown:
        // Sign out unauthorised roles after the frame renders
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SessionManager.instance.signOut();
        });
        return const LoginScreen();
    }
  }
}