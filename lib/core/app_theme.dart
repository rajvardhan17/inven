import 'package:flutter/material.dart';

// ============================================================
//  APP THEME — Shared Design System
// ============================================================

class AppTheme {
  // ── Palette ────────────────────────────────────────────────
  static const Color bg        = Color(0xFF0D0F14);   // near-black
  static const Color surface   = Color(0xFF161A23);   // card surface
  static const Color surface2  = Color(0xFF1E2330);   // elevated surface
  static const Color border    = Color(0xFF262C3A);   // subtle border
  static const Color accent    = Color(0xFFE8B84B);   // gold accent
  static const Color accentSoft= Color(0x33E8B84B);   // 20% gold
  static const Color green     = Color(0xFF2ECC8A);
  static const Color greenSoft = Color(0x332ECC8A);
  static const Color red       = Color(0xFFE85555);
  static const Color redSoft   = Color(0x33E85555);
  static const Color orange    = Color(0xFFE8944B);
  static const Color orangeSoft= Color(0x33E8944B);
  static const Color blue      = Color(0xFF4B9EE8);
  static const Color blueSoft  = Color(0x334B9EE8);
  static const Color purple    = Color(0xFF9B6BE8);
  static const Color purpleSoft= Color(0x339B6BE8);

  static const Color textPrimary   = Color(0xFFF0F2F7);
  static const Color textSecondary = Color(0xFF7A8299);
  static const Color textMuted     = Color(0xFF3D4459);

  // ── Typography ─────────────────────────────────────────────
  static const String fontDisplay = 'Sora';
  static const String fontBody    = 'DM Sans';

  // ── Gradients ──────────────────────────────────────────────
  static const LinearGradient accentGrad = LinearGradient(
    colors: [Color(0xFFE8B84B), Color(0xFFD4A033)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGrad = LinearGradient(
    colors: [Color(0xFF2ECC8A), Color(0xFF1A9E68)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGrad = LinearGradient(
    colors: [Color(0xFF0D0F14), Color(0xFF111520)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Shadows ────────────────────────────────────────────────
  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
  ];

  static List<BoxShadow> accentShadow = [
    BoxShadow(color: accent.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
  ];

  // ── Border radius ──────────────────────────────────────────
  static const double radiusLg = 20;
  static const double radiusMd = 14;
  static const double radiusSm = 10;

  // ── ThemeData ──────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      surface: surface,
      background: bg,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: Color(0xFF0D0F14),
      elevation: 8,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: const Color(0xFF0D0F14),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.3),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: accent),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface2,
      labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
      hintStyle: const TextStyle(color: textMuted, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: const BorderSide(color: accent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 1),
    chipTheme: ChipThemeData(
      backgroundColor: surface2,
      selectedColor: accentSoft,
      labelStyle: const TextStyle(color: textPrimary, fontSize: 13),
      side: const BorderSide(color: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}

// ============================================================
//  SHARED WIDGETS
// ============================================================

/// Consistent page scaffold with gradient background
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? fab;
  final List<Widget>? actions;
  final PreferredSizeWidget? appBar;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.fab,
    this.actions,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      extendBodyBehindAppBar: false,
      appBar: appBar ?? AppBar(
        title: Text(title),
        actions: actions,
        backgroundColor: AppTheme.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      floatingActionButton: fab,
      body: body,
    );
  }
}

/// Card container with consistent dark style
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.border),
          boxShadow: shadow ?? AppTheme.cardShadow,
        ),
        child: child,
      ),
    );
  }
}

/// Status badge
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  factory StatusBadge.fromStatus(String status) {
    Color c;
    switch (status.toLowerCase()) {
      case 'delivered': c = AppTheme.green; break;
      case 'packed':    c = AppTheme.purple; break;
      case 'pending':   c = AppTheme.orange; break;
      case 'paid':      c = AppTheme.green; break;
      case 'unpaid':    c = AppTheme.orange; break;
      default:          c = AppTheme.red;
    }
    return StatusBadge(label: status.toUpperCase(), color: c);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8),
      ),
    );
  }
}

/// Section header
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                )),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Gold accent divider
class AccentDivider extends StatelessWidget {
  const AccentDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, AppTheme.border, Colors.transparent],
        ),
      ),
    );
  }
}

/// Loading state
class AppLoader extends StatelessWidget {
  const AppLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppTheme.accent,
        strokeWidth: 2,
      ),
    );
  }
}

/// Empty state
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const AppEmptyState({super.key, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface2,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border),
            ),
            child: Icon(icon, color: AppTheme.textMuted, size: 36),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}