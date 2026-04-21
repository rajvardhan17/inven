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
  // SAFE STATUS NORMALIZER
  String _normalizeStatus(String raw) {
    final s = raw.toLowerCase().trim();
    if (s.isEmpty) return 'pending';
    if (s == 'assigned') return 'assigned';
    if (s == 'packed') return 'packed';
    if (s == 'delivered') return 'delivered';
    if (s == 'failed') return 'failed';
    return s;
  }

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
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
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
                        style: TextStyle(
                            color: AppTheme.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(name,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const Text("DISTRIBUTOR",
                        style: TextStyle(
                            color: AppTheme.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 26,
                backgroundColor: AppTheme.green,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'D',
                  style: const TextStyle(color: Colors.white),
                ),
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
          .where('assignedDistributorId', isEqualTo: widget.uid)
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

          final status = _normalizeStatus(d['status'] ?? d['deliveryStatus'] ?? '');
          final payment = (d['paymentStatus'] ?? '').toString().toLowerCase();

          total++;

          if (status == 'delivered') {
            delivered++;
          } else if (status == 'failed') {
            failed++;
          } else {
            pending++;
          }

          if (payment == 'paid') {
            final amt = d['totalAmount'];
            if (amt != null) {
              collected += (amt as num).toDouble();
            }
          }
        }

        final kpis = [
          _KD("Assigned", "$total", Icons.assignment_outlined,
              AppTheme.blue, AppTheme.blueSoft),
          _KD("Pending", "$pending", Icons.hourglass_top_rounded,
              AppTheme.orange, AppTheme.orangeSoft),
          _KD("Delivered", "$delivered", Icons.check_circle_outline,
              AppTheme.green, AppTheme.greenSoft),
          _KD("Collected", "₹${collected.toInt()}",
              Icons.currency_rupee, AppTheme.accent, AppTheme.accentSoft),
        ];

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: kpis.map((k) => _kpiCard(k)).toList(),
          ),
        );
      },
    );
  }

  Widget _kpiCard(_KD k) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
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
                  fontWeight: FontWeight.w800)),
          Text(k.label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  Widget _pendingBanner() {
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('orders')
          .where('assignedDistributorId', isEqualTo: widget.uid)
          .snapshots(),
      builder: (_, snap) {
        final hasPending = (snap.data?.docs ?? []).any((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final status = _normalizeStatus(d['status'] ?? '');
          return status == 'pending' || status == 'assigned' || status == 'packed';
        });

        if (!hasPending) return const SizedBox();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.orangeSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.local_shipping_outlined, color: AppTheme.orange),
              SizedBox(width: 10),
              Expanded(child: Text("Pending Deliveries")),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  Widget _recentDeliveries() {
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('orders')
          .where('assignedDistributorId', isEqualTo: widget.uid)
          .snapshots(),
      builder: (_, snap) {
        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text("No deliveries yet"),
          );
        }

        return Column(
          children: docs.take(5).map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final status =
                _normalizeStatus(d['status'] ?? d['deliveryStatus'] ?? '');

            return ListTile(
              title: Text(d['shopName'] ?? ''),
              subtitle: Text("₹${d['totalAmount'] ?? 0}"),
              trailing: Text(status),
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