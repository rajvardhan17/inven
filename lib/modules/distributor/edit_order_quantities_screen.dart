import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/app_theme.dart';
import '../admin/invoices/presentation/screens/invoice_detail_screen.dart';
import '../../../models/invoice_model.dart';

class EditOrderQuantitiesScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const EditOrderQuantitiesScreen({
    super.key,
    required this.orderId,
    required this.orderData,
  });

  @override
  State<EditOrderQuantitiesScreen> createState() => _EditOrderQuantitiesScreenState();
}

class _EditOrderQuantitiesScreenState extends State<EditOrderQuantitiesScreen> {
  late List<Map<String, dynamic>> items;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final rawItems = widget.orderData['items'];
    if (rawItems is List) {
      items = rawItems.map((e) => Map<String, dynamic>.from(e)).toList();
    } else if (rawItems is Map) {
      items = rawItems.values.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      items = [];
    }
  }

  double get subTotal => items.fold(0.0, (s, i) => s + ((i['qty'] ?? 0) * (i['price'] ?? 0)));
  double get totalCgst => items.fold(0.0, (s, i) {
    final base = (i['qty'] ?? 0) * (i['price'] ?? 0);
    return s + (base * (i['cgstPercent'] ?? 2.5) / 100);
  });
  double get totalSgst => items.fold(0.0, (s, i) {
    final base = (i['qty'] ?? 0) * (i['price'] ?? 0);
    return s + (base * (i['sgstPercent'] ?? 2.5) / 100);
  });
  double get grandTotal => subTotal + totalCgst + totalSgst;

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      final db = FirebaseFirestore.instance;
      await db.runTransaction((txn) async {
        final orderRef = db.collection('orders').doc(widget.orderId);
        
        // Update order items and totals
        txn.update(orderRef, {
          'items': items,
          'subTotal': subTotal,
          'cgstAmount': totalCgst,
          'sgstAmount': totalSgst,
          'totalAmount': grandTotal,
          'isEdited': true,
          'editedAt': FieldValue.serverTimestamp(),
        });

        // Also update the associated payment/invoice record if it exists
        final paySnap = await txn.get(db.collection('payments').doc(widget.orderId));
        if (paySnap.exists) {
          txn.update(paySnap.reference, {
            'items': items,
            'subTotal': subTotal,
            'cgstAmount': totalCgst,
            'sgstAmount': totalSgst,
            'totalAmount': grandTotal,
          });
        }
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order updated successfully'), backgroundColor: AppTheme.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Adjust Quantities'),
        actions: [
          if (!_isSaving)
            TextButton(
              onPressed: _saveChanges,
              child: const Text('SAVE', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _isSaving 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return AppCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((item['productName'] ?? 'Product').toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('Price: ₹${item['price']}', style: const TextStyle(color: AppTheme.textSecondary)),
                        const Spacer(),
                        _qtyAction(Icons.remove, () {
                          if (items[index]['qty'] > 0) {
                            setState(() => items[index]['qty']--);
                          }
                        }),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('${items[index]['qty']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        _qtyAction(Icons.add, () {
                          setState(() => items[index]['qty']++);
                        }),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('New Total:', style: TextStyle(color: AppTheme.textSecondary)),
            Text('₹${grandTotal.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.accent, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _qtyAction(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Icon(icon, color: AppTheme.accent, size: 20),
      ),
    );
  }
}
