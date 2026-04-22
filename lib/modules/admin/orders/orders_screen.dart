import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/app_theme.dart';
import 'create_order_screen.dart';
import 'order_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  STATUS HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/// Full order status lifecycle
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
      case OrderStatus.pending:       return 'pending';
      case OrderStatus.packed:        return 'packed';
      case OrderStatus.assigned:      return 'assigned';
      case OrderStatus.outForDelivery:return 'out_for_delivery';
      case OrderStatus.delivered:     return 'delivered';
      case OrderStatus.failed:        return 'failed';
      case OrderStatus.cancelled:     return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.pending:       return 'Pending';
      case OrderStatus.packed:        return 'Packed';
      case OrderStatus.assigned:      return 'Assigned';
      case OrderStatus.outForDelivery:return 'Out for Delivery';
      case OrderStatus.delivered:     return 'Delivered';
      case OrderStatus.failed:        return 'Failed';
      case OrderStatus.cancelled:     return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending:       return AppTheme.orange;
      case OrderStatus.packed:        return AppTheme.purple;
      case OrderStatus.assigned:      return AppTheme.blue;
      case OrderStatus.outForDelivery:return const Color(0xFF8B5CF6);
      case OrderStatus.delivered:     return AppTheme.green;
      case OrderStatus.failed:        return AppTheme.red;
      case OrderStatus.cancelled:     return AppTheme.textSecondary;
    }
  }

  Color get softColor {
    switch (this) {
      case OrderStatus.pending:       return AppTheme.orangeSoft;
      case OrderStatus.packed:        return AppTheme.purpleSoft;
      case OrderStatus.assigned:      return AppTheme.blueSoft;
      case OrderStatus.outForDelivery:return const Color(0x338B5CF6);
      case OrderStatus.delivered:     return AppTheme.greenSoft;
      case OrderStatus.failed:        return AppTheme.redSoft;
      case OrderStatus.cancelled:     return AppTheme.surface2;
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.pending:       return Icons.hourglass_top_rounded;
      case OrderStatus.packed:        return Icons.inventory_2_outlined;
      case OrderStatus.assigned:      return Icons.assignment_ind_outlined;
      case OrderStatus.outForDelivery:return Icons.local_shipping_outlined;
      case OrderStatus.delivered:     return Icons.check_circle_outline;
      case OrderStatus.failed:        return Icons.cancel_outlined;
      case OrderStatus.cancelled:     return Icons.block_outlined;
    }
  }

  /// The next status in the normal lifecycle (null if terminal)
  OrderStatus? get next {
    switch (this) {
      case OrderStatus.pending:       return OrderStatus.packed;
      case OrderStatus.packed:        return OrderStatus.assigned;
      case OrderStatus.assigned:      return OrderStatus.outForDelivery;
      case OrderStatus.outForDelivery:return OrderStatus.delivered;
      default:                        return null;
    }
  }

  bool get isTerminal =>
      this == OrderStatus.delivered ||
      this == OrderStatus.failed ||
      this == OrderStatus.cancelled;

  static OrderStatus fromKey(String? key) {
    switch (key?.toLowerCase().trim()) {
      case 'packed':           return OrderStatus.packed;
      case 'assigned':         return OrderStatus.assigned;
      case 'out_for_delivery': return OrderStatus.outForDelivery;
      case 'delivered':        return OrderStatus.delivered;
      case 'failed':           return OrderStatus.failed;
      case 'cancelled':        return OrderStatus.cancelled;
      default:                 return OrderStatus.pending;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ORDERS SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  final db = FirebaseFirestore.instance;
  late TabController _tabCtrl;
  String _filter = 'all';
  String _search = '';

  // Tab definitions: label → filter key
  static const _tabs = [
    ('ALL',      'all'),
    ('PENDING',  'pending'),
    ('PACKED',   'packed'),
    ('ASSIGNED', 'assigned'),
    ('TRANSIT',  'out_for_delivery'),
    ('DONE',     'delivered'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this)
      ..addListener(() {
        if (!_tabCtrl.indexIsChanging) {
          setState(() => _filter = _tabs[_tabCtrl.index].$2);
        }
      });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────

  List<Map<String, dynamic>> _parseItems(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    if (raw is Map) return raw.values.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    return [];
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v.toDouble();
    if (v is double) return v;
    return double.tryParse(v.toString()) ?? 0;
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.red : AppTheme.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Create Order ──────────────────────────────────────────

  Future<void> _createOrder() async {
    try {
      final shopSnap    = await db.collection('shops').get();
      final productSnap = await db.collection('products').get();

      final shops    = shopSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      final products = productSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();

      if (!mounted) return;

      if (shops.isEmpty || products.isEmpty) {
        _snack("Add shops & products first", isError: true);
        return;
      }

      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(builder: (_) => CreateOrderScreen(shops: shops, products: products)),
      );

      if (result != null) {
        await db.collection('orders').add({
          ...result,
          'status':        'pending',
          'paymentStatus': 'unpaid',
          'distributorId': null,
          'distributorName': null,
          'tracking': [
            {
              'status':    'pending',
              'note':      'Order created',
              'timestamp': Timestamp.now(),
              'by':        'Admin',
            }
          ],
          'createdAt': FieldValue.serverTimestamp(),
        });
        _snack("Order created successfully");
      }
    } catch (e) {
      _snack("Failed to create order: $e", isError: true);
    }
  }

  // ── Advance Status ────────────────────────────────────────

  Future<void> _advanceStatus(String orderId, Map<String, dynamic> order) async {
    final current = OrderStatusX.fromKey(order['status']);
    final next    = current.next;
    if (next == null) return;

    // If advancing to 'assigned', require a distributor
    if (next == OrderStatus.assigned) {
      await _assignDistributor(orderId, order, thenAdvance: true);
      return;
    }

    try {
      final entry = {
        'status':    next.key,
        'note':      'Status updated to ${next.label}',
        'timestamp': Timestamp.now(),
        'by':        'Admin',
      };

      await db.collection('orders').doc(orderId).update({
        'status': next.key,
        'tracking': FieldValue.arrayUnion([entry]),
        if (next == OrderStatus.packed) ...{
          'packedAt': FieldValue.serverTimestamp(),
        },
        if (next == OrderStatus.delivered) ...{
          'deliveredAt': FieldValue.serverTimestamp(),
        },
      });

      // Auto-create payment record when packing
      if (next == OrderStatus.packed) {
        final invoiceNo = "INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
        await db.collection('payments').add({
          'orderId':    orderId,
          'shopId':     order['shopId'],
          'shopName':   order['shopName'],
          'totalAmount':order['totalAmount'],
          'subTotal':   order['subTotal'],
          'gstAmount':  order['gstAmount'],
          'gstPercent': order['gstPercent'],
          'items':      order['items'],
          'status':     'unpaid',
          'invoiceNo':  invoiceNo,
          'createdAt':  FieldValue.serverTimestamp(),
        });
        _snack("Packed ✓  Invoice: $invoiceNo");
      } else {
        _snack("Status → ${next.label}");
      }
    } catch (e) {
      _snack("Update failed: $e", isError: true);
    }
  }

  // ── Assign Distributor ────────────────────────────────────

  Future<void> _assignDistributor(
    String orderId,
    Map<String, dynamic> order, {
    bool thenAdvance = false,
  }) async {
    final distributors = await db.collection('users')
        .where('role', isEqualTo: 'distributor')
        .get();

    if (!mounted) return;

    if (distributors.docs.isEmpty) {
      _snack("No distributors found", isError: true);
      return;
    }

    String? selId;
    String? selName;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
              )),
              const SizedBox(height: 20),
              const Text("Assign Distributor", style: TextStyle(
                color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 16),
              ...distributors.docs.map((doc) {
                final d    = doc.data();
                final name = d['name'] ?? d['displayName'] ?? 'Distributor';
                final sel  = selId == doc.id;
                return GestureDetector(
                  onTap: () => setS(() { selId = doc.id; selName = name; }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.blueSoft : AppTheme.surface2,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(color: sel ? AppTheme.blue : AppTheme.border),
                    ),
                    child: Row(children: [
                      Icon(Icons.local_shipping_outlined,
                        color: sel ? AppTheme.blue : AppTheme.textSecondary, size: 18),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, style: TextStyle(
                          color: sel ? AppTheme.blue : AppTheme.textPrimary,
                          fontWeight: FontWeight.w600, fontSize: 14)),
                        if (d['phone'] != null)
                          Text(d['phone'], style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                      ])),
                      if (sel) const Icon(Icons.check_circle, color: AppTheme.blue, size: 18),
                    ]),
                  ),
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selId == null ? null : () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: selId != null ? AppTheme.accent : AppTheme.surface2,
                    foregroundColor: selId != null ? AppTheme.bg : AppTheme.textMuted,
                  ),
                  child: const Text("Confirm Assignment"),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selId == null || selName == null) return;

    try {
      final updates = <String, dynamic>{
        'distributorId':   selId,
        'distributorName': selName,
      };

      if (thenAdvance) {
        updates['status'] = OrderStatus.assigned.key;
        updates['tracking'] = FieldValue.arrayUnion([{
          'status':    OrderStatus.assigned.key,
          'note':      'Assigned to $selName',
          'timestamp': Timestamp.now(),
          'by':        'Admin',
        }]);
      }

      await db.collection('orders').doc(orderId).update(updates);
      _snack("Assigned to $selName");
    } catch (e) {
      _snack("Assignment failed: $e", isError: true);
    }
  }

  // ── Mark Payment ──────────────────────────────────────────

  Future<void> _markPayment(String orderId, String currentStatus) async {
    final next = currentStatus == 'unpaid' ? 'paid' : 'unpaid';
    try {
      await db.collection('orders').doc(orderId).update({'paymentStatus': next});
      // sync linked payment doc
      final paySnap = await db.collection('payments')
          .where('orderId', isEqualTo: orderId).limit(1).get();
      if (paySnap.docs.isNotEmpty) {
        await paySnap.docs.first.reference.update({
          'status': next,
          if (next == 'paid') 'paidAt': FieldValue.serverTimestamp(),
        });
      }
      _snack("Payment marked as $next");
    } catch (e) {
      _snack("Payment update failed", isError: true);
    }
  }

  // ── Cancel / Fail ─────────────────────────────────────────

  Future<void> _setTerminalStatus(String orderId, OrderStatus terminal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        title: Text("${terminal.label} Order?",
          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: Text("This action cannot be reversed.",
          style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: terminal.color, foregroundColor: Colors.white),
            child: Text(terminal.label),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await db.collection('orders').doc(orderId).update({
        'status': terminal.key,
        'tracking': FieldValue.arrayUnion([{
          'status':    terminal.key,
          'note':      '${terminal.label} by Admin',
          'timestamp': Timestamp.now(),
          'by':        'Admin',
        }]),
      });
      _snack("Order ${terminal.label}");
    } catch (e) {
      _snack("Failed: $e", isError: true);
    }
  }

  // ── Delete ────────────────────────────────────────────────

  Future<void> _deleteOrder(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        title: const Text("Delete Order?",
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: const Text("This will permanently delete the order.",
          style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red, foregroundColor: Colors.white),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await db.collection('orders').doc(orderId).delete();
      _snack("Order deleted");
    } catch (e) {
      _snack("Delete failed: $e", isError: true);
    }
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text("Orders"),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.accentSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: AppTheme.accent, size: 20),
            ),
            onPressed: _createOrder,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(children: [
            Container(height: 1, color: AppTheme.border),
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: TextField(
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Search by shop, order ID…",
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 18),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 16),
                          onPressed: () => setState(() => _search = ''))
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 6),
            TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              labelColor: AppTheme.accent,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.accent,
              indicatorWeight: 2,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.5),
              tabs: _tabs.map((t) => Tab(text: t.$1)).toList(),
            ),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createOrder,
        icon: const Icon(Icons.add),
        label: const Text("New Order", style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ✅ No orderBy — avoids composite index. Client-side sort.
        stream: db.collection('orders').snapshots(),
        builder: (_, snap) {
          if (snap.hasError) {
            return Center(child: Text("Error: ${snap.error}",
              style: const TextStyle(color: AppTheme.red)));
          }
          if (!snap.hasData) return const AppLoader();

          // Sort client-side descending by createdAt
          final docs = snap.data!.docs.toList()
            ..sort((a, b) {
              final aTs = (a.data() as Map)['createdAt'] as Timestamp?;
              final bTs = (b.data() as Map)['createdAt'] as Timestamp?;
              if (aTs == null && bTs == null) return 0;
              if (aTs == null) return 1;
              if (bTs == null) return -1;
              return bTs.compareTo(aTs);
            });

          // Apply tab filter + search
          final filtered = docs.where((d) {
            final data   = d.data() as Map<String, dynamic>;
            final status = (data['status'] ?? '').toString().toLowerCase().trim();
            final shop   = (data['shopName'] ?? '').toString().toLowerCase();
            final id     = d.id.toLowerCase();

            final tabMatch = _filter == 'all' || status == _filter;
            final searchMatch = _search.isEmpty || shop.contains(_search) || id.contains(_search);
            return tabMatch && searchMatch;
          }).toList();

          if (filtered.isEmpty) {
            return AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: _search.isNotEmpty ? "No results" : "No Orders",
              subtitle: _search.isNotEmpty ? "Try a different search" : "Tap + to create an order",
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100, top: 8),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final doc   = filtered[i];
              final order = doc.data() as Map<String, dynamic>;
              return _OrderCard(
                orderId:        doc.id,
                order:          order,
                items:          _parseItems(order['items']),
                toDouble:       _toDouble,
                onAdvance:      () => _advanceStatus(doc.id, order),
                onAssign:       () => _assignDistributor(doc.id, order),
                onPayment:      () => _markPayment(doc.id, order['paymentStatus'] ?? 'unpaid'),
                onFail:         () => _setTerminalStatus(doc.id, OrderStatus.failed),
                onCancel:       () => _setTerminalStatus(doc.id, OrderStatus.cancelled),
                onDelete:       () => _deleteOrder(doc.id),
                onViewDetails:  () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(orderId: doc.id),
                )),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ORDER CARD WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _OrderCard extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> order;
  final List<Map<String, dynamic>> items;
  final double Function(dynamic) toDouble;
  final VoidCallback onAdvance;
  final VoidCallback onAssign;
  final VoidCallback onPayment;
  final VoidCallback onFail;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback onViewDetails;

  const _OrderCard({
    required this.orderId,
    required this.order,
    required this.items,
    required this.toDouble,
    required this.onAdvance,
    required this.onAssign,
    required this.onPayment,
    required this.onFail,
    required this.onCancel,
    required this.onDelete,
    required this.onViewDetails,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final o       = widget.order;
    final status  = OrderStatusX.fromKey(o['status']);
    final payment = (o['paymentStatus'] ?? 'unpaid').toString();
    final total   = widget.toDouble(o['totalAmount']);
    final sub     = widget.toDouble(o['subTotal']);
    final gstAmt  = widget.toDouble(o['gstAmount']);
    final gstPct  = widget.toDouble(o['gstPercent']);
    final ts      = o['createdAt'] as Timestamp?;
    final date    = ts != null
        ? "${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}"
        : '—';
    final nextStatus = status.next;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    // Shop icon
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.surface2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Icon(Icons.store_outlined, color: AppTheme.textSecondary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o['shopName'] ?? '—', style: const TextStyle(
                          color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 3),
                        Text("${widget.items.length} item(s)  ·  $date",
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      ],
                    )),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text("₹${total.toStringAsFixed(2)}", style: const TextStyle(
                        color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 5),
                      _statusChip(status),
                    ]),
                  ]),

                  const SizedBox(height: 10),

                  // Status progress strip
                  _StatusProgressBar(current: status),
                ],
              ),
            ),
          ),

          // ── Expanded section ─────────────────────────────
          if (_expanded) ...[
            Container(height: 1, color: AppTheme.border),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Distributor info
                  if (o['distributorName'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(children: [
                        const Icon(Icons.local_shipping_outlined, color: AppTheme.blue, size: 14),
                        const SizedBox(width: 6),
                        Text(o['distributorName'], style: const TextStyle(
                          color: AppTheme.blue, fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    ),

                  // Items
                  ...widget.items.take(3).map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(children: [
                      Container(width: 5, height: 5,
                        decoration: const BoxDecoration(color: AppTheme.textMuted, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        "${item['productName']} × ${item['qty']}",
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
                      Text("₹${widget.toDouble(item['total']).toStringAsFixed(0)}",
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
                    ]),
                  )),
                  if (widget.items.length > 3)
                    Text("+${widget.items.length - 3} more items",
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),

                  const AccentDivider(),

                  // Bill rows
                  _miniRow("Subtotal", "₹${sub.toStringAsFixed(2)}"),
                  const SizedBox(height: 4),
                  _miniRow("GST (${gstPct.toStringAsFixed(0)}%)", "₹${gstAmt.toStringAsFixed(2)}"),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text("Total", style: TextStyle(
                      color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                    Text("₹${total.toStringAsFixed(2)}", style: const TextStyle(
                      color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 17)),
                  ]),

                  const SizedBox(height: 12),

                  // Payment row
                  Row(children: [
                    _payBadge(payment),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: widget.onPayment,
                      icon: Icon(
                        payment == 'paid' ? Icons.money_off_outlined : Icons.attach_money_rounded,
                        size: 16,
                        color: payment == 'paid' ? AppTheme.textSecondary : AppTheme.green,
                      ),
                      label: Text(
                        payment == 'paid' ? "Mark Unpaid" : "Mark Paid",
                        style: TextStyle(
                          color: payment == 'paid' ? AppTheme.textSecondary : AppTheme.green,
                          fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 8),

                  // Action buttons
                  _ActionButtons(
                    status:         status,
                    nextStatus:     nextStatus,
                    hasDistributor: o['distributorName'] != null,
                    onAdvance:      widget.onAdvance,
                    onAssign:       widget.onAssign,
                    onFail:         widget.onFail,
                    onCancel:       widget.onCancel,
                    onDelete:       widget.onDelete,
                    onViewDetails:  widget.onViewDetails,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(OrderStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.softColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withOpacity(0.4)),
      ),
      child: Text(status.label, style: TextStyle(
        color: status.color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
    );
  }

  Widget _payBadge(String status) {
    final isPaid = status == 'paid';
    final color  = isPaid ? AppTheme.green : AppTheme.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(isPaid ? "PAID" : "UNPAID", style: TextStyle(
        color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
    );
  }

  Widget _miniRow(String l, String v) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(l, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      Text(v, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  STATUS PROGRESS BAR
// ─────────────────────────────────────────────────────────────────────────────

class _StatusProgressBar extends StatelessWidget {
  final OrderStatus current;
  const _StatusProgressBar({required this.current});

  static const _flow = [
    OrderStatus.pending,
    OrderStatus.packed,
    OrderStatus.assigned,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    if (current == OrderStatus.failed || current == OrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: current.softColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(children: [
          Icon(current.icon, color: current.color, size: 14),
          const SizedBox(width: 6),
          Text(current.label, style: TextStyle(
            color: current.color, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      );
    }

    final currentIdx = _flow.indexOf(current);

    return Row(children: _flow.asMap().entries.map((entry) {
      final i      = entry.key;
      final status = entry.value;
      final done   = i <= currentIdx;
      final isLast = i == _flow.length - 1;

      return Expanded(child: Row(children: [
        Expanded(child: Column(children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              color: done ? status.color : AppTheme.surface2,
              shape: BoxShape.circle,
              border: Border.all(
                color: done ? status.color : AppTheme.border,
                width: 1.5,
              ),
            ),
            child: done
                ? Icon(Icons.check, color: AppTheme.bg, size: 11)
                : null,
          ),
          const SizedBox(height: 4),
          Text(
            status.label.split(' ').first,
            style: TextStyle(
              color: done ? status.color : AppTheme.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ])),
        if (!isLast)
          Expanded(child: Container(
            height: 2,
            margin: const EdgeInsets.only(bottom: 14),
            color: i < currentIdx ? _flow[i + 1].color.withOpacity(0.4) : AppTheme.border,
          )),
      ]));
    }).toList());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ACTION BUTTONS
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final OrderStatus status;
  final OrderStatus? nextStatus;
  final bool hasDistributor;
  final VoidCallback onAdvance;
  final VoidCallback onAssign;
  final VoidCallback onFail;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback onViewDetails;

  const _ActionButtons({
    required this.status,
    required this.nextStatus,
    required this.hasDistributor,
    required this.onAdvance,
    required this.onAssign,
    required this.onFail,
    required this.onCancel,
    required this.onDelete,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // View details — always visible
        _btn(
          label: "Details",
          icon: Icons.open_in_new_rounded,
          color: AppTheme.textSecondary,
          soft: AppTheme.surface2,
          onTap: onViewDetails,
        ),

        // Assign/Reassign distributor
        if (!status.isTerminal)
          _btn(
            label: hasDistributor ? "Reassign" : "Assign",
            icon: Icons.person_pin_circle_outlined,
            color: AppTheme.blue,
            soft: AppTheme.blueSoft,
            onTap: onAssign,
          ),

        // Advance to next status
        if (nextStatus != null && nextStatus != OrderStatus.assigned)
          _btn(
            label: nextStatus!.label,
            icon: nextStatus!.icon,
            color: nextStatus!.color,
            soft: nextStatus!.softColor,
            onTap: onAdvance,
            primary: true,
          ),

        // Assigned advance (requires distributor)
        if (nextStatus == OrderStatus.assigned)
          _btn(
            label: "Assign & Pack",
            icon: Icons.assignment_ind_outlined,
            color: AppTheme.blue,
            soft: AppTheme.blueSoft,
            onTap: onAdvance,
            primary: true,
          ),

        // Fail / Cancel — only on active orders
        if (!status.isTerminal) ...[
          _btn(label: "Fail", icon: Icons.cancel_outlined, color: AppTheme.red, soft: AppTheme.redSoft, onTap: onFail),
          _btn(label: "Cancel", icon: Icons.block_outlined, color: AppTheme.textSecondary, soft: AppTheme.surface2, onTap: onCancel),
        ],

        // Delete — always
        _btn(label: "Delete", icon: Icons.delete_outline_rounded, color: AppTheme.red, soft: AppTheme.redSoft, onTap: onDelete),
      ],
    );
  }

  Widget _btn({
    required String label,
    required IconData icon,
    required Color color,
    required Color soft,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: primary ? color.withOpacity(0.18) : soft,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: primary ? color.withOpacity(0.5) : color.withOpacity(0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
        ]),
      ),
    );
  }
}