import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/app_theme.dart';
import 'salesman_create_order.dart';

class SalesmanOrdersScreen extends StatefulWidget {
  final String uid;
  const SalesmanOrdersScreen({super.key, required this.uid});

  @override
  State<SalesmanOrdersScreen> createState() => _SalesmanOrdersScreenState();
}

class _SalesmanOrdersScreenState extends State<SalesmanOrdersScreen>
    with SingleTickerProviderStateMixin {
  final db = FirebaseFirestore.instance;
  late TabController _tab;
  String _statusFilter = 'all';
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this)
      ..addListener(() {
        if (!_tab.indexIsChanging) {
          setState(() {
            switch (_tab.index) {
              case 0: _statusFilter = 'all'; break;
              case 1: _statusFilter = 'pending'; break;
              case 2: _statusFilter = 'packed'; break;
              case 3: _statusFilter = 'delivered'; break;
            }
          });
        }
      });
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  List<Map<String, dynamic>> _parseItems(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    if (raw is Map) return raw.values.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    return [];
  }

  bool _inDateRange(Timestamp? ts) {
    if (_dateRange == null || ts == null) return true;
    final d = ts.toDate();
    return d.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
        d.isBefore(_dateRange!.end.add(const Duration(days: 1)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text("My Orders"),
        actions: [
          IconButton(
            icon: Icon(
              Icons.date_range_outlined,
              color: _dateRange != null ? AppTheme.accent : AppTheme.textSecondary,
            ),
            onPressed: _pickDateRange,
          ),
          if (_dateRange != null)
            IconButton(
              icon: const Icon(Icons.close, color: AppTheme.textSecondary),
              onPressed: () => setState(() => _dateRange = null),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(children: [
            Container(height: 1, color: AppTheme.border),
            TabBar(
              controller: _tab,
              labelColor: AppTheme.accent,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.accent,
              indicatorWeight: 2,
              isScrollable: true,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5),
              tabs: const [Tab(text: "ALL"), Tab(text: "PENDING"), Tab(text: "PACKED"), Tab(text: "DELIVERED")],
            ),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goCreateOrder,
        backgroundColor: AppTheme.accent,
        foregroundColor: AppTheme.bg,
        icon: const Icon(Icons.add),
        label: const Text("New Order", style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ✅ No orderBy — avoids composite index. Sort client-side.
        stream: db.collection('orders')
            .where('salesmanId', isEqualTo: widget.uid)
            .snapshots(),
        builder: (_, snap) {
          if (snap.hasError) {
            return Center(child: Text("Error: ${snap.error}",
                style: const TextStyle(color: AppTheme.red)));
          }
          if (!snap.hasData) return const AppLoader();

          // Sort client-side descending by createdAt
          var docs = snap.data!.docs.toList()
            ..sort((a, b) {
              final aTs = (a.data() as Map)['createdAt'] as Timestamp?;
              final bTs = (b.data() as Map)['createdAt'] as Timestamp?;
              if (aTs == null && bTs == null) return 0;
              if (aTs == null) return 1;
              if (bTs == null) return -1;
              return bTs.compareTo(aTs);
            });

          // Apply status + date filters
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'pending';
            final ts = data['createdAt'] as Timestamp?;
            final statusMatch = _statusFilter == 'all' || status == _statusFilter;
            return statusMatch && _inDateRange(ts);
          }).toList();

          if (docs.isEmpty) {
            return AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: _dateRange != null ? "No Orders in Range" : "No Orders",
              subtitle: "Your orders will appear here",
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100, top: 8),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doc  = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              return _orderCard(doc.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _orderCard(String id, Map<String, dynamic> d) {
    final items   = _parseItems(d['items']);
    final status  = d['status'] ?? 'pending';
    final payment = d['paymentStatus'] ?? 'unpaid';
    final total   = (d['totalAmount'] ?? 0).toDouble();
    final ts      = d['createdAt'] as Timestamp?;
    final date    = ts != null
        ? "${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}"
        : '—';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d['shopName'] ?? '—', style: const TextStyle(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 3),
              Text(date, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              StatusBadge.fromStatus(status),
              const SizedBox(height: 4),
              StatusBadge.fromStatus(payment),
            ]),
          ]),
          const AccentDivider(),
          ...items.take(2).map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              Container(width: 5, height: 5,
                decoration: const BoxDecoration(color: AppTheme.textMuted, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(
                "${item['productName']} × ${item['qty']}",
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
              Text("₹${item['total']}", style: const TextStyle(
                color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
            ]),
          )),
          if (items.length > 2)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text("+${items.length - 2} more", style: const TextStyle(
                color: AppTheme.textMuted, fontSize: 11)),
            ),
          const AccentDivider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("Total", style: TextStyle(
              color: AppTheme.textSecondary, fontSize: 13)),
            Text("₹${total.toStringAsFixed(2)}", style: const TextStyle(
              color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 16)),
          ]),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.accent, surface: AppTheme.surface2),
        ),
        child: child!,
      ),
    );
    if (range != null) setState(() => _dateRange = range);
  }

  Future<void> _goCreateOrder() async {
    final productSnap = await db.collection('products').get();
    // ✅ Use 'assignedSalesmanId' — matches the field set by AddShopSheet
    final shopSnap = await db.collection('shops')
        .where('assignedSalesmanId', isEqualTo: widget.uid).get();
    final products = productSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    final shops    = shopSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => SalesmanCreateOrder(uid: widget.uid, shops: shops, products: products),
    ));
  }
}