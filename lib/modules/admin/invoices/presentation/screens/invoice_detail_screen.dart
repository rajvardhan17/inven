import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inven/core/app_theme.dart';
import 'package:inven/models/invoice_model.dart';
import 'package:inven/services/invoice_service.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final InvoiceModel invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  bool _isProcessing = false;

  Future<void> _recordPayment() async {
    setState(() => _isProcessing = true);
    try {
      final db = FirebaseFirestore.instance;
      await db.runTransaction((txn) async {
        final payRef = db.collection('payments').doc(widget.invoice.id);
        
        txn.update(payRef, {
          'status': 'paid',
          'paidAt': FieldValue.serverTimestamp(),
          'method': 'cash', // Default for now
        });

        if (widget.invoice.orderId != null) {
          final orderRef = db.collection('orders').doc(widget.invoice.orderId);
          txn.update(orderRef, {'paymentStatus': 'paid'});
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded successfully!'), backgroundColor: AppTheme.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;

    return AppScaffold(
      title: 'TAX INVOICE',
      actions: [
        IconButton(
          onPressed: () {
            InvoiceService.generateInvoice({
              "shop": invoice.customerName,
              "date": invoice.date.toString().split(' ')[0],
              "items": invoice.items.map((e) => {
                "product": e.description,
                "qty": e.quantity,
                "price": e.rate,
                "total": e.totalAmount,
              }).toList(),
              "subTotal": invoice.subTotal,
              "gstPercent": 5.0,
              "gstAmount": invoice.totalCgst + invoice.totalSgst,
              "totalAmount": invoice.totalAmount,
              "paymentStatus": _getStatusString(invoice.status),
            });
          },
          icon: const Icon(Icons.print, color: AppTheme.accent),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Invoice Document
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER ---
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCompanyLogo(),
                        const SizedBox(width: 16),
                        _buildCompanyInfo(),
                        const Spacer(),
                        const Text(
                          'TAX INVOICE',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 28,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- SUB-HEADER ---
                  _buildSubHeader(invoice),

                  // --- BILL TO ---
                  _buildBillToSection(invoice),

                  // --- ITEMS TABLE ---
                  _buildInvoiceTable(invoice),

                  // --- SUMMARY & FOOTER ---
                  _buildSummarySection(invoice),

                  const SizedBox(height: 40),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment Action Button
            if (invoice.status != InvoiceStatus.paid)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _recordPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: AppTheme.bg,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                  ),
                  child: _isProcessing 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('CONFIRM PAYMENT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Center(
        child: Icon(Icons.eco_outlined, color: Color(0xFFC5A358), size: 40),
      ),
    );
  }

  Widget _buildCompanyInfo() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('KhushbooWala', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text('483, SHYAM NAGAR MAIN\nSukhliya\nIndore Madhya Pradesh 452010\nIndia', 
          style: TextStyle(color: Colors.black87, fontSize: 11, height: 1.3)),
        SizedBox(height: 4),
        Text('7000822897\nkhushboowala12@gmail.com\nGSTIN: 23CAJPT0734M1ZF', 
          style: TextStyle(color: Colors.black87, fontSize: 11, height: 1.3)),
      ],
    );
  }

  Widget _buildSubHeader(InvoiceModel invoice) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoGrid([
              ['#', invoice.invoiceNo],
              ['Invoice Date', invoice.date.toString().split(' ')[0]],
              ['Terms', 'Due on Receipt'],
              ['Due Date', invoice.dueDate.toString().split(' ')[0]],
            ]),
          ),
          Container(width: 1, height: 60, color: Colors.grey.shade300),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _buildInfoGrid([
                ['Place Of Supply', invoice.placeOfSupply ?? 'Madhya Pradesh (23)'],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillToSection(InvoiceModel invoice) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bill To', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(invoice.customerName, style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
          if (invoice.customerAddress != null)
            Text(invoice.customerAddress!, style: const TextStyle(color: Colors.black87, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInvoiceTable(InvoiceModel invoice) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(30),
        1: FlexColumnWidth(4),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(1.5),
        4: FlexColumnWidth(1.5),
        5: FlexColumnWidth(3), // Combined % and Amt
        6: FlexColumnWidth(3), // Combined % and Amt
        7: FlexColumnWidth(2),
      },
      border: TableBorder.all(color: Colors.grey.shade300),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: [
            _headerCell('#'),
            _headerCell('Item & Description'),
            _headerCell('HSN\n/SAC'),
            _headerCell('Qty'),
            _headerCell('Rate'),
            _headerCell('CGST (2.5%)'),
            _headerCell('SGST (2.5%)'),
            _headerCell('Amount'),
          ],
        ),
        ...List.generate(invoice.items.length, (index) {
          final item = invoice.items[index];
          return TableRow(
            children: [
              _dataCell('${index + 1}'),
              _dataCell(item.description),
              _dataCell(item.hsn),
              _dataCell('${item.quantity}\npcs'),
              _dataCell(item.rate.toStringAsFixed(2)),
              _dataCell(item.cgstAmount.toStringAsFixed(2)),
              _dataCell(item.sgstAmount.toStringAsFixed(2)),
              _dataCell(item.totalAmount.toStringAsFixed(2), align: TextAlign.right, isBold: true),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildSummarySection(InvoiceModel invoice) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total In Words', style: TextStyle(color: Colors.grey, fontSize: 10)),
                Text('${InvoiceService.convertToWords(invoice.totalAmount.toInt())} Only', 
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11, fontStyle: FontStyle.italic)),
                const SizedBox(height: 20),
                const Text('Notes', style: TextStyle(color: Colors.grey, fontSize: 10)),
                const Text('Thanks for your business.', style: TextStyle(color: Colors.black87, fontSize: 11)),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
            child: Column(
              children: [
                _buildSummaryRow('Sub Total', '₹${invoice.subTotal.toStringAsFixed(2)}'),
                _buildSummaryRow('CGST (2.5%)', '₹${invoice.totalCgst.toStringAsFixed(2)}'),
                _buildSummaryRow('SGST (2.5%)', '₹${invoice.totalSgst.toStringAsFixed(2)}'),
                _buildSummaryRow('Total', '₹${invoice.totalAmount.toStringAsFixed(2)}', isTotal: true),
                _buildSummaryRow('Payment Made', '(-) ₹${invoice.paymentMade.toStringAsFixed(2)}', isNegative: true),
                _buildSummaryRow('Balance Due', '₹${invoice.balanceDue.toStringAsFixed(2)}', isBold: true),
                const SizedBox(height: 40),
                const Center(child: Text('Authorized Signature', style: TextStyle(color: Colors.black54, fontSize: 10))),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String text) {
    return Container(
      padding: const EdgeInsets.all(4),
      alignment: Alignment.center,
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 9)),
    );
  }

  Widget _dataCell(String text, {TextAlign align = TextAlign.center, bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.all(6),
      alignment: _getAlignment(align),
      child: Text(text, textAlign: align, style: TextStyle(color: Colors.black87, fontSize: 10, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
    );
  }

  Alignment _getAlignment(TextAlign align) {
    if (align == TextAlign.right) return Alignment.centerRight;
    if (align == TextAlign.left) return Alignment.centerLeft;
    return Alignment.center;
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false, bool isBold = false, bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isTotal ? Colors.black : Colors.grey, fontSize: 11, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(
            color: isNegative ? Colors.red : Colors.black, 
            fontWeight: (isTotal || isBold) ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 13 : 11,
          )),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(List<List<String>> data) {
    return Column(
      children: data.map((pair) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(width: 80, child: Text(pair[0], style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))),
            const Text(':', style: TextStyle(color: Colors.black, fontSize: 10)),
            const SizedBox(width: 8),
            Expanded(child: Text(pair[1], style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold))),
          ],
        ),
      )).toList(),
    );
  }

  String _getStatusString(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid: return 'Paid';
      case InvoiceStatus.pending: return 'Pending';
      case InvoiceStatus.overdue: return 'Overdue';
      case InvoiceStatus.sent: return 'Sent';
      default: return 'Draft';
    }
  }
}
