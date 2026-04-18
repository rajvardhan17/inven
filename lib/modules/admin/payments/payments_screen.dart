import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../../../core/app_theme.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (!_tabCtrl.indexIsChanging) {
          setState(() {
            switch (_tabCtrl.index) {
              case 0: _filter = 'all'; break;
              case 1: _filter = 'unpaid'; break;
              case 2: _filter = 'paid'; break;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text("Payments"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              Container(height: 1, color: AppTheme.border),
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
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('payments')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const AppLoader();
          if (snapshot.hasError) return const Center(child: Text("Something went wrong", style: TextStyle(color: AppTheme.textSecondary)));

          final all = snapshot.data?.docs ?? [];
          final docs = _filter == 'all'
              ? all
              : all.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return (data['status'] ?? 'unpaid') == _filter;
                }).toList();

          if (docs.isEmpty) {
            return const AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: "No Payments",
              subtitle: "Payment records will appear here",
            );
          }

          // Summary stats
          double totalPaid   = 0;
          double totalUnpaid = 0;
          for (final d in all) {
            final data   = d.data() as Map<String, dynamic>;
            final amt    = (data['totalAmount'] ?? data['amount'] ?? 0).toDouble();
            final status = (data['status'] ?? 'unpaid').toString();
            if (status == 'paid')   totalPaid   += amt;
            if (status == 'unpaid') totalUnpaid += amt;
          }

          return Column(
            children: [
              _summaryStrip(totalPaid, totalUnpaid),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24, top: 8),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final doc     = docs[i];
                    final payment = (doc.data() ?? {}) as Map<String, dynamic>;
                    final amount  = (payment['totalAmount'] ?? payment['amount'] ?? 0).toDouble();
                    final status  = (payment['status'] ?? 'unpaid').toString();
                    return _paymentCard(doc.id, payment, amount, status);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Summary Strip ─────────────────────────────────────────
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
      child: Row(
        children: [
          _summaryItem("Collected", "₹${paid.toInt()}", AppTheme.green, AppTheme.greenSoft),
          Container(width: 1, height: 40, color: AppTheme.border, margin: const EdgeInsets.symmetric(horizontal: 16)),
          _summaryItem("Outstanding", "₹${unpaid.toInt()}", AppTheme.orange, AppTheme.orangeSoft),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color, Color bg) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          )),
        ],
      ),
    );
  }

  // ── Payment Card ──────────────────────────────────────────
  Widget _paymentCard(String docId, Map<String, dynamic> payment, double amount, String status) {
    final isPaid = status == 'paid';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: isPaid ? AppTheme.greenSoft : AppTheme.orangeSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPaid ? Icons.check_circle_outline : Icons.hourglass_top_rounded,
                  color: isPaid ? AppTheme.green : AppTheme.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(payment['shopName'] ?? 'Unknown Shop', style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    )),
                    const SizedBox(height: 3),
                    Text(payment['invoiceNo'] ?? '', style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 11, fontFamily: 'monospace')),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("₹${amount.toStringAsFixed(2)}", style: const TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  )),
                  const SizedBox(height: 4),
                  StatusBadge.fromStatus(status),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showBill(payment),
                  icon: const Icon(Icons.receipt_outlined, size: 16),
                  label: const Text("View Bill"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: const BorderSide(color: AppTheme.border),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                  ),
                ),
              ),
              if (!isPaid) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handlePayment(docId, payment),
                    icon: const Icon(Icons.payment_outlined, size: 16),
                    label: const Text("Collect"),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Payment Flow ──────────────────────────────────────────
  void _handlePayment(String docId, Map<String, dynamic> payment) {
    String method = 'cash';
    final total  = (payment['totalAmount'] ?? 0).toDouble();
    final upiId  = "yourupi@okaxis";

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Collect Payment", style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              )),
              const SizedBox(height: 4),
              Text("₹${total.toStringAsFixed(2)}", style: const TextStyle(
                color: AppTheme.accent,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              )),
              const SizedBox(height: 20),

              // Method chips
              Row(
                children: [
                  _methodChip('cash', 'Cash', Icons.money_outlined, method, (v) => setS(() => method = v)),
                  const SizedBox(width: 10),
                  _methodChip('upi', 'UPI', Icons.qr_code_scanner_outlined, method, (v) => setS(() => method = v)),
                ],
              ),
              const SizedBox(height: 20),

              if (method == 'upi')
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: QrImageView(
                          data: "upi://pay?pa=$upiId&am=$total",
                          size: 140,
                          foregroundColor: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("Scan to pay ₹${total.toStringAsFixed(2)}",
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.greenSoft,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.money_outlined, color: AppTheme.green, size: 28),
                      const SizedBox(height: 8),
                      Text("Collect ₹${total.toStringAsFixed(2)}", style: const TextStyle(
                        color: AppTheme.green,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      )),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance.runTransaction((txn) async {
                      final payRef   = FirebaseFirestore.instance.collection('payments').doc(docId);
                      final orderRef = FirebaseFirestore.instance.collection('orders').doc(payment['orderId']);
                      txn.update(payRef, {
                        'status': 'paid',
                        'method': method,
                        'paidAt': FieldValue.serverTimestamp(),
                      });
                      txn.update(orderRef, {'paymentStatus': 'paid'});
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
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

  Widget _methodChip(String value, String label, IconData icon, String current, Function(String) onChanged) {
    final sel = current == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: sel ? AppTheme.accentSoft : AppTheme.surface2,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: sel ? AppTheme.accent : AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: sel ? AppTheme.accent : AppTheme.textSecondary, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(
              color: sel ? AppTheme.accent : AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }

  // ── Bill View ─────────────────────────────────────────────
  void _showBill(Map<String, dynamic> payment) async {
    try {
      final orderId = payment['orderId'];
      final orderDoc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
      final order = (orderDoc.data() ?? {}) as Map<String, dynamic>;
      final items = List<Map<String, dynamic>>.from(order['items'] ?? []);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.surface,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
        ),
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, sc) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Invoice", style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text(payment['invoiceNo'] ?? '—', style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    StatusBadge.fromStatus(payment['status'] ?? 'unpaid'),
                  ],
                ),
                const AccentDivider(),
                Text(payment['shopName'] ?? '', style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    controller: sc,
                    children: [
                      ...items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(child: Text(
                              "${item['productName']} × ${item['qty']}",
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                            )),
                            Text("₹${item['total']}", style: const TextStyle(
                              color: AppTheme.accent, fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      )),
                      const AccentDivider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total", style: TextStyle(
                            color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                          Text("₹${order['totalAmount'] ?? 0}", style: const TextStyle(
                            color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 20)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _printPDF(order, payment),
                        icon: const Icon(Icons.print_outlined, size: 18),
                        label: const Text("Print Invoice"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error loading bill"), backgroundColor: AppTheme.red));
    }
  }

  // ── PDF Export ────────────────────────────────────────────
  Future<void> _printPDF(Map<String, dynamic> order, Map<String, dynamic> payment) async {
    final pdf   = pw.Document();
    final items = List<Map<String, dynamic>>.from(order['items'] ?? []);
    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    pdf.addPage(pw.Page(
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("Invoice: ${payment['invoiceNo']}", style: pw.TextStyle(font: ttf, fontSize: 20)),
          pw.SizedBox(height: 10),
          pw.Text("Shop: ${payment['shopName']}", style: pw.TextStyle(font: ttf)),
          pw.Divider(),
          ...items.map((item) => pw.Text(
            "${item['productName']} ×${item['qty']}  —  ₹${item['total']}",
            style: pw.TextStyle(font: ttf),
          )),
          pw.Divider(),
          pw.Text("Subtotal: ₹${order['subTotal'] ?? 0}", style: pw.TextStyle(font: ttf)),
          pw.Text("GST: ₹${order['gstAmount'] ?? 0}", style: pw.TextStyle(font: ttf)),
          pw.Text("Total: ₹${order['totalAmount'] ?? 0}",
            style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 16)),
        ],
      ),
    ));

    final bytes = await pdf.save();

    if (kIsWeb) {
      final blob = html.Blob([bytes]);
      final url  = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, "_blank");
    } else {
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    }
  }
}