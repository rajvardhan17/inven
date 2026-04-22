import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/app_theme.dart';

class DistributorDashboard extends StatefulWidget {
  final String uid;
  const DistributorDashboard({super.key, required this.uid});

  @override
  State<DistributorDashboard> createState() => _DistributorDashboardState();
}

class _DistributorDashboardState extends State<DistributorDashboard>
    with SingleTickerProviderStateMixin {
  final db = FirebaseFirestore.instance;
  late AnimationController _fade;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _anim = CurvedAnimation(parent: _fade, curve: Curves.easeOut);
    _fade.forward();
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  String _normalizeStatus(String raw) {
    final s = raw.toLowerCase().trim();
    if (s.isEmpty) return 'pending';
    if (s == 'assigned') return 'assigned';
    if (s == 'packed') return 'packed';
    if (s == 'delivered') return 'delivered';
    if (s == 'failed') return 'failed';
    if (s == 'cancelled') return 'failed';
    return s;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _anim,
          child: RefreshIndicator(
            color: AppTheme.green,
            backgroundColor: AppTheme.surface,
            onRefresh: () async {
              setState(() {});
              _fade.forward(from: 0);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _header()),
                SliverToBoxAdapter(child: _kpiGrid()),
                SliverToBoxAdapter(child: _pendingBanner()),
                SliverToBoxAdapter(child: _recentDeliveries()),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  Widget _header() {
    return StreamBuilder<DocumentSnapshot>(
      stream: db.collection('users').doc(widget.uid).snapshots(),
      builder: (_, snap) {
        final data = snap.data?.data() as Map<String, dynamic>? ?? {};
        final name = data['name'] ?? 'Distributor';

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D1F18), Color(0xFF122A1F)],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.green.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("ON ROUTE",
                        style: TextStyle(color: AppTheme.green, fontSize: 10)),
                    const SizedBox(height: 8),
                    Text(name,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              CircleAvatar(
                backgroundColor: AppTheme.green,
                child: Text(name[0].toUpperCase()),
              )
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  Widget _kpiGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('orders')
          .where('distributorId', isEqualTo: widget.uid) // ✅ FIXED
          .snapshots(),
      builder: (_, snap) {
        int total = 0;
        int pending = 0;
        int delivered = 0;
        int failed = 0;
        double collected = 0;

        final docs = snap.data?.docs ?? [];

        for (var doc in docs) {
          final d = doc.data() as Map<String, dynamic>;

          final status = _normalizeStatus(
              d['status'] ?? d['deliveryStatus'] ?? '');
          final payment =
              (d['paymentStatus'] ?? '').toString().toLowerCase();

          total++;

          if (status == 'delivered') {
            delivered++;
          } else if (status == 'failed') {
            failed++;
          } else {
            pending++;
          }

          if (payment == 'paid') {
            collected += _toDouble(d['totalAmount']);
          }
        }

        final kpis = [
          _KD("Assigned", "$total", Icons.assignment, AppTheme.blue, AppTheme.blueSoft),
          _KD("Pending", "$pending", Icons.hourglass_top, AppTheme.orange, AppTheme.orangeSoft),
          _KD("Delivered", "$delivered", Icons.check_circle, AppTheme.green, AppTheme.greenSoft),
          _KD("Collected", "₹${collected.toInt()}", Icons.currency_rupee, AppTheme.accent, AppTheme.accentSoft),
        ];

        return Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            children: kpis.map((k) => _kpiCard(k)).toList(),
          ),
        );
      },
    );
  }

  Widget _kpiCard(_KD k) {
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(k.icon, color: k.color),
          const Spacer(),
          Text(k.value,
              style: TextStyle(
                  color: k.color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          Text(k.label),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  Widget _pendingBanner() {
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('orders')
          .where('distributorId', isEqualTo: widget.uid) // ✅ FIXED
          .snapshots(),
      builder: (_, snap) {
        final hasPending = (snap.data?.docs ?? []).any((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final status = _normalizeStatus(d['status'] ?? '');
          return status != 'delivered' && status != 'failed';
        });

        if (!hasPending) return const SizedBox();

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          color: AppTheme.orangeSoft,
          child: const Text("Pending Deliveries"),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  Widget _recentDeliveries() {
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('orders')
          .where('distributorId', isEqualTo: widget.uid) // ✅ FIXED
          .snapshots(),
      builder: (_, snap) {
        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text("No deliveries yet"),
          );
        }

        final sorted = docs..sort((a, b) {
          final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          return bTime.compareTo(aTime);
        });

        return Column(
          children: sorted.take(5).map((doc) {
            final d = doc.data() as Map<String, dynamic>;

            return ListTile(
              title: Text(d['shopName'] ?? ''),
              subtitle: Text("₹${d['totalAmount'] ?? 0}"),
            );
          }).toList(),
        );
      },
    );
  }
}

class _KD {
  final String label, value;
  final IconData icon;
  final Color color, bg;

  _KD(this.label, this.value, this.icon, this.color, this.bg);
}