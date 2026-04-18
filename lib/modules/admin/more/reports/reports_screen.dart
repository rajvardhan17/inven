import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../../core/app_theme.dart';

// ─────────────────────────────────────────────────
// Pure-Dart helpers — no intl package needed
// ─────────────────────────────────────────────────

String _fmtRupee(double amount) {
  final n = amount.toInt();
  final s = n.toString();
  if (s.length <= 3) return s;
  final last3 = s.substring(s.length - 3);
  final rest = s.substring(0, s.length - 3);
  final buf = StringBuffer();
  for (int i = 0; i < rest.length; i++) {
    if (i != 0 && (rest.length - i) % 2 == 0) buf.write(',');
    buf.write(rest[i]);
  }
  return '${buf.toString()},$last3';
}

String _fmtDateShort(DateTime d) {
  const months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '${d.day.toString().padLeft(2,'0')} ${months[d.month-1]}, $h:$m';
}

// ─────────────────────────────────────────────────

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'This Month';
  final List<String> _periods = ['Today', 'This Week', 'This Month', 'This Year'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTimeRange _getPeriodRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Today':
        return DateTimeRange(
            start: DateTime(now.year, now.month, now.day), end: now);
      case 'This Week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
            start: DateTime(weekStart.year, weekStart.month, weekStart.day),
            end: now);
      case 'This Year':
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
      default: // This Month
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text(
          'Reports',
          style:
              TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.orange,
          labelColor: AppTheme.orange,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Orders'),
            Tab(text: 'Users'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Period selector
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _periods.map((period) {
                  final selected = period == _selectedPeriod;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPeriod = period),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.orange : AppTheme.bg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? AppTheme.orange : AppTheme.border,
                        ),
                      ),
                      child: Text(
                        period,
                        style: TextStyle(
                          color: selected
                              ? AppTheme.bg
                              : AppTheme.textSecondary,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(range: _getPeriodRange()),
                _OrdersTab(range: _getPeriodRange()),
                _UsersTab(range: _getPeriodRange()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── OVERVIEW TAB ──────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final DateTimeRange range;
  const _OverviewTab({required this.range});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.orange));
        }
        final stats = snapshot.data ?? {};
        final totalOrders = stats['totalOrders'] ?? 0;
        final totalRevenue = (stats['totalRevenue'] ?? 0.0) as double;
        final totalUsers = stats['totalUsers'] ?? 0;
        final totalShops = stats['totalShops'] ?? 0;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _StatCard(
                  title: 'Total Orders',
                  value: '$totalOrders',
                  icon: Icons.shopping_bag,
                  color: AppTheme.blue,
                ),
                _StatCard(
                  title: 'Revenue',
                  value: '₹${_fmtRupee(totalRevenue)}',
                  icon: Icons.currency_rupee,
                  color: AppTheme.green,
                ),
                _StatCard(
                  title: 'Total Users',
                  value: '$totalUsers',
                  icon: Icons.people,
                  color: AppTheme.purple,
                ),
                _StatCard(
                  title: 'Shops',
                  value: '$totalShops',
                  icon: Icons.store,
                  color: AppTheme.orange,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _SectionHeader(title: 'Recent Orders'),
            const SizedBox(height: 12),
            _RecentOrdersList(range: range),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchStats() async {
    final firestore = FirebaseFirestore.instance;

    final ordersQuery = await firestore
        .collection('orders')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
        .get();

    double totalRevenue = 0;
    for (final doc in ordersQuery.docs) {
      final data = doc.data();
      totalRevenue += (data['totalAmount'] ?? 0) is int
          ? (data['totalAmount'] as int).toDouble()
          : (data['totalAmount'] ?? 0.0) as double;
    }

    final usersCount =
        await firestore.collection('users').count().get();
    final shopsCount =
        await firestore.collection('shops').count().get();

    return {
      'totalOrders': ordersQuery.docs.length,
      'totalRevenue': totalRevenue,
      'totalUsers': usersCount.count ?? 0,
      'totalShops': shopsCount.count ?? 0,
    };
  }
}

// ── ORDERS TAB ──────────────────────────────────────────
class _OrdersTab extends StatelessWidget {
  final DateTimeRange range;
  const _OrdersTab({required this.range});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
              child: Text('Error', style: TextStyle(color: AppTheme.red)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.orange));
        }

        final docs = snapshot.data!.docs;
        final statusMap = <String, int>{};
        double total = 0;
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'unknown';
          statusMap[status] = (statusMap[status] ?? 0) + 1;
          final amt = data['totalAmount'];
          total += amt is int ? amt.toDouble() : (amt ?? 0.0) as double;
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionHeader(title: 'Order Summary'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  _summaryRow('Total Orders', '${docs.length}',
                      AppTheme.textPrimary),
                  const Divider(color: AppTheme.border, height: 24),
                  _summaryRow(
                      'Total Revenue', '₹${_fmtRupee(total)}', AppTheme.green),
                  if (statusMap.isNotEmpty) ...[
                    const Divider(color: AppTheme.border, height: 24),
                    ...statusMap.entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _StatusChip(status: e.key),
                              Text('${e.value}',
                                  style: const TextStyle(
                                      color: AppTheme.textPrimary)),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: AppTheme.textSecondary)),
        Text(value,
            style: TextStyle(
                color: valueColor, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ── USERS TAB ──────────────────────────────────────────
class _UsersTab extends StatelessWidget {
  final DateTimeRange range;
  const _UsersTab({required this.range});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.orange));
        }
        final docs = snapshot.data!.docs;
        final roleMap = <String, int>{};
        int activeCount = 0;

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final role = data['role'] ?? 'user';
          roleMap[role] = (roleMap[role] ?? 0) + 1;
          if (data['isActive'] == true) activeCount++;
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionHeader(title: 'User Summary'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  _row('Total Users', '${docs.length}', AppTheme.textPrimary),
                  const Divider(color: AppTheme.border, height: 24),
                  _row('Active', '$activeCount', AppTheme.green),
                  const Divider(color: AppTheme.border, height: 24),
                  ...roleMap.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _row(
                          e.key[0].toUpperCase() + e.key.substring(1),
                          '${e.value}',
                          AppTheme.textPrimary,
                        ),
                      )),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _row(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        Text(value,
            style:
                TextStyle(color: valueColor, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ── REUSABLE WIDGETS ──────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(title,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _RecentOrdersList extends StatelessWidget {
  final DateTimeRange range;
  const _RecentOrdersList({required this.range});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No orders yet',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
          );
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final ts = data['createdAt'] as Timestamp?;
            final date = ts != null ? _fmtDateShort(ts.toDate()) : '';
            final amt = data['totalAmount'];
            final amount =
                amt is int ? amt.toDouble() : (amt ?? 0.0) as double;
            final status = data['status'] ?? 'pending';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['orderNumber'] ??
                              doc.id.substring(0, 8).toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(date,
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${_fmtRupee(amount)}',
                        style: const TextStyle(
                          color: AppTheme.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _StatusChip(status: status),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return AppTheme.green;
      case 'pending':
        return AppTheme.orange;
      case 'cancelled':
        return AppTheme.red;
      case 'processing':
        return AppTheme.blue;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
            color: _color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}