import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
// ignore: avoid_web_libraries_in_flutter
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import '../../../core/app_theme.dart';
import '../../../core/services/log_service.dart';
import '../../../core/services/auto_notification_engine.dart';

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

  // ── Helpers ───────────────────────────────────────────────

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

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text("Payments"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(97),
          child: Column(children: [
            Container(height: 1, color: AppTheme.border),
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: TextField(
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Search shop or invoice…",
                  prefixIcon: const Icon(Icons.search,
                      color: AppTheme.textSecondary, size: 18),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close,
                              color: AppTheme.textSecondary, size: 16),
                          onPressed: () => setState(() => _search = ''))
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.5),
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
        // ✅ No orderBy — avoids composite index requirement.
        //    Single-field 'timestamp' index is auto-created by Firestore.
        //    We sort client-side.
        stream: FirebaseFirestore.instance
            .collection('payments')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoader();
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}",
                  style: const TextStyle(color: AppTheme.red, fontSize: 13)));
          }

          // Sort client-side descending by createdAt
          final all = (snapshot.data?.docs ?? []).toList()
            ..sort((a, b) {
              final aTs = (a.data() as Map)['createdAt'] as Timestamp?;
              final bTs = (b.data() as Map)['createdAt'] as Timestamp?;
              if (aTs == null && bTs == null) return 0;
              if (aTs == null) return 1;
              if (bTs == null) return -1;
              return bTs.compareTo(aTs);
            });

          // Tab filter
          var docs = _filter == 'all'
              ? all
              : all.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return (data['status'] ?? 'unpaid') == _filter;
                }).toList();

          // Search filter
          if (_search.isNotEmpty) {
            docs = docs.where((d) {
              final data = d.data() as Map<String, dynamic>;
              final shop    = (data['shopName'] ?? '').toString().toLowerCase();
              final invoice = (data['invoiceNo'] ?? '').toString().toLowerCase();
              return shop.contains(_search) || invoice.contains(_search);
            }).toList();
          }

          // Summary stats from ALL docs (not filtered)
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
                  title: "No Payments",
                  subtitle: "Payment records will appear here",
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
                  final doc     = docs[i];
                  final payment = doc.data() as Map<String, dynamic>;
                  final amount  = _toDouble(payment['totalAmount'] ?? payment['amount']);
                  final status  = (payment['status'] ?? 'unpaid').toString();
                  return _PaymentCard(
                    docId:   doc.id,
                    payment: payment,
                    amount:  amount,
                    status:  status,
                    onCollect:  _handlePayment,
                    onViewBill: _showBill,
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
      child: Row(children: [
        _summaryItem("Collected",   "₹${paid.toStringAsFixed(0)}",   AppTheme.green,  AppTheme.greenSoft),
        Container(width: 1, height: 40, color: AppTheme.border,
            margin: const EdgeInsets.symmetric(horizontal: 16)),
        _summaryItem("Outstanding", "₹${unpaid.toStringAsFixed(0)}", AppTheme.orange, AppTheme.orangeSoft),
      ]),
    );
  }

  Widget _summaryItem(String label, String value, Color color, Color bg) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(
          color: color, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      ]),
    );
  }

  // ── Collect payment bottom sheet ──────────────────────────

  void _handlePayment(String docId, Map<String, dynamic> payment) {
    String method = 'cash';
    final total  = _toDouble(payment['totalAmount']);
    const upiId  = "yourupi@okaxis";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2)),
              )),
              const SizedBox(height: 20),
              const Text("Collect Payment", style: TextStyle(
                color: AppTheme.textPrimary, fontSize: 20,
                fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text("₹${total.toStringAsFixed(2)}", style: const TextStyle(
                color: AppTheme.accent, fontSize: 28,
                fontWeight: FontWeight.w900, letterSpacing: -1)),
              if (payment['shopName'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(payment['shopName'], style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
                ),
              const SizedBox(height: 20),

              // Method chips
              Row(children: [
                _methodChip('cash',   'Cash',   Icons.money_outlined,          method, (v) => setS(() => method = v)),
                const SizedBox(width: 8),
                _methodChip('upi',    'UPI',    Icons.qr_code_scanner_outlined, method, (v) => setS(() => method = v)),
                const SizedBox(width: 8),
                _methodChip('credit', 'Credit', Icons.credit_card_outlined,     method, (v) => setS(() => method = v)),
              ]),
              const SizedBox(height: 20),

              // Method body
              if (method == 'upi')
                Center(child: Column(children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                    child: QrImageView(
                      data: "upi://pay?pa=$upiId&am=$total&cu=INR",
                      size: 150,
                      foregroundColor: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text("Scan to pay ₹${total.toStringAsFixed(2)}",
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(upiId, style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 11, fontFamily: 'monospace')),
                ]))
              else if (method == 'credit')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.blueSoft,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.blue.withOpacity(0.3))),
                  child: Column(children: [
                    const Icon(Icons.credit_card_outlined, color: AppTheme.blue, size: 28),
                    const SizedBox(height: 8),
                    Text("Credit ₹${total.toStringAsFixed(2)}", style: const TextStyle(
                      color: AppTheme.blue, fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text("Amount will be recorded as credit",
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ]),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.greenSoft,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.green.withOpacity(0.3))),
                  child: Column(children: [
                    const Icon(Icons.money_outlined, color: AppTheme.green, size: 28),
                    const SizedBox(height: 8),
                    Text("Collect ₹${total.toStringAsFixed(2)}", style: const TextStyle(
                      color: AppTheme.green, fontSize: 20, fontWeight: FontWeight.w800)),
                  ]),
                ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
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

                      // ✅ Log the payment event
                      await LogService.payment(
                        "Payment collected for ${payment['shopName'] ?? 'shop'} — ₹${total.toStringAsFixed(2)} via $method",
                        meta: {
                          'action':    'collected',
                          'paymentId': docId,
                          'orderId':   payment['orderId'],
                          'shopId':    payment['shopId'],
                          'amount':    total,
                          'method':    method,
                          'invoiceNo': payment['invoiceNo'],
                        },
                      );

                      if (ctx.mounted) Navigator.pop(ctx);
                      await AutoNotificationEngine.onPaymentSuccess(
                        orderId: payment['orderId'],
                        amount: total,
                      );
                      _snack("Payment confirmed ✓");
                    } catch (e) {
                      await LogService.error(
                        "Payment failed for ${payment['shopName']}: $e",
                        meta: {'paymentId': docId, 'module': 'payments'},
                      );
                      _snack("Payment failed: $e", isError: true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15)),
                  child: const Text("Confirm Payment"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _methodChip(
    String value, String label, IconData icon,
    String current, ValueChanged<String> onChanged) {
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
            Text(label, style: TextStyle(
              color: sel ? AppTheme.accent : AppTheme.textSecondary,
              fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
          ]),
        ),
      ),
    );
  }

  // ── View Bill ─────────────────────────────────────────────

  void _showBill(Map<String, dynamic> payment) async {
    try {
      final orderId  = payment['orderId'];
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders').doc(orderId).get();
      final order = (orderDoc.data() ?? {}) as Map<String, dynamic>;
      final items = List<Map<String, dynamic>>.from(
        (order['items'] is List) ? order['items'] : []);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.surface,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg))),
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, sc) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2)),
                )),
                const SizedBox(height: 20),

                // Invoice header
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text("INVOICE", style: TextStyle(
                      color: AppTheme.textMuted, fontSize: 10, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text(payment['invoiceNo'] ?? '—', style: const TextStyle(
                      color: AppTheme.accent, fontSize: 17, fontWeight: FontWeight.w800)),
                  ]),
                  StatusBadge.fromStatus(payment['status'] ?? 'unpaid'),
                ]),
                const AccentDivider(),
                Text(payment['shopName'] ?? '—', style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 16),

                // Items list
                Expanded(
                  child: ListView(controller: sc, children: [
                    // Column headers
                    Row(children: const [
                      Expanded(flex: 4, child: Text("PRODUCT", style: TextStyle(
                        color: AppTheme.textMuted, fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w600))),
                      Expanded(flex: 1, child: Text("QTY", style: TextStyle(
                        color: AppTheme.textMuted, fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w600))),
                      Expanded(flex: 2, child: Text("TOTAL", textAlign: TextAlign.right, style: TextStyle(
                        color: AppTheme.textMuted, fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w600))),
                    ]),
                    const SizedBox(height: 8),
                    const Divider(color: AppTheme.border, height: 1),

                    ...items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(children: [
                        Expanded(flex: 4, child: Text(item['productName'] ?? '—',
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
                        Expanded(flex: 1, child: Text("×${item['qty'] ?? 0}",
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
                        Expanded(flex: 2, child: Text(
                          "₹${_toDouble(item['total']).toStringAsFixed(2)}",
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w600))),
                      ]),
                    )),

                    const AccentDivider(),

                    // Billing rows
                    _billRow("Subtotal", "₹${_toDouble(order['subTotal']).toStringAsFixed(2)}", false),
                    const SizedBox(height: 6),
                    _billRow(
                      "GST (${_toDouble(order['gstPercent']).toStringAsFixed(0)}%)",
                      "₹${_toDouble(order['gstAmount']).toStringAsFixed(2)}",
                      false),
                    const AccentDivider(),
                    _billRow(
                      "Grand Total",
                      "₹${_toDouble(order['totalAmount']).toStringAsFixed(2)}",
                      true),

                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: () => _printPDF(order, payment),
                      icon: const Icon(Icons.print_outlined, size: 18),
                      label: const Text("Print / Download PDF"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      _snack("Error loading bill", isError: true);
      await LogService.error(
        "Failed to load bill for payment: $e",
        meta: {'module': 'payments'},
      );
    }
  }

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

  // ── PDF Export ────────────────────────────────────────────

  Future<void> _printPDF(
    Map<String, dynamic> order,
    Map<String, dynamic> payment,
  ) async {
    try {
      final pdf   = pw.Document();
      final items = List<Map<String, dynamic>>.from(order['items'] ?? []);
      final date  = DateTime.now();

      final subtotal = _toDouble(order['subTotal']);
      final gstAmt   = _toDouble(order['gstAmount']);
      final gstPct   = _toDouble(order['gstPercent']);
      final total    = _toDouble(order['totalAmount']);

      final font     = await PdfGoogleFonts.notoSansRegular();
      final fontBold = await PdfGoogleFonts.notoSansBold();

      pdf.addPage(pw.Page(
        margin: const pw.EdgeInsets.all(28),
        build: (_) => pw.DefaultTextStyle(
          style: pw.TextStyle(font: font, fontSize: 11),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(child: pw.Text(
                "KHUSHBOOWALA",
                style: pw.TextStyle(font: fontBold, fontSize: 22),
              )),
              pw.SizedBox(height: 4),
              pw.Center(child: pw.Text(
                "Tax Invoice",
                style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey600),
              )),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 10),

              // Invoice meta
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Invoice No: ${payment['invoiceNo'] ?? '-'}",
                    style: pw.TextStyle(font: fontBold)),
                  pw.Text("Date: ${date.day}/${date.month}/${date.year}"),
                ],
              ),
              pw.SizedBox(height: 10),

              // Shop info
              pw.Text("Shop: ${payment['shopName'] ?? ''}"),
              if ((order['shopPhone'] ?? '').toString().isNotEmpty)
                pw.Text("Phone: ${order['shopPhone']}"),
              if ((order['shopAddress'] ?? '').toString().isNotEmpty)
                pw.Text("Address: ${order['shopAddress']}"),

              pw.SizedBox(height: 14),
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),

              // Table header
              pw.SizedBox(height: 6),
              pw.Row(children: [
                pw.Expanded(child: pw.Text("Item", style: pw.TextStyle(font: fontBold))),
                pw.SizedBox(width: 40, child: pw.Text("Qty", style: pw.TextStyle(font: fontBold))),
                pw.SizedBox(width: 65, child: pw.Text("Price", style: pw.TextStyle(font: fontBold))),
                pw.SizedBox(width: 65, child: pw.Text("Total", style: pw.TextStyle(font: fontBold))),
              ]),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),

              // Items
              ...items.map((item) {
                final name  = item['productName'] ?? '';
                final qty   = item['qty'] ?? 0;
                final price = _toDouble(item['price']);
                final itotal= _toDouble(item['total']);
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(children: [
                    pw.Expanded(child: pw.Text(name)),
                    pw.SizedBox(width: 40, child: pw.Text("$qty")),
                    pw.SizedBox(width: 65, child: pw.Text("Rs ${price.toStringAsFixed(2)}")),
                    pw.SizedBox(width: 65, child: pw.Text("Rs ${itotal.toStringAsFixed(2)}")),
                  ]),
                );
              }),

              pw.SizedBox(height: 6),
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.SizedBox(height: 8),

              // Totals
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("Subtotal:   Rs ${subtotal.toStringAsFixed(2)}"),
                    pw.Text("GST (${gstPct.toStringAsFixed(0)}%):   Rs ${gstAmt.toStringAsFixed(2)}"),
                    pw.SizedBox(height: 6),
                    pw.Text("Total:   Rs ${total.toStringAsFixed(2)}",
                      style: pw.TextStyle(font: fontBold, fontSize: 14)),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Center(child: pw.Text(
                "Thank you for your business!",
                style: pw.TextStyle(color: PdfColors.grey600, fontSize: 11),
              )),
            ],
          ),
        ),
      ));

      final bytes = await pdf.save();

if (kIsWeb) {
  await Printing.sharePdf(
    bytes: bytes,
    filename: 'invoice.pdf',
  );
} else {
  await Printing.layoutPdf(
    onLayout: (format) async => bytes,
  );
}

      await LogService.payment(
        "Invoice printed: ${payment['invoiceNo']}",
        meta: {
          'action':    'printed',
          'invoiceNo': payment['invoiceNo'],
          'shopName':  payment['shopName'],
        },
      );
    } catch (e) {
      _snack("PDF failed: $e", isError: true);
      await LogService.error("PDF generation failed: $e",
          meta: {'module': 'payments'});
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PAYMENT CARD  (extracted widget for clean build method)
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> payment;
  final double amount;
  final String status;
  final void Function(String, Map<String, dynamic>) onCollect;
  final void Function(Map<String, dynamic>) onViewBill;
  final void Function(String, {bool isError}) snack;

  const _PaymentCard({
    required this.docId,
    required this.payment,
    required this.amount,
    required this.status,
    required this.onCollect,
    required this.onViewBill,
    required this.snack,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid  = status == 'paid';
    final method  = payment['method']?.toString();
    final ts      = payment['createdAt'] as Timestamp?;
    final date    = ts != null
        ? "${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}"
        : '—';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            // Status icon
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

            // Shop + invoice
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment['shopName'] ?? 'Unknown Shop', style: const TextStyle(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 3),
                Row(children: [
                  Text(payment['invoiceNo'] ?? '—', style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 11, fontFamily: 'monospace')),
                  const Text("  ·  ", style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  Text(date, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ]),
              ],
            )),

            // Amount + badge
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text("₹${amount.toStringAsFixed(2)}", style: const TextStyle(
                color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 5),
              StatusBadge.fromStatus(status),
            ]),
          ]),

          // Payment method pill (if paid)
          if (isPaid && method != null) ...[
            const SizedBox(height: 10),
            _methodPill(method),
          ],

          const SizedBox(height: 12),

          // Action buttons
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onViewBill(payment),
                icon: const Icon(Icons.receipt_outlined, size: 16),
                label: const Text("View Bill"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: AppTheme.border),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm))),
              ),
            ),
            if (!isPaid) ...[
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onCollect(docId, payment),
                  icon: const Icon(Icons.payment_outlined, size: 16),
                  label: const Text("Collect"),
                ),
              ),
            ],
          ]),
        ],
      ),
    );
  }

  Widget _methodPill(String method) {
    IconData icon;
    Color color;
    switch (method) {
      case 'upi':    icon = Icons.qr_code_outlined;      color = AppTheme.purple; break;
      case 'credit': icon = Icons.credit_card_outlined;  color = AppTheme.blue;   break;
      default:       icon = Icons.money_outlined;        color = AppTheme.green;  break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 5),
        Text(method.toUpperCase(), style: TextStyle(
          color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ]),
    );
  }
}