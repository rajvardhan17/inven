import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InvoiceService {
  static Future<void> generateInvoice(Map<String, dynamic> order) async {
    final pdf = pw.Document();
    
    // Load font that supports Indian Rupee symbol
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    final items = (order["items"] ?? []) as List;
    final subTotal = (order["subTotal"] ?? 0).toDouble();
    final gstPercent = (order["gstPercent"] ?? 0).toDouble();
    final gstAmount = (order["gstAmount"] ?? 0).toDouble();
    final total = (order["totalAmount"] ?? 0).toDouble();

    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(16),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 🔥 HEADER
              pw.Text("TAX INVOICE",
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

              pw.SizedBox(height: 10),
              pw.Text("Total in Words: ${convertToWords(total.toInt())} Only", style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),

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

  static String convertToWords(int number) {
    if (number == 0) return "Zero";
    
    const units = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"];
    const tens = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"];
    
    String convert(int n) {
      if (n < 20) return units[n];
      if (n < 100) return tens[n ~/ 10] + (n % 10 != 0 ? " ${units[n % 10]}" : "");
      if (n < 1000) return "${units[n ~/ 100]} Hundred${n % 100 != 0 ? " ${convert(n % 100)}" : ""}";
      if (n < 100000) return "${convert(n ~/ 1000)} Thousand${n % 1000 != 0 ? " ${convert(n % 1000)}" : ""}";
      if (n < 10000000) return "${convert(n ~/ 100000)} Lakh${n % 100000 != 0 ? " ${convert(n % 100000)}" : ""}";
      return "${convert(n ~/ 10000000)} Crore${n % 10000000 != 0 ? " ${convert(n % 10000000)}" : ""}";
    }
    
    return "Indian Rupee ${convert(number)}";
  }
}
