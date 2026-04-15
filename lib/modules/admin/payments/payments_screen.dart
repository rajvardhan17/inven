import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

// 🔥 SAFE WEB IMPORT
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Payments"),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('payments')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text("No Payments Found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, index) {
              final doc = docs[index];
              final payment = (doc.data() ?? {}) as Map<String, dynamic>;

              final amount =
                  (payment["totalAmount"] ?? payment["amount"] ?? 0).toDouble();

              final status = (payment["status"] ?? "unpaid").toString();

              return _paymentCard(context, doc.id, payment, amount, status);
            },
          );
        },
      ),
    );
  }

  // 🔹 PAYMENT CARD
  Widget _paymentCard(BuildContext context, String docId,
      Map<String, dynamic> payment, double amount, String status) {
    final isPaid = status == "paid";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
        ],
      ),
      child: Column(
        children: [

          Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    isPaid ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                child: Icon(
                  Icons.receipt_long,
                  color: isPaid ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment["shopName"] ?? "Unknown Shop",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text("₹${amount.toStringAsFixed(2)}"),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPaid ? Colors.green : Colors.orange,
                  ),
                ),
              ),

              TextButton(
                onPressed: () => _showBill(context, payment),
                child: const Text("View Bill"),
              ),

              if (!isPaid)
                ElevatedButton(
                  onPressed: () =>
                      _handlePayment(context, docId, payment),
                  child: const Text("Pay"),
                ),
            ],
          )
        ],
      ),
    );
  }

  // 🔥 PAYMENT FLOW
  void _handlePayment(
      BuildContext context, String docId, Map<String, dynamic> payment) {

    String method = "cash";
    final total = (payment["totalAmount"] ?? 0).toDouble();
    final upiId = "yourupi@okaxis";

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  const Text("Select Payment Method",
                      style: TextStyle(fontWeight: FontWeight.bold)),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text("Cash"),
                        selected: method == "cash",
                        onSelected: (_) => setState(() => method = "cash"),
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text("UPI"),
                        selected: method == "upi",
                        onSelected: (_) => setState(() => method = "upi"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  if (method == "upi")
                    QrImageView(
                      data: "upi://pay?pa=$upiId&am=$total",
                      size: 150,
                    )
                  else
                    Text(
                      "Collect ₹${total.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () async {
  await FirebaseFirestore.instance.runTransaction((txn) async {
    final paymentRef =
        FirebaseFirestore.instance.collection('payments').doc(docId);

    final orderRef =
        FirebaseFirestore.instance.collection('orders').doc(payment["orderId"]);

    // ✅ UPDATE PAYMENT
    txn.update(paymentRef, {
      "status": "paid",
      "method": method,
      "paidAt": FieldValue.serverTimestamp(),
    });

    // 🔥 SYNC ORDER (THIS FIXES DASHBOARD)
    txn.update(orderRef, {
      "paymentStatus": "paid",
    });
  });

  Navigator.pop(context);
},
                    child: const Text("Confirm Payment"),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 🔥 BILL VIEW (SAFE + CLEAN)
  void _showBill(BuildContext context, Map<String, dynamic> payment) async {
    try {
      final orderId = payment["orderId"];

      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();

      final order = (orderDoc.data() ?? {}) as Map<String, dynamic>;
      final items = List<Map<String, dynamic>>.from(order["items"] ?? []);

      showDialog(
        context: context,
        builder: (_) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Text("Invoice: ${payment["invoiceNo"] ?? ""}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),

                const SizedBox(height: 10),

                ...items.map((item) => ListTile(
                      title: Text(item["productName"]),
                      subtitle: Text(
                          "${item["qty"]} x ₹${item["price"]}"),
                      trailing: Text("₹${item["total"]}"),
                    )),

                const Divider(),

                Text("Total: ₹${order["totalAmount"] ?? 0}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),

                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: () =>
                      _printPDF(order, payment),
                  child: const Text("Print"),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Error loading bill")));
    }
  }

  // 🔥 PDF EXPORT
  Future<void> _printPDF(
      Map<String, dynamic> order, Map<String, dynamic> payment) async {

    final pdf = pw.Document();
    final items = List<Map<String, dynamic>>.from(order["items"] ?? []);

    final fontData =
        await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.Page(
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Invoice: ${payment["invoiceNo"]}",
                style: pw.TextStyle(font: ttf)),

            ...items.map((item) => pw.Text(
                "${item["productName"]} x${item["qty"]} - ₹${item["total"]}",
                style: pw.TextStyle(font: ttf))),

            pw.Divider(),

            pw.Text("Total: ₹${order["totalAmount"]}",
                style: pw.TextStyle(font: ttf)),
          ],
        ),
      ),
    );

    final bytes = await pdf.save();

    if (kIsWeb) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, "_blank");
    } else {
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    }
  }
}