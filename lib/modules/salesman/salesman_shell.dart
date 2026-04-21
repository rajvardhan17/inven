import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'salesman_dashboard.dart';
import 'salesman_shops.dart';
import 'salesman_orders.dart';
import 'salesman_profile.dart';
import '../../../core/app_theme.dart';

class SalesmanShell extends StatefulWidget {
  const SalesmanShell({super.key});

  @override
  State<SalesmanShell> createState() => _SalesmanShellState();
}

class _SalesmanShellState extends State<SalesmanShell> {
  int _index = 0;

  final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      SalesmanDashboard(uid: uid),
      SalesmanShopsScreen(uid: uid),
      SalesmanOrdersScreen(uid: uid),
      SalesmanProfileScreen(uid: uid),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() {
    final items = [
      _NavItem(Icons.grid_view_rounded, Icons.grid_view_rounded, 'Dashboard'),
      _NavItem(Icons.storefront_outlined, Icons.storefront_rounded, 'Shops'),
      _NavItem(Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Orders'),
      _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: AppTheme.border)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final sel = _index == i;
              return GestureDetector(
                onTap: () => setState(() => _index = i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? AppTheme.accentSoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        sel ? items[i].activeIcon : items[i].icon,
                        color: sel ? AppTheme.accent : AppTheme.textSecondary,
                        size: 22,
                      ),
                      if (sel) ...[
                        const SizedBox(width: 8),
                        Text(items[i].label, style: const TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        )),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon, activeIcon;
  final String label;
  _NavItem(this.icon, this.activeIcon, this.label);
}