import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/app_theme.dart';
import '../../../core/services/log_service.dart';
import '../../../core/services/auto_notification_engine.dart';
import '../../admin/invoices/presentation/screens/invoice_detail_screen.dart';
import '../../../models/invoice_model.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _filter = 'all';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (!_tabCtrl.indexIsChanging) {
          setState(() {
            switch (_tabCtrl.index) {
              case 0: _filter = 'all';    break;
              case 1: _filter = 'unpaid'; break;
              case 2: _filter = 'paid';   break;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text("Payments & Receipts"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(97),
          child: Column(children: [
            Container(height: 1, color: AppTheme.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: TextField(
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Search shop or invoice…",
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
              labelColor: AppTheme.accent,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.accent,
              indicatorWeight: 2,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5),
              tabs: const [
                Tab(text: "ALL"),
                Tab(text: "UNPAID"),
                Tab(text: "PAID"),
              ],
            ),
          ]),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('payments').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoader();
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: AppTheme.red, fontSize: 13)));
          }

          final all = (snapshot.data?.docs ?? []).toList()
            ..sort((a, b) {
              final aTs = (a.data() as Map)['createdAt'] as Timestamp?;
              final bTs = (b.data() as Map)['createdAt'] as Timestamp?;
              if (aTs == null && bTs == null) return 0;
              if (aTs == null) return 1;
              if (bTs == null) return -1;
              return bTs.compareTo(aTs);
            });

          var docs = _filter == 'all'
              ? all
              : all.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return (data['status'] ?? 'unpaid') == _filter;
                }).toList();

          if (_search.isNotEmpty) {
            docs = docs.where((d) {
              final data = d.data() as Map<String, dynamic>;
              final shop = (data['shopName'] ?? '').toString().toLowerCase();
              final invoice = (data['invoiceNo'] ?? '').toString().toLowerCase();
              return shop.contains(_search) || invoice.contains(_search);
            }).toList();
          }

          double totalPaid   = 0;
          double totalUnpaid = 0;
          for (final d in all) {
            final data   = d.data() as Map<String, dynamic>;
            final amt    = _toDouble(data['totalAmount'] ?? data['amount']);
            final status = (data['status'] ?? 'unpaid').toString();
            if (status == 'paid')   totalPaid   += amt;
            if (status == 'unpaid') totalUnpaid += amt;
          }

          if (docs.isEmpty) {
            return Column(children: [
              _summaryStrip(totalPaid, totalUnpaid),
              const Expanded(
                child: AppEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: "No Payments Found",
                  subtitle: "Your payment records will appear here",
                ),
              ),
            ]);
          }

          return Column(children: [
            _summaryStrip(totalPaid, totalUnpaid),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 32, top: 4),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final doc = docs[i];
                  return _PaymentCard(
                    invoice: InvoiceModel.fromFirestore(doc),
                    onCollect:  _handlePayment,
                    onViewBill: (inv) => Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoice: inv))),
                    snack:      _snack,
                  );
                },
              ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _summaryStrip(double paid, double unpaid) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(children: [
        _summaryItem("Collected", "₹${paid.toStringAsFixed(0)}", AppTheme.green, AppTheme.greenSoft),
        Container(width: 1, height: 40, color: AppTheme.border, margin: const EdgeInsets.symmetric(horizontal: 16)),
        _summaryItem("Outstanding", "₹${unpaid.toStringAsFixed(0)}", AppTheme.orange, AppTheme.orangeSoft),
      ]),
    );
  }

  Widget _summaryItem(String label, String value, Color color, Color bg) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      ]),
    );
  }

  void _handlePayment(InvoiceModel invoice) {
    String method = 'cash';
    final total = invoice.totalAmount;
    const upiId = "khushboowala@okaxis";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text("Collect Payment", style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text("₹${total.toStringAsFixed(2)}", style: const TextStyle(color: AppTheme.accent, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(invoice.customerName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ),
              const SizedBox(height: 20),

              Row(children: [
                _methodChip('cash', 'Cash', Icons.money_outlined, method, (v) => setS(() => method = v)),
                const SizedBox(width: 8),
                _methodChip('upi', 'UPI', Icons.qr_code_scanner_outlined, method, (v) => setS(() => method = v)),
                const SizedBox(width: 8),
                _methodChip('credit', 'Credit', Icons.credit_card_outlined, method, (v) => setS(() => method = v)),
              ]),
              const SizedBox(height: 20),

              if (method == 'upi')
                Center(child: Column(children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                    child: QrImageView(data: "upi://pay?pa=$upiId&am=$total&cu=INR", size: 150, foregroundColor: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Text("Scan to pay ₹${total.toStringAsFixed(2)}", style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ]))
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: method == 'credit' ? AppTheme.blueSoft : AppTheme.greenSoft,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: (method == 'credit' ? AppTheme.blue : AppTheme.green).withOpacity(0.3))),
                  child: Column(children: [
                    Icon(method == 'credit' ? Icons.credit_card_outlined : Icons.money_outlined, color: method == 'credit' ? AppTheme.blue : AppTheme.green, size: 28),
                    const SizedBox(height: 8),
                    Text(method == 'credit' ? "Record Credit" : "Collect Cash", style: TextStyle(color: method == 'credit' ? AppTheme.blue : AppTheme.green, fontSize: 20, fontWeight: FontWeight.w800)),
                  ]),
                ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await FirebaseFirestore.instance.runTransaction((txn) async {
                        final payRef = FirebaseFirestore.instance.collection('payments').doc(invoice.id);
                        txn.update(payRef, {
                          'status': 'paid',
                          'method': method,
                          'paidAt': FieldValue.serverTimestamp(),
                        });
                        if (invoice.orderId != null) {
                          txn.update(FirebaseFirestore.instance.collection('orders').doc(invoice.orderId), {'paymentStatus': 'paid'});
                        }
                      });

                      await LogService.payment("Payment collected for ${invoice.customerName} — ₹${total.toStringAsFixed(2)} via $method");

                      if (ctx.mounted) Navigator.pop(ctx);
                      await AutoNotificationEngine.onPaymentSuccess(orderId: invoice.orderId ?? '', amount: total);
                      _snack("Payment confirmed ✓");
                    } catch (e) {
                      _snack("Payment failed: $e", isError: true);
                    }
                  },
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                  child: const Text("Confirm Payment"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _methodChip(String value, String label, IconData icon, String current, ValueChanged<String> onChanged) {
    final sel = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: sel ? AppTheme.accentSoft : AppTheme.surface2,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: sel ? AppTheme.accent : AppTheme.border)),
          child: Column(children: [
            Icon(icon, color: sel ? AppTheme.accent : AppTheme.textSecondary, size: 18),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: sel ? AppTheme.accent : AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final InvoiceModel invoice;
  final void Function(InvoiceModel) onCollect;
  final void Function(InvoiceModel) onViewBill;
  final void Function(String, {bool isError}) snack;

  const _PaymentCard({
    required this.invoice,
    required this.onCollect,
    required this.onViewBill,
    required this.snack,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = invoice.status == InvoiceStatus.paid;
    final date = "${invoice.date.day}/${invoice.date.month}/${invoice.date.year}";

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isPaid ? AppTheme.greenSoft : AppTheme.orangeSoft,
                borderRadius: BorderRadius.circular(10)),
              child: Icon(
                isPaid ? Icons.check_circle_outline : Icons.hourglass_top_rounded,
                color: isPaid ? AppTheme.green : AppTheme.orange,
                size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invoice.customerName, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 3),
                Row(children: [
                  Text(invoice.invoiceNo, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontFamily: 'monospace')),
                  const Text("  ·  ", style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  Text(date, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ]),
              ],
            )),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text("₹${invoice.totalAmount.toStringAsFixed(2)}", style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 4),
              StatusBadge.fromStatus(isPaid ? 'paid' : 'unpaid'),
            ]),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => onViewBill(invoice),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
              child: const Text("View Bill"),
            )),
            if (!isPaid) ...[
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () => onCollect(invoice),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                child: const Text("Collect"),
              )),
            ],
          ]),
        ],
      ),
    );
  }
}