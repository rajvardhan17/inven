import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class PaymentsScreen extends StatelessWidget {
  PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payments")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('payments')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No Payments Found"));
          }

          final payments = snapshot.data!.docs;

          return ListView.builder(
            itemCount: payments.length,
            itemBuilder: (_, index) {
              final doc = payments[index];
              final payment = doc.data() as Map<String, dynamic>;
              final amount = (payment["totalAmount"] ?? payment["amount"] ?? 0).toDouble();
              final status = payment["status"] ?? "unpaid";

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: status == "paid"
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          child: Icon(
                            Icons.receipt,
                            color: status == "paid" ? Colors.green : Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(payment["shopName"] ?? "",
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
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
                              color: status == "paid" ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showBill(context, payment),
                          child: const Text("View Bill"),
                        ),
                        if (status != "paid")
                          ElevatedButton(
                            onPressed: () => _handlePayment(context, doc.id, payment),
                            child: const Text("Pay"),
                          ),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _handlePayment(BuildContext context, String docId, Map<String, dynamic> payment) {
    String method = "cash";
    final total = (payment["totalAmount"] ?? 0).toDouble();
    final upiId = "yourupi@okaxis";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                height: 380,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    Expanded(
                      child: Center(
                        child: method == "upi"
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("Scan & Pay"),
                                  const SizedBox(height: 10),
                                  QrImageView(
                                    data: "upi://pay?pa=$upiId&am=$total",
                                    size: 140,
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("Collect Cash"),
                                  const SizedBox(height: 10),
                                  Text(
                                    "₹${total.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('payments')
                            .doc(docId)
                            .update({
                          "status": "paid",
                          "method": method,
                          "paidAt": FieldValue.serverTimestamp(),
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Confirm Payment"),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showBill(BuildContext context, Map<String, dynamic> payment) async {
  final orderId = payment["orderId"];

  final orderDoc = await FirebaseFirestore.instance
      .collection('orders')
      .doc(orderId)
      .get();

  final order = orderDoc.data() as Map<String, dynamic>;

  final items = List<Map<String, dynamic>>.from(order["items"] ?? []);

  final shopsDoc = await FirebaseFirestore.instance
      .collection('shops')
      .doc(order["shopId"])
      .get();

  final shops = shopsDoc.data() as Map<String, dynamic>;

  final address = shops["address"] as Map<String, dynamic>?;

  final formattedAddress = address != null
      ? "${address["street"] ?? ""}, ${address["city"] ?? ""} ${address["pincode"] ?? ""}"
      : "N/A";

  showDialog(
    context: context,
    builder: (_) => Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🔹 INVOICE HEADER
            Center(
              child: Text(
                "Invoice: ${payment["invoiceNo"] ?? "N/A"}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            // 🔹 SHOP + DATE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Shop: ${order["shopName"] ?? "N/A"}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Date: ${order["date"] != null ? order["date"].toDate().toString().split(" ")[0] : "N/A"}",
                ),
              ],
            ),

            const SizedBox(height: 6),

            // 🔹 OWNER
            Text(
              "Owner: ${shops["ownerName"] ?? "N/A"}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            // 🔹 CONTACT
            Text(
              "Contact: ${shops["phone"] ?? "N/A"}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            // 🔹 ADDRESS
            Text(
              "Address: $formattedAddress",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const Divider(),

            // 🔹 TABLE HEADER
            Row(
              children: const [
                Expanded(child: Text("Item", style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(width: 40),
                Text("Qty", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 40),
                Text("Price", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 40),
                Text("Total", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(height: 6),

            // 🔹 ITEMS
            ...items.map((item) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(item["productName"] ?? "")),
                    const SizedBox(width: 40),
                    Text("${item["qty"] ?? 0}"),
                    const SizedBox(width: 40),
                    Text("₹${item["price"] ?? 0}"),
                    const SizedBox(width: 40),
                    Text("₹${item["total"] ?? 0}"),
                  ],
                )),

            const Divider(),

            // 🔹 TOTALS
            Row(
              children: [
                const Expanded(
                    child: Text("Sub-Total",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Text("₹${order["subTotal"] ?? 0}"),
              ],
            ),

            Row(
              children: [
                const Expanded(
                    child: Text("GST",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Text("₹${order["gstAmount"] ?? 0}"),
              ],
            ),

            Row(
              children: [
                const Expanded(
                    child: Text("Total",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Text(
                  "₹${order["totalAmount"] ?? 0}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 🔹 BUTTONS
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _printPDF(order, payment),
                    child: const Text("Print"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final msg =
                          "Invoice ${payment["invoiceNo"]}\nAmount: ₹${order["totalAmount"]}";
                      final url =
                          "https://wa.me/?text=${Uri.encodeComponent(msg)}";
                      html.window.open(url, "_blank");
                    },
                    child: const Text("WhatsApp"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    ),
  );
}

  Future<void> _printPDF(Map<String, dynamic> order, Map<String, dynamic> payment) async {
    final pdf = pw.Document();
    final items = List<Map<String, dynamic>>.from(order["items"] ?? []);

    // Load a Unicode font (Roboto)
    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.Page(
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Invoice: ${payment["invoiceNo"]}", style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
            pw.Text("Customer: ${order["shopName"]}", style: pw.TextStyle(font: ttf)),
            pw.SizedBox(height: 10),
            // Table headers
            pw.Row(
              children: [
                pw.Expanded(child: pw.Text("Item", style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold))),
                pw.SizedBox(width: 20),
                pw.Text("Qty", style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(width: 20),
                pw.Text("Price", style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(width: 20),
                pw.Text("Total", style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 6),
            ...items.map((item) => pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(child: pw.Text(item["productName"], style: pw.TextStyle(font: ttf))),
                    pw.Text("${item["qty"]}", style: pw.TextStyle(font: ttf)),
                    pw.Text("₹${item["price"]}", style: pw.TextStyle(font: ttf)),
                    pw.Text("₹${item["total"]}", style: pw.TextStyle(font: ttf)),
                  ],
                )),
            pw.Divider(),
            pw.Text("Subtotal: ₹${order["subTotal"]}", style: pw.TextStyle(font: ttf)),
            pw.Text("GST: ₹${order["gstAmount"]}", style: pw.TextStyle(font: ttf)),
            pw.Text("Total: ₹${order["totalAmount"]}", style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
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