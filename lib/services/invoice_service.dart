import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InvoiceService {
  static Future<void> generateInvoice(Map<String, dynamic> order) async {
    final pdf = pw.Document();

    final items = (order["items"] ?? []) as List;
    final subTotal = (order["subTotal"] ?? 0).toDouble();
    final gstPercent = (order["gstPercent"] ?? 0).toDouble();
    final gstAmount = (order["gstAmount"] ?? 0).toDouble();
    final total = (order["totalAmount"] ?? 0).toDouble();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(16),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 🔥 HEADER
              pw.Text("INVOICE",
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),

              pw.SizedBox(height: 10),

              pw.Text("Shop: ${order["shop"]}"),
              pw.Text("Date: ${order["date"] ?? ""}"),

              pw.SizedBox(height: 20),

              // 🔹 ITEMS TABLE
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      _cell("Product", isHeader: true),
                      _cell("Qty", isHeader: true),
                      _cell("Price", isHeader: true),
                      _cell("Total", isHeader: true),
                    ],
                  ),
                  ...items.map<pw.TableRow>((item) {
                    return pw.TableRow(
                      children: [
                        _cell(item["product"].toString()),
                        _cell(item["qty"].toString()),
                        _cell("₹${item["price"]}"),
                        _cell("₹${item["total"]}"),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 20),

              // 🔹 TOTALS
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("Subtotal: ₹${subTotal.toStringAsFixed(2)}"),
                    pw.Text(
                        "GST (${gstPercent.toStringAsFixed(0)}%): ₹${gstAmount.toStringAsFixed(2)}"),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      "Total: ₹${total.toStringAsFixed(2)}",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              pw.Text(
                "Payment Status: ${order["paymentStatus"]}",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );

    // 🔥 OPEN / PRINT / DOWNLOAD
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  static pw.Widget _cell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
