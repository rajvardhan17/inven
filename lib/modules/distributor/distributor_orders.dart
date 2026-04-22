import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/app_theme.dart';

// ───────────────── STATUS SYSTEM ─────────────────

enum OrderStatus {
  pending,
  packed,
  assigned,
  outForDelivery,
  delivered,
  failed,
  cancelled,
}

extension OrderStatusX on OrderStatus {
  String get key {
    switch (this) {
      case OrderStatus.pending: return 'pending';
      case OrderStatus.packed: return 'packed';
      case OrderStatus.assigned: return 'assigned';
      case OrderStatus.outForDelivery: return 'out_for_delivery';
      case OrderStatus.delivered: return 'delivered';
      case OrderStatus.failed: return 'failed';
      case OrderStatus.cancelled: return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.pending: return 'Pending';
      case OrderStatus.packed: return 'Packed';
      case OrderStatus.assigned: return 'Assigned';
      case OrderStatus.outForDelivery: return 'Out for Delivery';
      case OrderStatus.delivered: return 'Delivered';
      case OrderStatus.failed: return 'Failed';
      case OrderStatus.cancelled: return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending: return Colors.orange;
      case OrderStatus.packed: return Colors.purple;
      case OrderStatus.assigned: return Colors.blue;
      case OrderStatus.outForDelivery: return Colors.deepPurple;
      case OrderStatus.delivered: return Colors.green;
      case OrderStatus.failed: return Colors.red;
      case OrderStatus.cancelled: return Colors.grey;
    }
  }

  bool get isTerminal =>
      this == OrderStatus.delivered ||
      this == OrderStatus.failed ||
      this == OrderStatus.cancelled;

  static OrderStatus fromKey(String? key) {
    switch (key?.toLowerCase().trim()) {
      case 'packed': return OrderStatus.packed;
      case 'assigned': return OrderStatus.assigned;
      case 'out_for_delivery': return OrderStatus.outForDelivery;
      case 'delivered': return OrderStatus.delivered;
      case 'failed': return OrderStatus.failed;
      case 'cancelled': return OrderStatus.cancelled;
      default: return OrderStatus.pending;
    }
  }
}

// ───────────────── SCREEN ─────────────────

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

  // ───────────────── HELPERS ─────────────────

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  List<Map<String, dynamic>> _parseItems(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (raw is Map) {
      return raw.values.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  // ───────────────── BUILD ─────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text("My Deliveries"),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: "ACTIVE"),
            Tab(text: "DELIVERED"),
            Tab(text: "FAILED"),
          ],
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: db
            .collection("orders")
            .where("distributorId", isEqualTo: widget.uid)
            .snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs.toList()
            ..sort((a, b) {
              final aTime = (a["createdAt"] as Timestamp?)?.toDate() ?? DateTime.now();
              final bTime = (b["createdAt"] as Timestamp?)?.toDate() ?? DateTime.now();
              return bTime.compareTo(aTime);
            });

          final filtered = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = OrderStatusX.fromKey(data["status"]);

            if (_filter == "active") return !status.isTerminal;
            if (_filter == "delivered") return status == OrderStatus.delivered;
            if (_filter == "failed") return status == OrderStatus.failed;

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

  // ───────────────── ORDER CARD ─────────────────

  Widget _orderCard(String id, Map<String, dynamic> d) {
    final status = OrderStatusX.fromKey(d["status"]);
    final items = _parseItems(d["items"]);
    final total = _toDouble(d["totalAmount"]);

    return GestureDetector(
      onTap: () => _openOrderDetails(id, d),
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
                  Text(
                    status.label.toUpperCase(),
                    style: TextStyle(
                      color: status.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text("Items: ${items.length}"),
              Text("Total: ₹$total"),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────── DETAILS ─────────────────

  void _openOrderDetails(String id, Map<String, dynamic> d) async {
    final shopId = d["shopId"];
    Map<String, dynamic>? shop;

    if (shopId != null) {
      final snap = await db.collection("shops").doc(shopId).get();
      if (snap.exists) shop = snap.data();
    }

    if (!mounted) return;

    final items = _parseItems(d["items"]);
    final total = _toDouble(d["totalAmount"]);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            shrinkWrap: true,
            children: [

              Text(d["shopName"] ?? "Shop",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

              const SizedBox(height: 10),

              Text("📍 ${shop?["address"] ?? "N/A"}"),
              Text("📞 ${shop?["phone"] ?? "N/A"}"),
              Text("👤 ${shop?["ownerName"] ?? "N/A"}"),

              const Divider(),

              const Text("Items", style: TextStyle(fontWeight: FontWeight.bold)),

              ...items.map((i) => ListTile(
                title: Text(i["productName"] ?? "Item"),
                subtitle: Text("Qty: ${i["qty"]}"),
                trailing: Text("₹${i["price"]}"),
              )),

              const Divider(),

              Text("Total: ₹$total",
                  style: const TextStyle(fontWeight: FontWeight.bold)),

              const SizedBox(height: 20),

              // PAY NOW
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showPaymentOptions(id, total);
                },
                child: const Text("Pay Now"),
              ),

              const SizedBox(height: 10),

              // PAY LATER
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () async {
                  await _completeOrder(id, false);
                  if (mounted) Navigator.pop(context);
                },
                child: const Text("Pay Later"),
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────────── PAYMENT OPTIONS ─────────────────

  void _showPaymentOptions(String orderId, double amount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Text("Select Payment Method",
                  style: TextStyle(fontWeight: FontWeight.bold)),

              const SizedBox(height: 20),

              ListTile(
                leading: const Icon(Icons.money),
                title: const Text("Cash"),
                onTap: () async {
                  Navigator.pop(context);
                  await _completeOrder(orderId, true);
                },
              ),

              ListTile(
                leading: const Icon(Icons.qr_code),
                title: const Text("Online (QR)"),
                onTap: () {
                  Navigator.pop(context);
                  _showQR(orderId, amount);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────────── QR SCREEN ─────────────────

  void _showQR(String orderId, double amount) {
    final qrUrl =
        "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=upi://pay?pa=yourupi@bank&pn=Shop&am=$amount&cu=INR";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Text("Scan & Pay",
                  style: TextStyle(fontWeight: FontWeight.bold)),

              const SizedBox(height: 20),

              Image.network(qrUrl, height: 200),

              const SizedBox(height: 20),

              const Text("After payment click below"),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: () async {
                  await _completeOrder(orderId, true);
                  if (mounted) Navigator.pop(context);
                },
                child: const Text("I've Paid"),
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────────── COMPLETE ORDER ─────────────────

  Future<void> _completeOrder(String id, bool paid) async {
    await db.collection("orders").doc(id).update({
      "status": OrderStatus.delivered.key,
      "paymentStatus": paid ? "paid" : "unpaid",
      "deliveredAt": FieldValue.serverTimestamp(),
      if (paid) "paidAt": FieldValue.serverTimestamp(),
    });
  }
}