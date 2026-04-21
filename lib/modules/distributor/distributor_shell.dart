import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'distributor_screen.dart';
import 'distributor_orders.dart';
import 'distributor_history.dart';
import 'distributor_profile.dart';
import '../../../core/app_theme.dart';

class DistributorShell extends StatefulWidget {
  const DistributorShell({super.key});

  @override
  State<DistributorShell> createState() => _DistributorShellState();
}

class _DistributorShellState extends State<DistributorShell> {
  int _index = 0;

  late String uid;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    uid = user?.uid ?? '';

    _pages = [
      DistributorDashboard(uid: uid),
      DistributorOrdersScreen(uid: uid),
      DistributorHistoryScreen(uid: uid),
      DistributorProfileScreen(uid: uid),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: _buildSalesmanStyleNav(),
    );
  }

  // ─────────────────────────────────────────────
  // SALES-MAN STYLE BOTTOM NAV (SAFE + RESPONSIVE)
  Widget _buildSalesmanStyleNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: AppTheme.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, -3),
          )
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            children: [
              _navItem(0, Icons.dashboard_outlined, Icons.dashboard_rounded, "Dash"),
              _navItem(1, Icons.local_shipping_outlined, Icons.local_shipping_rounded, "Orders"),
              _navItem(2, Icons.history_outlined, Icons.history_rounded, "History"),
              _navItem(3, Icons.person_outline, Icons.person, "Profile"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int i, IconData icon, IconData activeIcon, String label) {
    final selected = _index == i;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _index = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.greenSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? activeIcon : icon,
                color: selected ? AppTheme.green : AppTheme.textSecondary,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppTheme.green
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}