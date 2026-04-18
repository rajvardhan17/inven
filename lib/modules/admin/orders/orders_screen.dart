import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_order_screen.dart';
import '../../../core/app_theme.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  late TabController _tabCtrl;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();

    _tabCtrl = TabController(length: 4, vsync: this)
      ..addListener(() {
        if (!_tabCtrl.indexIsChanging) {
          setState(() {
            switch (_tabCtrl.index) {
              case 0:
                _filter = 'all';
                break;
              case 1:
                _filter = 'pending';
                break;
              case 2:
                _filter = 'packed';
                break;
              case 3:
                _filter = 'delivered';
                break;
            }
          });
        }
      });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ───────────────── SAFE PARSER ─────────────────
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

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v.toDouble();
    if (v is double) return v;
    return double.tryParse(v.toString()) ?? 0;
  }

  String _status(dynamic s) => s?.toString().toLowerCase().trim() ?? '';

  // ───────────────── CREATE ORDER ─────────────────
  Future<void> _createOrder() async {
    try {
      final shopSnap = await db.collection('shops').get();
      final productSnap = await db.collection('products').get();

      final shops =
          shopSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();

      final products =
          productSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();

      if (shops.isEmpty || products.isEmpty) {
        _showSnack("Add shops & products first", isError: true);
        return;
      }

      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CreateOrderScreen(shops: shops, products: products),
        ),
      );

      if (result != null) {
        await db.collection('orders').add({
          ...result,
          'status': 'pending',
          'paymentStatus': 'unpaid',
          'createdAt': FieldValue.serverTimestamp(),
        });

        _showSnack("Order created");
      }
    } catch (e) {
      _showSnack("Failed to create order", isError: true);
    }
  }

  // ───────────────── PACK ORDER ─────────────────
  Future<void> _packOrder(String orderId, Map<String, dynamic> order) async {
    try {
      final invoiceNo =
          "INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

      await db.runTransaction((txn) async {
        final orderRef = db.collection('orders').doc(orderId);
        final paymentRef = db.collection('payments').doc();

        txn.update(orderRef, {
          'status': 'packed',
          'paymentStatus': 'unpaid',
        });

        txn.set(paymentRef, {
          'orderId': orderId,
          'shopId': order['shopId'],
          'shopName': order['shopName'],
          'totalAmount': order['totalAmount'],
          'subTotal': order['subTotal'],
          'gstAmount': order['gstAmount'],
          'gstPercent': order['gstPercent'],
          'items': order['items'],
          'status': 'unpaid',
          'invoiceNo': invoiceNo,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      _showSnack("Packed ✓ $invoiceNo");
    } catch (e) {
      _showSnack("Pack failed", isError: true);
    }
  }

  // ───────────────── MARK DELIVERED ─────────────────
  Future<void> _markDelivered(String orderId) async {
    try {
      await db.runTransaction((txn) async {
        final orderRef = db.collection('orders').doc(orderId);
        final deliveryRef =
            db.collection('deliveries').doc(orderId);

        txn.update(orderRef, {
          'status': 'delivered',
          'deliveredAt': FieldValue.serverTimestamp(),
        });

        txn.set(deliveryRef, {
          'orderId': orderId,
          'status': 'delivered',
          'deliveredAt': FieldValue.serverTimestamp(),
          'notes': '',
        });
      });

      _showSnack("Delivered successfully");
    } catch (e) {
      _showSnack("Delivery failed", isError: true);
    }
  }

  // ───────────────── SNACKBAR ─────────────────
  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? AppTheme.red : AppTheme.green,
      ),
    );
  }

  // ───────────────── UI ─────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text("Orders"),
        backgroundColor: AppTheme.surface,
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: "ALL"),
            Tab(text: "PENDING"),
            Tab(text: "PACKED"),
            Tab(text: "DELIVERED"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createOrder,
        icon: const Icon(Icons.add),
        label: const Text("New Order"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          final filtered = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final status = _status(data['status']);

            if (_filter == 'all') return true;
            return status == _filter;
          }).toList();

          if (filtered.isEmpty) {
            return const Center(child: Text("No orders"));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100, top: 8),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final doc = filtered[i];
              final order = doc.data() as Map<String, dynamic>;
              final items = _parseItems(order['items']);

              return _orderCard(doc.id, order, items);
            },
          );
        },
      ),
    );
  }

  // ───────────────── ORDER CARD ─────────────────
  Widget _orderCard(
    String id,
    Map<String, dynamic> order,
    List<Map<String, dynamic>> items,
  ) {
    final status = _status(order['status']);
    final payment = _status(order['paymentStatus']);

    final total = _toDouble(order['totalAmount']);
    final sub = _toDouble(order['subTotal']);
    final gst = _toDouble(order['gstAmount']);
    final gstPct = _toDouble(order['gstPercent']);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.store, color: AppTheme.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(order['shopName'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold)),
              ),
              Column(
                children: [
                  Text(status.toUpperCase()),
                  Text(payment),
                ],
              )
            ],
          ),

          const SizedBox(height: 10),

          Text("Items: ${items.length}"),

          const Divider(),

          Text("Subtotal ₹$sub"),
          Text("GST ₹$gst ($gstPct%)"),
          Text("Total ₹$total"),

          const SizedBox(height: 10),

          Row(
            children: [
              if (status == 'pending')
                ElevatedButton(
                  onPressed: () => _packOrder(id, order),
                  child: const Text("Pack"),
                )
              else if (status == 'packed')
                ElevatedButton(
                  onPressed: () => _markDelivered(id),
                  child: const Text("Deliver"),
                )
              else
                const Text("DELIVERED"),
            ],
          )
        ],
      ),
    );
  }
}