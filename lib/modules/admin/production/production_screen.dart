import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/app_theme.dart';

class ProductionScreen extends StatefulWidget {
  const ProductionScreen({super.key});

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? selectedProductId;
  Map<String, dynamic>? selectedProductData;
  final qtyCtrl = TextEditingController();
  bool isLoading = false;

  // ── Produce ───────────────────────────────────────────────
  Future<void> _produce() async {
    if (selectedProductId == null) return _err("Select a product");
    final qty = int.tryParse(qtyCtrl.text) ?? 0;
    if (qty <= 0) return _err("Enter a valid quantity");

    setState(() => isLoading = true);

    try {
      await _db.runTransaction((txn) async {
        final productRef  = _db.collection('products').doc(selectedProductId);
        final productSnap = await txn.get(productRef);

        if (!productSnap.exists) throw Exception("Product not found");

        final productData = productSnap.data()!;
        final recipe      = Map<String, dynamic>.from(productData['recipe'] ?? {});

        if (recipe.isEmpty) throw Exception("Recipe not defined for this product");

        // Check & deduct raw materials
        for (var entry in recipe.entries) {
          final rawQuery = await _db
              .collection('raw_materials')
              .where('name', isEqualTo: entry.key)
              .limit(1)
              .get();

          if (rawQuery.docs.isEmpty) throw Exception("${entry.key} not found in inventory");

          final rawDoc  = rawQuery.docs.first;
          final rawData = rawDoc.data();

          final double available = (rawData['qty'] ?? 0).toDouble();
          final double required  = (entry.value as num).toDouble() * qty;

          if (available < required) {
            throw Exception("Insufficient ${entry.key}: need $required, have $available");
          }

          txn.update(rawDoc.reference, {'qty': FieldValue.increment(-required)});
        }

        // Add product stock
        txn.update(productRef, {'qty': FieldValue.increment(qty)});

        // Log production
        await _db.collection('production_logs').add({
          'productId':   selectedProductId,
          'productName': productData['name'],
          'qty':         qty,
          'createdAt':   FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        _showSuccess("Production complete! $qty units added.");
        qtyCtrl.clear();
        setState(() => selectedProductId = null);
      }
    } catch (e) {
      if (mounted) _err(e.toString().replaceAll("Exception: ", ""));
    }

    if (mounted) setState(() => isLoading = false);
  }

  void _err(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: AppTheme.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(msg),
      ]),
      backgroundColor: AppTheme.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text("Production"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          const SectionHeader(
            title: "New Production Run",
            subtitle: "Select product and quantity to produce",
          ),
          _productSelectorCard(),
          _recipePreview(),
          const SectionHeader(title: "Production Logs", subtitle: "Recent runs"),
          _productionLogs(),
        ],
      ),
    );
  }

  // ── Product Selector ──────────────────────────────────────
  Widget _productSelectorCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _db.collection('products').where('isActive', isEqualTo: true).snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const AppLoader();
              final products = snap.data!.docs;

              return DropdownButtonFormField<String>(
                value: selectedProductId,
                hint: const Text("Choose a product"),
                dropdownColor: AppTheme.surface2,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.factory_outlined, color: AppTheme.textSecondary, size: 18),
                  labelText: "Product",
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                ),
                items: products.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text(data['name'] ?? 'No Name'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedProductId = val;
                    if (val != null) {
                      final doc = products.firstWhere((d) => d.id == val);
                      selectedProductData = doc.data() as Map<String, dynamic>;
                    } else {
                      selectedProductData = null;
                    }
                  });
                },
              );
            },
          ),

          const AccentDivider(),

          TextField(
            controller: qtyCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: "Quantity to Produce",
              prefixIcon: Icon(Icons.numbers_outlined, color: AppTheme.textSecondary, size: 18),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : _produce,
              icon: isLoading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.bg))
                  : const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(isLoading ? "Processing..." : "Start Production"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Recipe Preview ────────────────────────────────────────
  Widget _recipePreview() {
    if (selectedProductData == null) return const SizedBox();

    final recipe = Map<String, dynamic>.from(selectedProductData!['recipe'] ?? {});
    if (recipe.isEmpty) return const SizedBox();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science_outlined, color: AppTheme.accent, size: 18),
              const SizedBox(width: 8),
              const Text("Recipe", style: TextStyle(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
              const Spacer(),
              Text("per unit", style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          ...recipe.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(e.key, style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13))),
                  Text("${e.value}", style: const TextStyle(
                    color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Production Logs ───────────────────────────────────────
  Widget _productionLogs() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('production_logs')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const AppLoader();

        final logs = snap.data!.docs;

        if (logs.isEmpty) {
          return const AppEmptyState(
            icon: Icons.history_outlined,
            title: "No Logs Yet",
            subtitle: "Production runs will appear here",
          );
        }

        return Column(
          children: logs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = data['productName'] ?? 'Unknown';
            final qty  = data['qty'] ?? 0;
            final ts   = data['createdAt'] as Timestamp?;
            final date = ts != null
                ? "${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}"
                : '—';

            return AppCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.accentSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.factory_outlined, color: AppTheme.accent, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        )),
                        const SizedBox(height: 3),
                        Text(date, style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentSoft,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                    ),
                    child: Text("+$qty units", style: const TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    )),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}