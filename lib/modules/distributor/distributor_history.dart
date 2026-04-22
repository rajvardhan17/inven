import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/app_theme.dart';

class DistributorHistoryScreen extends StatefulWidget {
  final String uid;
  const DistributorHistoryScreen({super.key, required this.uid});

  @override
  State<DistributorHistoryScreen> createState() =>
      _DistributorHistoryScreenState();
}

class _DistributorHistoryScreenState
    extends State<DistributorHistoryScreen>
    with SingleTickerProviderStateMixin {
  final db = FirebaseFirestore.instance;
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ───────────────────────── HELPERS ─────────────────────────

  String _status(dynamic raw) {
    final s = (raw ?? "").toString().toLowerCase().trim();
    if (s.isEmpty) return "pending";
    if (s == "assigned") return "assigned";
    if (s == "packed") return "packed";
    if (s == "delivered") return "delivered";
    if (s == "failed") return "failed";
    if (s == "cancelled") return "failed";
    return s;
  }

  double _safeDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  List<Map<String, dynamic>> _parseItems(dynamic raw) {
    if (raw == null) return [];

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    if (raw is Map) {
      return raw.values
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return [];
  }

  // ───────────────────────── UI ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text("History"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              Container(height: 1, color: AppTheme.border),
              TabBar(
                controller: _tab,
                labelColor: AppTheme.green,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.green,
                tabs: const [
                  Tab(text: "DELIVERIES"),
                  Tab(text: "PAYMENTS")
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _deliveriesTab(),
          _paymentsTab(),
        ],
      ),
    );
  }

  // ───────────────── DELIVERIES TAB ─────────────────

  Widget _deliveriesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('orders')
          .where('assignedDistributorId', isEqualTo: widget.uid)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snap.data!.docs.where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final st = _status(d["deliveryStatus"] ?? d["status"]);
          return st == "delivered";
        }).toList();

        if (docs.isEmpty) {
          return const Center(child: Text("No Deliveries Yet"));
        }

        double totalCollected = 0;
        int count = docs.length;

        for (var d in docs) {
          final data = d.data() as Map<String, dynamic>;
          totalCollected += _safeDouble(data['totalAmount']);
        }

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // SUMMARY
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(child: Text("Delivered: $count")),
                  Expanded(child: Text("₹${totalCollected.toInt()}")),
                ],
              ),
            ),

            ...docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final items = _parseItems(d['items']);
              final total = _safeDouble(d['totalAmount']);

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(d['shopName'] ?? ''),
                  subtitle: Text("${items.length} items"),
                  trailing: Text("₹${total.toInt()}"),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // ───────────────── PAYMENTS TAB ─────────────────

  Widget _paymentsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('orders')
          .where('assignedDistributorId', isEqualTo: widget.uid)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snap.data!.docs.where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          return (d["paymentStatus"] ?? "") == "paid";
        }).toList();

        if (docs.isEmpty) {
          return const Center(child: Text("No Payments Yet"));
        }

        double total = 0;

        for (var d in docs) {
          final data = d.data() as Map<String, dynamic>;
          total += _safeDouble(
              data['collectedAmount'] ?? data['totalAmount']);
        }

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // TOTAL BANNER
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Total ₹${total.toInt()}",
                style: const TextStyle(color: Colors.white),
              ),
            ),

            ...docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final amt = _safeDouble(
                  d['collectedAmount'] ?? d['totalAmount']);

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(d['shopName'] ?? ''),
                  subtitle: Text(d['paymentMethod'] ?? 'cash'),
                  trailing: Text("₹${amt.toInt()}"),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}