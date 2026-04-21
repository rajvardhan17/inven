import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/app_theme.dart';

class DistributorOrdersScreen extends StatefulWidget {
  final String uid;
  const DistributorOrdersScreen({super.key, required this.uid});

  @override
  State<DistributorOrdersScreen> createState() =>
      _DistributorOrdersScreenState();
}

class _DistributorOrdersScreenState extends State<DistributorOrdersScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  late TabController _tab;
  String _filter = "active";

  @override
  void initState() {
    super.initState();

    _tab = TabController(length: 3, vsync: this);

    _tab.addListener(() {
      if (_tab.indexIsChanging) return;

      setState(() {
        if (_tab.index == 0) _filter = "active";
        if (_tab.index == 1) _filter = "delivered";
        if (_tab.index == 2) _filter = "failed";
      });
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ───────────────────────── SAFE HELPERS ─────────────────────────

  String _status(dynamic raw) {
    final s = (raw ?? "").toString().toLowerCase().trim();
    if (s.isEmpty) return "pending";
    if (s == "packed") return "packed";
    if (s == "assigned") return "assigned";
    if (s == "delivered") return "delivered";
    if (s == "failed") return "failed";
    return s;
  }

  double _safeDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  List<Map<String, dynamic>> _parseItems(dynamic raw) {
    try {
      if (raw == null) return [];

      if (raw is List) {
        return raw.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      if (raw is Map) {
        return raw.values.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  // ───────────────────────── MAIN UI ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text("My Deliveries"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Column(
            children: [
              Container(height: 1, color: AppTheme.border),
              TabBar(
                controller: _tab,
                labelColor: AppTheme.green,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.green,
                tabs: const [
                  Tab(text: "ACTIVE"),
                  Tab(text: "DELIVERED"),
                  Tab(text: "FAILED"),
                ],
              ),
            ],
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: db
            .collection("orders")
            .where("assignedDistributorId", isEqualTo: widget.uid)
            .snapshots(),

        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(child: Text("Error: ${snap.error}"));
          }

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // ✅ FIXED: correct sorting (THIS WAS YOUR BUG)
          final docs = snap.data!.docs.toList()
            ..sort((a, b) {
              final aTime = (a["createdAt"] as Timestamp?)?.toDate() ??
                  DateTime.now();
              final bTime = (b["createdAt"] as Timestamp?)?.toDate() ??
                  DateTime.now();
              return bTime.compareTo(aTime);
            });

          final filtered = docs.where((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final st = _status(d["deliveryStatus"] ?? d["status"]);

            if (_filter == "active") return st != "delivered" && st != "failed";
            if (_filter == "delivered") return st == "delivered";
            if (_filter == "failed") return st == "failed";

            return true;
          }).toList();

          if (filtered.isEmpty) {
            return const Center(child: Text("No Orders Found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final d = filtered[i].data() as Map<String, dynamic>;
              return _orderCard(filtered[i].id, d);
            },
          );
        },
      ),
    );
  }

  // ───────────────────────── ORDER CARD ─────────────────────────

  Widget _orderCard(String id, Map<String, dynamic> d) {
    final st = _status(d["deliveryStatus"] ?? d["status"]);
    final items = _parseItems(d["items"]);
    final total = _safeDouble(d["totalAmount"]);
    final isActive = st != "delivered" && st != "failed";

    return GestureDetector(
      onTap: () => _showOrderDetails(d),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.store),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      d["shopName"] ?? "Shop",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(st),
                ],
              ),

              const SizedBox(height: 10),

              Text("Items: ${items.length}"),
              Text("Total: ₹$total"),

              const SizedBox(height: 10),

              if (isActive)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _markDelivered(id),
                        child: const Text("Delivered"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _collectPayment(id),
                        child: const Text("Collect"),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── DETAILS ─────────────────────────

  void _showOrderDetails(Map<String, dynamic> d) async {
    final shopId = d["shopId"];
    Map<String, dynamic>? shop;

    if (shopId != null) {
      final snap = await db.collection("shops").doc(shopId).get();
      shop = snap.data();
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d["shopName"] ?? "",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),

              const SizedBox(height: 10),

              Text("📍 ${shop?["address"] ?? "N/A"}"),
              Text("📞 ${shop?["phone"] ?? "N/A"}"),
              Text("👤 ${shop?["ownerName"] ?? "N/A"}"),

              const Divider(),

              const Text("Items:",
                  style: TextStyle(fontWeight: FontWeight.bold)),

              const SizedBox(height: 10),

              ..._parseItems(d["items"]).map((i) => Text(
                  "${i["productName"]} × ${i["qty"]} - ₹${i["total"]}")),
            ],
          ),
        );
      },
    );
  }

  // ───────────────────────── ACTIONS ─────────────────────────

  Future<void> _markDelivered(String id) async {
    await db.collection("orders").doc(id).update({
      "deliveryStatus": "delivered",
      "deliveredAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> _collectPayment(String id) async {
    await db.collection("orders").doc(id).update({
      "paymentStatus": "paid",
      "collectedAt": FieldValue.serverTimestamp(),
    });
  }
}