import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/order_data.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderData = Provider.of<OrderData>(context);
    final orders = orderData.orders;

    double totalRevenue = 0;
    double pendingAmount = 0;

    for (var order in orders) {
      final amount = (order["totalAmount"] ?? 0).toDouble();

      if (order["paymentStatus"] == "Paid") {
        totalRevenue += amount;
      } else {
        pendingAmount += amount;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(title: const Text("Payments")),
      body: orders.isEmpty
          ? const Center(child: Text("No Bills Available"))
          : Column(
              children: [
                // 🔥 SUMMARY
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _summaryCard("Revenue", totalRevenue, Colors.green),
                      const SizedBox(width: 10),
                      _summaryCard("Pending", pendingAmount, Colors.orange),
                    ],
                  ),
                ),

                // 🔹 BILL LIST
                Expanded(
                  child: ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (_, index) {
                      final order = orders[index];

                      final shop = order["shop"];
                      final amount = (order["totalAmount"] ?? 0).toDouble();
                      final status = order["paymentStatus"];

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: status == "Paid"
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.orange.withValues(alpha: 0.1),
                                  child: Icon(
                                    Icons.receipt,
                                    color: status == "Paid"
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        shop,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        "₹${amount.toStringAsFixed(2)}",
                                        style:
                                            const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                status == "Paid"
                                    ? const Chip(
                                        label: Text("Paid"),
                                        backgroundColor: Colors.green,
                                        labelStyle:
                                            TextStyle(color: Colors.white),
                                      )
                                    : ElevatedButton(
                                        onPressed: () {
                                          orderData.markPaid(index);
                                        },
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange),
                                        child: const Text("Mark Paid"),
                                      ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // 🔥 VIEW BILL BUTTON
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  _showBill(context, order);
                                },
                                child: const Text("View Bill"),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  // 🔹 BILL POPUP
  void _showBill(BuildContext context, Map<String, dynamic> order) {
    final items = (order["items"] ?? []) as List;
    final subTotal = (order["subTotal"] ?? 0).toDouble();
    final gst = (order["gstAmount"] ?? 0).toDouble();
    final total = (order["totalAmount"] ?? 0).toDouble();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Invoice"),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔥 SHOP HEADER
                const Text(
                  "KHOSHBOOWALA",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text("Wholesale & Retail Store"),
                const Text("Indore, Madhya Pradesh"),
                const SizedBox(height: 10),

                Text("Customer: ${order["shop"]}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),

                const SizedBox(height: 10),

                // 🔹 ITEMS
                ...items.map<Widget>((item) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text("${item["product"]} x${item["qty"]}"),
                      ),
                      Text("₹${item["total"]}"),
                    ],
                  );
                }),

                const Divider(),

                _billRow("Subtotal", subTotal),
                _billRow("GST", gst),
                const SizedBox(height: 5),
                _billRow("Total", total, isBold: true),
              ],
            ),
          ),
        ),

        // 🔥 ACTION BUTTONS
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          ElevatedButton.icon(
            onPressed: () {
              _downloadPDF(order);
            },
            icon: const Icon(Icons.download),
            label: const Text("Download"),
          ),
        ],
      ),
    );
  }

  //DOWNLOAD METHOD
  Future<void> _downloadPDF(Map<String, dynamic> order) async {
    final pdf = pw.Document();

    final items = (order["items"] ?? []) as List;
    final subTotal = (order["subTotal"] ?? 0).toDouble();
    final gst = (order["gstAmount"] ?? 0).toDouble();
    final total = (order["totalAmount"] ?? 0).toDouble();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 🔥 HEADER
              pw.Text("KHOSHBOOWALA",
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Text("Wholesale & Retail Store"),
              pw.Text("Indore, Madhya Pradesh"),

              pw.SizedBox(height: 10),

              pw.Text("Customer: ${order["shop"]}",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),

              pw.SizedBox(height: 10),

              // 🔹 ITEMS
              ...items.map((item) {
                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("${item["product"]} x${item["qty"]}"),
                    pw.Text("₹${item["total"]}"),
                  ],
                );
              }),

              pw.Divider(),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Subtotal"),
                  pw.Text("₹${subTotal.toStringAsFixed(2)}"),
                ],
              ),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("GST"),
                  pw.Text("₹${gst.toStringAsFixed(2)}"),
                ],
              ),

              pw.SizedBox(height: 5),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Total",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text("₹${total.toStringAsFixed(2)}",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          );
        },
      ),
    );

    // 🔥 OPEN SHARE / DOWNLOAD
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  // 🔹 SUMMARY CARD
  Widget _summaryCard(String title, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              "₹${amount.toStringAsFixed(2)}",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 BILL ROW
  Widget _billRow(String label, double amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text("₹${amount.toStringAsFixed(2)}",
            style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}
