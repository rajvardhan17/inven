import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/app_theme.dart';
import 'orders_screen.dart'; // for OrderStatus + extensions

// ─────────────────────────────────────────────────────────────────────────────
//  ORDER DETAIL SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return Scaffold(
            backgroundColor: AppTheme.bg,
            appBar: AppBar(backgroundColor: AppTheme.surface, title: const Text("Order")),
            body: const AppLoader(),
          );
        }

        final order = snap.data!.data() as Map<String, dynamic>;
        return _OrderDetailView(orderId: orderId, order: order);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DETAIL VIEW (stateful for tab control)
// ─────────────────────────────────────────────────────────────────────────────

class _OrderDetailView extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> order;
  const _OrderDetailView({required this.orderId, required this.order});

  @override
  State<_OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<_OrderDetailView>
    with SingleTickerProviderStateMixin {
  final db = FirebaseFirestore.instance;
  late TabController _tab;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────

  List<Map<String, dynamic>> _parseItems(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    if (raw is Map) return raw.values.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    return [];
  }

  List<Map<String, dynamic>> _parseTracking(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
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

  // ── Update Status ─────────────────────────────────────────

  Future<void> _addTrackingNote() async {
    final noteCtrl = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 20),
            const Text("Add Tracking Note", style: TextStyle(
              color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(
              controller: noteCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              maxLines: 3,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "Enter note…",
                labelText: "Note",
                prefixIcon: Icon(Icons.notes_outlined, size: 18),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, noteCtrl.text.trim()),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                child: const Text("Add Note"),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == null || result.isEmpty) return;
    setState(() => _actionLoading = true);
    try {
      final status = widget.order['status'] ?? 'pending';
      await db.collection('orders').doc(widget.orderId).update({
        'tracking': FieldValue.arrayUnion([{
          'status':    status,
          'note':      result,
          'timestamp': Timestamp.now(),
          'by':        'Admin',
        }]),
      });
      _snack("Note added");
    } catch (e) {
      _snack("Failed: $e", isError: true);
    }
    if (mounted) setState(() => _actionLoading = false);
  }

  Future<void> _advanceStatus() async {
    final current = OrderStatusX.fromKey(widget.order['status']);
    final next    = current.next;
    if (next == null) return;

    setState(() => _actionLoading = true);
    try {
      final entry = {
        'status':    next.key,
        'note':      'Status updated to ${next.label}',
        'timestamp': Timestamp.now(),
        'by':        'Admin',
      };
      await db.collection('orders').doc(widget.orderId).update({
        'status':   next.key,
        'tracking': FieldValue.arrayUnion([entry]),
        if (next == OrderStatus.delivered) 'deliveredAt': FieldValue.serverTimestamp(),
      });
      _snack("→ ${next.label}");
    } catch (e) {
      _snack("Failed: $e", isError: true);
    }
    if (mounted) setState(() => _actionLoading = false);
  }

  Future<void> _markPayment() async {
    final current = (widget.order['paymentStatus'] ?? 'unpaid').toString();
    final next    = current == 'paid' ? 'unpaid' : 'paid';
    setState(() => _actionLoading = true);
    try {
      await db.collection('orders').doc(widget.orderId).update({'paymentStatus': next});
      final paySnap = await db.collection('payments')
          .where('orderId', isEqualTo: widget.orderId).limit(1).get();
      if (paySnap.docs.isNotEmpty) {
        await paySnap.docs.first.reference.update({
          'status': next,
          if (next == 'paid') 'paidAt': FieldValue.serverTimestamp(),
        });
      }
      _snack("Payment marked $next");
    } catch (e) {
      _snack("Failed: $e", isError: true);
    }
    if (mounted) setState(() => _actionLoading = false);
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final o       = widget.order;
    final status  = OrderStatusX.fromKey(o['status']);
    final payment = (o['paymentStatus'] ?? 'unpaid').toString();
    final items   = _parseItems(o['items']);
    final tracking= _parseTracking(o['tracking']);
    final total   = _toDouble(o['totalAmount']);
    final sub     = _toDouble(o['subTotal']);
    final gstAmt  = _toDouble(o['gstAmount']);
    final gstPct  = _toDouble(o['gstPercent']);
    final nextStatus = status.next;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Text(widget.orderId.length > 16
            ? "#${widget.orderId.substring(0, 8)}…"
            : "#${widget.orderId}"),
        actions: [
          if (_actionLoading)
            const Center(child: SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
            )),
          IconButton(
            icon: const Icon(Icons.note_add_outlined, color: AppTheme.textSecondary),
            onPressed: _addTrackingNote,
            tooltip: "Add note",
          ),
          const SizedBox(width: 8),
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
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5),
              tabs: const [Tab(text: "DETAILS"), Tab(text: "TRACKING"), Tab(text: "ACTIONS")],
            ),
          ]),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // ── Tab 1: Details ───────────────────────────────
          _DetailsTab(
            order: o,
            items: items,
            status: status,
            payment: payment,
            total: total,
            sub: sub,
            gstAmt: gstAmt,
            gstPct: gstPct,
          ),

          // ── Tab 2: Tracking ──────────────────────────────
          _TrackingTab(tracking: tracking, status: status),

          // ── Tab 3: Actions ───────────────────────────────
          _ActionsTab(
            orderId: widget.orderId,
            order: o,
            status: status,
            nextStatus: nextStatus,
            payment: payment,
            total: total,
            onAdvance: _advanceStatus,
            onPayment: _markPayment,
            loading: _actionLoading,
            db: db,
            snack: _snack,
            setLoading: (v) => setState(() => _actionLoading = v),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TAB 1: DETAILS
// ─────────────────────────────────────────────────────────────────────────────

class _DetailsTab extends StatelessWidget {
  final Map<String, dynamic> order;
  final List<Map<String, dynamic>> items;
  final OrderStatus status;
  final String payment;
  final double total, sub, gstAmt, gstPct;

  const _DetailsTab({
    required this.order,
    required this.items,
    required this.status,
    required this.payment,
    required this.total,
    required this.sub,
    required this.gstAmt,
    required this.gstPct,
  });

  double _td(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v.toDouble();
    if (v is double) return v;
    return double.tryParse(v.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // Header card
        AppCard(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("ORDER ID", style: TextStyle(
                  color: AppTheme.textMuted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                SelectableText(order['orderId'] ?? '', style: const TextStyle(
                  color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.3)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                _statusChip(status),
                const SizedBox(height: 6),
                _payChip(payment),
              ]),
            ]),
            const AccentDivider(),
            Row(children: [
              Expanded(child: _detailField("Shop", order['shopName'] ?? '—')),
              Expanded(child: _detailField("Salesman", order['salesmanName'] ?? '—')),
            ]),
            if (order['distributorName'] != null) ...[
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.local_shipping_outlined, color: AppTheme.blue, size: 14),
                const SizedBox(width: 6),
                Text(order['distributorName'], style: const TextStyle(
                  color: AppTheme.blue, fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            ],
          ]),
        ),

        // Shop info card
        if (order['shopAddress'] != null || order['shopPhone'] != null)
          AppCard(
            margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("SHOP INFO", style: TextStyle(
                color: AppTheme.textMuted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              if (order['shopPhone'] != null)
                _infoRow(Icons.phone_outlined, order['shopPhone']),
              if (order['shopAddress'] != null) ...[
                const SizedBox(height: 8),
                _infoRow(Icons.location_on_outlined, order['shopAddress']),
              ],
            ]),
          ),

        // Items table
        AppCard(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text("ITEMS", style: TextStyle(
                color: AppTheme.textMuted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accentSoft, borderRadius: BorderRadius.circular(20)),
                child: Text("${items.length}", style: const TextStyle(
                  color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 12),
            // Table header
            Row(children: const [
              Expanded(flex: 4, child: Text("PRODUCT", style: TextStyle(color: AppTheme.textMuted, fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w600))),
              Expanded(flex: 1, child: Text("QTY", style: TextStyle(color: AppTheme.textMuted, fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text("PRICE", style: TextStyle(color: AppTheme.textMuted, fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
              Expanded(flex: 2, child: Text("TOTAL", style: TextStyle(color: AppTheme.textMuted, fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
            ]),
            const SizedBox(height: 8),
            const Divider(color: AppTheme.border, height: 1),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(flex: 4, child: Text(item['productName'] ?? '—',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
                  Expanded(flex: 1, child: Text("×${item['qty'] ?? 0}",
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                  Expanded(flex: 2, child: Text("₹${_td(item['price']).toStringAsFixed(0)}",
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13), textAlign: TextAlign.right)),
                  Expanded(flex: 2, child: Text("₹${_td(item['total']).toStringAsFixed(2)}",
                    style: const TextStyle(color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
                ]),
                const Divider(color: AppTheme.border, height: 16),
              ]),
            )),
          ]),
        ),

        // Billing summary
        AppCard(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("BILLING SUMMARY", style: TextStyle(
              color: AppTheme.textMuted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            _billRow("Subtotal", "₹${sub.toStringAsFixed(2)}", false),
            const SizedBox(height: 8),
            _billRow("GST (${gstPct.toStringAsFixed(0)}%)", "₹${gstAmt.toStringAsFixed(2)}", false),
            const AccentDivider(),
            _billRow("Grand Total", "₹${total.toStringAsFixed(2)}", true),
          ]),
        ),
      ],
    );
  }

  Widget _statusChip(OrderStatus s) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: s.softColor, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: s.color.withOpacity(0.4))),
    child: Text(s.label, style: TextStyle(
      color: s.color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
  );

  Widget _payChip(String p) {
    final isPaid = p == 'paid';
    final c = isPaid ? AppTheme.green : AppTheme.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.4))),
      child: Text(isPaid ? "PAID" : "UNPAID",
        style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
    );
  }

  Widget _detailField(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, letterSpacing: 1)),
      const SizedBox(height: 3),
      Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
    ],
  );

  Widget _infoRow(IconData icon, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: AppTheme.textMuted, size: 14),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
    ],
  );

  Widget _billRow(String label, String value, bool bold) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(
        color: bold ? AppTheme.textPrimary : AppTheme.textSecondary,
        fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
        fontSize: bold ? 15 : 13)),
      Text(value, style: TextStyle(
        color: bold ? AppTheme.accent : AppTheme.textPrimary,
        fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
        fontSize: bold ? 18 : 13)),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  TAB 2: TRACKING TIMELINE
// ─────────────────────────────────────────────────────────────────────────────

class _TrackingTab extends StatelessWidget {
  final List<Map<String, dynamic>> tracking;
  final OrderStatus status;
  const _TrackingTab({required this.tracking, required this.status});

  static const _lifecycle = [
    OrderStatus.pending,
    OrderStatus.packed,
    OrderStatus.assigned,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final doneKeys = tracking.map((t) => t['status']?.toString() ?? '').toSet();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        // Timeline
        ..._lifecycle.asMap().entries.map((entry) {
          final i       = entry.key;
          final st      = entry.value;
          final done    = doneKeys.contains(st.key);
          final isLast  = i == _lifecycle.length - 1;
          final entries = tracking.where((t) => t['status'] == st.key).toList();

          return _TimelineStep(
            status: st,
            done: done,
            isLast: isLast,
            entries: entries,
          );
        }),

        // Failed / Cancelled — if applicable
        if (status == OrderStatus.failed || status == OrderStatus.cancelled) ...[
          _TimelineStep(
            status: status,
            done: true,
            isLast: true,
            entries: tracking.where((t) => t['status'] == status.key).toList(),
            isFinalBad: true,
          ),
        ],

        // Extra notes (same-status notes after first entry)
        if (tracking.length > _lifecycle.length) ...[
          const SizedBox(height: 8),
          AppCard(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("ALL TRACKING ENTRIES", style: TextStyle(
                  color: AppTheme.textMuted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ...tracking.reversed.map((t) => _entryRow(t)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _entryRow(Map<String, dynamic> t) {
    final ts  = t['timestamp'];
    final dt  = ts is Timestamp ? ts.toDate() : (ts is DateTime ? ts : null);
    final fmt = dt != null
        ? "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}"
        : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 6, height: 6, margin: const EdgeInsets.only(top: 5),
          decoration: const BoxDecoration(color: AppTheme.textMuted, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t['note'] ?? '—', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 2),
          Text("${t['by'] ?? 'System'}  ·  $fmt",
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        ])),
      ]),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final OrderStatus status;
  final bool done;
  final bool isLast;
  final bool isFinalBad;
  final List<Map<String, dynamic>> entries;

  const _TimelineStep({
    required this.status,
    required this.done,
    required this.isLast,
    required this.entries,
    this.isFinalBad = false,
  });

  @override
  Widget build(BuildContext context) {
    final color  = done ? status.color : AppTheme.textMuted;
    final bgColor= done ? status.softColor : AppTheme.surface2;

    final ts  = entries.isNotEmpty ? entries.last['timestamp'] : null;
    final dt  = ts is Timestamp ? ts.toDate() : null;
    final fmt = dt != null
        ? "${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}"
        : null;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: dot + line
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: done ? color : AppTheme.border, width: 1.5),
                  ),
                  child: Center(child: Icon(
                    done ? Icons.check_rounded : status.icon,
                    color: done ? color : AppTheme.textMuted,
                    size: 15,
                  )),
                ),
                if (!isLast)
                  Expanded(child: Container(
                    width: 2,
                    color: done ? color.withOpacity(0.3) : AppTheme.border,
                  )),
              ],
            ),
          ),

          // Right: content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 12, bottom: isLast ? 0 : 24, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(status.label, style: TextStyle(
                    color: done ? color : AppTheme.textMuted,
                    fontWeight: done ? FontWeight.w700 : FontWeight.normal,
                    fontSize: 14,
                  )),
                  if (fmt != null) ...[
                    const SizedBox(height: 2),
                    Text(fmt, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  ],
                  ...entries.map((e) {
                    if (e['note'] == null || e['note'].toString().isEmpty) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppTheme.surface2,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e['note'], style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                          if (e['by'] != null)
                            Text("— ${e['by']}", style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 10)),
                        ]),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TAB 3: ACTIONS
// ─────────────────────────────────────────────────────────────────────────────

class _ActionsTab extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> order;
  final OrderStatus status;
  final OrderStatus? nextStatus;
  final String payment;
  final double total;
  final VoidCallback onAdvance;
  final VoidCallback onPayment;
  final bool loading;
  final FirebaseFirestore db;
  final void Function(String, {bool isError}) snack;
  final void Function(bool) setLoading;

  const _ActionsTab({
    required this.orderId,
    required this.order,
    required this.status,
    required this.nextStatus,
    required this.payment,
    required this.total,
    required this.onAdvance,
    required this.onPayment,
    required this.loading,
    required this.db,
    required this.snack,
    required this.setLoading,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        // ── Status advance ───────────────────────────────
        if (nextStatus != null) ...[
          const SectionHeader(title: "Status Update"),
          AppCard(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _chip(status.label, status.color, status.softColor),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded,
                    color: AppTheme.textMuted, size: 16),
                ),
                _chip(nextStatus!.label, nextStatus!.color, nextStatus!.softColor),
              ]),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: loading ? null : onAdvance,
                  icon: Icon(nextStatus!.icon, size: 18),
                  label: Text("Mark as ${nextStatus!.label}"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: nextStatus!.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ]),
          ),
        ],

        // ── Assign distributor ───────────────────────────
        if (!status.isTerminal) ...[
          const SectionHeader(title: "Distributor"),
          AppCard(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (order['distributorName'] != null) ...[
                Row(children: [
                  const Icon(Icons.local_shipping_outlined, color: AppTheme.blue, size: 16),
                  const SizedBox(width: 8),
                  Text(order['distributorName'], style: const TextStyle(
                    color: AppTheme.blue, fontWeight: FontWeight.w600, fontSize: 14)),
                ]),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: loading ? null : () => _assignDistributor(context),
                  icon: const Icon(Icons.person_pin_circle_outlined, size: 18),
                  label: Text(order['distributorName'] != null ? "Reassign Distributor" : "Assign Distributor"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.blue,
                    side: const BorderSide(color: AppTheme.blue),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ]),
          ),
        ],

        // ── Payment ──────────────────────────────────────
        const SectionHeader(title: "Payment"),
        AppCard(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Amount Due", style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text("₹${total.toStringAsFixed(2)}", style: const TextStyle(
                  color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 20)),
              ]),
              _chip(
                payment == 'paid' ? "PAID" : "UNPAID",
                payment == 'paid' ? AppTheme.green : AppTheme.orange,
                payment == 'paid' ? AppTheme.greenSoft : AppTheme.orangeSoft,
              ),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: loading ? null : onPayment,
                icon: Icon(
                  payment == 'paid' ? Icons.money_off_outlined : Icons.check_circle_outline,
                  size: 18,
                ),
                label: Text(payment == 'paid' ? "Mark as Unpaid" : "Mark as Paid"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: payment == 'paid' ? AppTheme.orange : AppTheme.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ]),
        ),

        // ── Danger zone ──────────────────────────────────
        if (!status.isTerminal) ...[
          const SectionHeader(title: "Danger Zone"),
          AppCard(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Column(children: [
              _dangerBtn(
                context,
                label: "Mark as Failed",
                icon: Icons.cancel_outlined,
                color: AppTheme.red,
                onTap: () => _terminalAction(context, OrderStatus.failed),
              ),
              const SizedBox(height: 8),
              _dangerBtn(
                context,
                label: "Cancel Order",
                icon: Icons.block_outlined,
                color: AppTheme.textSecondary,
                onTap: () => _terminalAction(context, OrderStatus.cancelled),
              ),
            ]),
          ),
        ],

        const SectionHeader(title: ""),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: OutlinedButton.icon(
            onPressed: loading ? null : () => _deleteOrder(context),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text("Delete Order"),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.red,
              side: const BorderSide(color: AppTheme.red),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, Color color, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bg, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4))),
    child: Text(label, style: TextStyle(
      color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
  );

  Widget _dangerBtn(BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: loading ? null : onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }

  Future<void> _assignDistributor(BuildContext context) async {
    final distributors = await db.collection('users')
        .where('role', isEqualTo: 'distributor')
        .get();

    if (!context.mounted) return;
    if (distributors.docs.isEmpty) { snack("No distributors found", isError: true); return; }

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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text("Assign Distributor", style: TextStyle(
              color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
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
                    border: Border.all(color: sel ? AppTheme.blue : AppTheme.border)),
                  child: Row(children: [
                    Icon(Icons.local_shipping_outlined,
                      color: sel ? AppTheme.blue : AppTheme.textSecondary, size: 18),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: TextStyle(
                        color: sel ? AppTheme.blue : AppTheme.textPrimary,
                        fontWeight: FontWeight.w600, fontSize: 14)),
                      if (d['phone'] != null) Text(d['phone'],
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
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
                child: const Text("Confirm"),
              ),
            ),
          ]),
        ),
      ),
    );

    if (selId == null || selName == null) return;
    setLoading(true);
    try {
      await db.collection('orders').doc(orderId).update({
        'distributorId':   selId,
        'distributorName': selName,
        'tracking': FieldValue.arrayUnion([{
          'status':    order['status'] ?? 'pending',
          'note':      'Assigned to $selName',
          'timestamp': Timestamp.now(),
          'by':        'Admin',
        }]),
      });
      snack("Assigned to $selName");
    } catch (e) {
      snack("Failed: $e", isError: true);
    }
    setLoading(false);
  }

  Future<void> _terminalAction(BuildContext context, OrderStatus terminal) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        title: Text("${terminal.label}?",
          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: const Text("This cannot be undone.",
          style: TextStyle(color: AppTheme.textSecondary)),
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
    if (ok != true) return;
    setLoading(true);
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
      snack("Order ${terminal.label}");
    } catch (e) {
      snack("Failed: $e", isError: true);
    }
    setLoading(false);
  }

  Future<void> _deleteOrder(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        title: const Text("Delete Order?",
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: const Text("Permanently deletes this order.",
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
    if (ok != true) return;
    setLoading(true);
    try {
      await db.collection('orders').doc(orderId).delete();
      snack("Order deleted");
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      snack("Failed: $e", isError: true);
    }
    setLoading(false);
  }
}