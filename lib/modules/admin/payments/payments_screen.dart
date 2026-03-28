import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../data/order_data.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

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
                                      Text(shop,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
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
    final total = (order["totalAmount"] ?? 0).toDouble();
    final upiId = "yourupi@okaxis";

    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Container(
          width: 400,
          height: 550,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("KHOSHBOOWALA",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const Text("Wholesale & Retail Store"),
                      const SizedBox(height: 8),
                      Text("Invoice: ${order["invoiceNo"] ?? "N/A"}"),
                      Text(
                          "Date: ${order["date"]?.toString().split(" ")[0] ?? ""}"),
                      const Divider(),
                      Text("Customer: ${order["shop"]}",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ...items.map<Widget>((item) => Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                  child: Text(
                                      "${item["product"]} x${item["qty"]}")),
                              Text("₹${item["total"]}"),
                            ],
                          )),
                      const Divider(),
                      Text(
                        "Total: ₹${total.toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      const Text("Scan & Pay"),
                      const SizedBox(height: 10),
                      Center(
                        child: QrImageView(
                          data: "upi://pay?pa=$upiId&pn=KHOSHBOOWALA&am=$total",
                          size: 120,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text("UPI ID: $upiId",
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close")),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      _downloadPDF(order);
                    },
                    icon: const Icon(Icons.download),
                    label: const Text("Download"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // 🔥 CLEAN PROFESSIONAL PDF
  Future<void> _downloadPDF(Map<String, dynamic> order) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.notoSansRegular();

    final items = (order["items"] ?? []) as List;
    final subTotal = (order["subTotal"] ?? 0).toDouble();
    final gst = (order["gstAmount"] ?? 0).toDouble();
    final total = (order["totalAmount"] ?? 0).toDouble();

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(24),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("KHOSHBOOWALA",
                style: pw.TextStyle(
                    font: font, fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.Text("Wholesale & Retail Store",
                style: pw.TextStyle(font: font)),
            pw.SizedBox(height: 10),
            pw.Divider(),
            pw.Text("Customer: ${order["shop"]}",
                style:
                    pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 15),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              color: PdfColors.grey300,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Item", style: pw.TextStyle(font: font)),
                  pw.Text("Qty", style: pw.TextStyle(font: font)),
                  pw.Text("Amount", style: pw.TextStyle(font: font)),
                ],
              ),
            ),
            ...items.map((item) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(item["product"], style: pw.TextStyle(font: font)),
                      pw.Text("${item["qty"]}",
                          style: pw.TextStyle(font: font)),
                      pw.Text("₹${item["total"]}",
                          style: pw.TextStyle(font: font)),
                    ],
                  ),
                )),
            pw.Divider(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text("Subtotal: ₹$subTotal",
                      style: pw.TextStyle(font: font)),
                  pw.Text("GST: ₹$gst", style: pw.TextStyle(font: font)),
                  pw.Text("Total: ₹$total",
                      style: pw.TextStyle(
                          font: font, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final bytes = await pdf.save();

    if (kIsWeb) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      html.AnchorElement(href: url)
        ..setAttribute("download", "invoice.pdf")
        ..click();

      html.Url.revokeObjectUrl(url);
    } else {
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    }
  }

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
            Text("₹${amount.toStringAsFixed(2)}",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
