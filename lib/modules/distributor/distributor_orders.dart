import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/app_theme.dart';
import '../admin/invoices/presentation/screens/invoice_detail_screen.dart';
import '../../../models/invoice_model.dart';
import 'edit_order_quantities_screen.dart';

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

  String _formatValue(dynamic v) {
    if (v == null) return "N/A";
    if (v is String) return v;
    if (v is Map) return v.values.join(", ");
    return v.toString();
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
              return _orderCard(filtered[i].id, d, filtered[i]);
            },
          );
        },
      ),
    );
  }

  // ───────────────── ORDER CARD ─────────────────

  Widget _orderCard(String id, Map<String, dynamic> d, DocumentSnapshot doc) {
    final status = OrderStatusX.fromKey(d["status"]);
    final items = _parseItems(d["items"]);
    final total = _toDouble(d["totalAmount"]);

    return GestureDetector(
      onTap: () => _openOrderDetails(id, d, doc),
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
                      _formatValue(d["shopName"] ?? d["name"]),
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
              Text("Total: ₹${total.toStringAsFixed(2)}"),
              if (d['isEdited'] == true)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text("Modified Order", style: TextStyle(color: AppTheme.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────── DETAILS ─────────────────

  void _openOrderDetails(String id, Map<String, dynamic> d, DocumentSnapshot doc) async {
    final shopId = d["shopId"];
    Map<String, dynamic>? shop;

    if (shopId != null) {
      final snap = await db.collection("shops").doc(shopId).get();
      if (snap.exists) shop = snap.data();
    }

    if (!mounted) return;

    final items = _parseItems(d["items"]);
    final total = _toDouble(d["totalAmount"]);
    final status = OrderStatusX.fromKey(d["status"]);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(_formatValue(d["shopName"] ?? d["name"]),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  Text("₹${_toDouble(total).toStringAsFixed(2)}", style: const TextStyle(color: AppTheme.accent, fontSize: 20, fontWeight: FontWeight.w900)),
                ],
              ),

              const SizedBox(height: 12),

              _infoRow(Icons.location_on_outlined, _formatValue(shop?["address"])),
              _infoRow(Icons.phone_outlined, _formatValue(shop?["phone"])),
              _infoRow(Icons.person_outline, _formatValue(shop?["ownerName"])),

              const Divider(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Items", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (!status.isTerminal)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => EditOrderQuantitiesScreen(orderId: id, orderData: d)));
                      }, 
                      icon: const Icon(Icons.edit_note, size: 18),
                      label: const Text("Adjust Items"),
                    ),
                ],
              ),

              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
                child: ListView(
                  shrinkWrap: true,
                  children: items.map((i) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_formatValue(i["productName"] ?? "Item"), style: const TextStyle(fontSize: 14)),
                    subtitle: Text("Qty: ${_formatValue(i["qty"])}", style: const TextStyle(fontSize: 12)),
                    trailing: Text("₹${(_toDouble(i["price"]) * _toDouble(i["qty"])).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  )).toList(),
                ),
              ),

              const Divider(height: 32),

              // ACTION BUTTONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        final invoice = InvoiceModel.fromFirestore(doc);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoice: invoice)));
                      },
                      icon: const Icon(Icons.receipt_long),
                      label: const Text("View Bill"),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                  if (!status.isTerminal) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showPaymentOptions(id, total);
                        },
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                        child: const Text("Confirm Delivery"),
                      ),
                    ),
                  ],
                ],
              ),

              if (!status.isTerminal) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => _confirmCancel(id),
                    child: const Text("Cancel Order", style: TextStyle(color: AppTheme.red)),
                  ),
                ),
              ],
              
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
        ],
      ),
    );
  }

  void _confirmCancel(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text("Cancel Order?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("KEEP ORDER")),
          TextButton(
            onPressed: () async {
              await db.collection("orders").doc(id).update({"status": OrderStatus.cancelled.key});
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close sheet
              }
            },
            child: const Text("CANCEL", style: TextStyle(color: AppTheme.red)),
          ),
        ],
      ),
    );
  }

  // ───────────────── PAYMENT OPTIONS ─────────────────

  void _showPaymentOptions(String orderId, double amount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select Payment Method", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.money, color: AppTheme.green),
                title: const Text("Cash"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(context);
                  await _completeOrder(orderId, true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code, color: AppTheme.accent),
                title: const Text("Online (QR)"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _showQR(orderId, amount);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: AppTheme.orange),
                title: const Text("Pay Later (Credit)"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  Navigator.pop(context);
                  await _completeOrder(orderId, false);
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
        "upi://pay?pa=khushboowala@okaxis&pn=KhushbooWala&am=$amount&cu=INR";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Scan & Pay", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 24),
              
              // Use real QR widget if possible, else image
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Image.network(
                  "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=$qrUrl",
                  height: 200,
                  width: 200,
                ),
              ),

              const SizedBox(height: 24),
              const Text("Confirm with customer after scan"),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _completeOrder(orderId, true);
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text("PAYMENT CONFIRMED"),
                ),
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

    // Update payment record too
    final payRef = db.collection('payments').doc(id);
    await payRef.update({
      'status': paid ? 'paid' : 'unpaid',
      'deliveredAt': FieldValue.serverTimestamp(),
      if (paid) 'paidAt': FieldValue.serverTimestamp(),
    });
  }
}