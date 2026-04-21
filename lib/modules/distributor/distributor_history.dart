import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/app_theme.dart';

class DistributorHistoryScreen extends StatefulWidget {
  final String uid;
  const DistributorHistoryScreen({super.key, required this.uid});

  @override
  State<DistributorHistoryScreen> createState() => _DistributorHistoryScreenState();
}

class _DistributorHistoryScreenState extends State<DistributorHistoryScreen>
    with SingleTickerProviderStateMixin {
  final db = FirebaseFirestore.instance;
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  List<Map<String, dynamic>> _parseItems(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text("History"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(children: [
            Container(height: 1, color: AppTheme.border),
            TabBar(
              controller: _tab,
              labelColor: AppTheme.green,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.green,
              indicatorWeight: 2,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5),
              tabs: const [Tab(text: "DELIVERIES"), Tab(text: "PAYMENTS")],
            ),
          ]),
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

  // ── Deliveries Tab ────────────────────────────────────────
  Widget _deliveriesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('orders')
          .where('distributorId', isEqualTo: widget.uid)
          .where('deliveryStatus', isEqualTo: 'delivered')
          .orderBy('deliveredAt', descending: true)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const AppLoader();
        final docs = snap.data!.docs;

        if (docs.isEmpty) {
          return const AppEmptyState(
            icon: Icons.check_circle_outline,
            title: "No Deliveries Yet",
            subtitle: "Completed deliveries appear here",
          );
        }

        // Summary
        double totalCollected = 0;
        int count = docs.length;
        for (var d in docs) {
          final data = d.data() as Map<String, dynamic>;
          totalCollected += (data['totalAmount'] ?? 0).toDouble();
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 24, top: 8),
          children: [
            // Summary strip
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.green.withOpacity(0.3)),
              ),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Total Delivered", style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text("$count orders", style: const TextStyle(
                    color: AppTheme.green, fontSize: 20, fontWeight: FontWeight.w800)),
                ])),
                Container(width: 1, height: 40, color: AppTheme.border,
                  margin: const EdgeInsets.symmetric(horizontal: 16)),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Total Value", style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text("₹${totalCollected.toInt()}", style: const TextStyle(
                    color: AppTheme.accent, fontSize: 20, fontWeight: FontWeight.w800)),
                ])),
              ]),
            ),

            ...docs.map((doc) {
              final d          = doc.data() as Map<String, dynamic>;
              final items      = _parseItems(d['items']);
              final total      = (d['totalAmount'] ?? 0).toDouble();
              final ts         = d['deliveredAt'] as Timestamp?;
              final date       = ts != null
                  ? "${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year} ${ts.toDate().hour}:${ts.toDate().minute.toString().padLeft(2,'0')}"
                  : '—';
              final notes      = d['deliveryNotes'] ?? '';
              final payStatus  = d['paymentStatus'] ?? 'unpaid';

              return AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d['shopName'] ?? '—', style: const TextStyle(
                        color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 3),
                      Text(date, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      const StatusBadge(label: "DELIVERED", color: AppTheme.green),
                      const SizedBox(height: 4),
                      StatusBadge.fromStatus(payStatus),
                    ]),
                  ]),

                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surface2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(children: [
                        const Icon(Icons.notes_outlined, color: AppTheme.textMuted, size: 14),
                        const SizedBox(width: 8),
                        Expanded(child: Text(notes, style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12))),
                      ]),
                    ),
                  ],

                  const AccentDivider(),

                  Text("${items.length} item(s)", style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text("Total", style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    Text("₹${total.toStringAsFixed(2)}", style: const TextStyle(
                      color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 16)),
                  ]),
                ]),
              );
            }),
          ],
        );
      },
    );
  }

  // ── Payments Tab ──────────────────────────────────────────
  Widget _paymentsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('orders')
          .where('distributorId', isEqualTo: widget.uid)
          .where('paymentStatus', isEqualTo: 'paid')
          .orderBy('collectedAt', descending: true)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const AppLoader();
        final docs = snap.data!.docs;

        if (docs.isEmpty) {
          return const AppEmptyState(
            icon: Icons.receipt_long_outlined,
            title: "No Payments Yet",
            subtitle: "Collected payments appear here",
          );
        }

        double total = 0;
        for (var d in docs) {
          final data = d.data() as Map<String, dynamic>;
          total += (data['collectedAmount'] ?? data['totalAmount'] ?? 0).toDouble();
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 24, top: 8),
          children: [
            // Total banner
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.greenGrad,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: [BoxShadow(color: AppTheme.green.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Row(children: [
                const Icon(Icons.savings_outlined, color: Colors.white, size: 28),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Total Collected", style: TextStyle(
                    color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text("₹${total.toStringAsFixed(2)}", style: const TextStyle(
                    color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                ]),
              ]),
            ),

            ...docs.map((doc) {
              final d      = doc.data() as Map<String, dynamic>;
              final amt    = (d['collectedAmount'] ?? d['totalAmount'] ?? 0).toDouble();
              final method = d['paymentMethod'] ?? 'cash';
              final ts     = d['collectedAt'] as Timestamp?;
              final date   = ts != null
                  ? "${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}"
                  : '—';

              return AppCard(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.greenSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      method == 'upi' ? Icons.qr_code_outlined
                      : method == 'credit' ? Icons.credit_card_outlined
                      : Icons.money_outlined,
                      color: AppTheme.green, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d['shopName'] ?? '—', style: const TextStyle(
                      color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 3),
                    Row(children: [
                      Text(method.toUpperCase(), style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      const Text("  ·  ", style: TextStyle(color: AppTheme.textMuted)),
                      Text(date, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    ]),
                  ])),
                  Text("₹${amt.toStringAsFixed(2)}", style: const TextStyle(
                    color: AppTheme.green, fontWeight: FontWeight.w800, fontSize: 16)),
                ]),
              );
            }),
          ],
        );
      },
    );
  }
}