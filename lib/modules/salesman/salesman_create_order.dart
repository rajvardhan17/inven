import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/app_theme.dart';

class SalesmanCreateOrder extends StatefulWidget {
  final String uid;
  final List<Map<String, dynamic>> shops;
  final List<Map<String, dynamic>> products;

  const SalesmanCreateOrder({
    super.key,
    required this.uid,
    required this.shops,
    required this.products,
  });

  @override
  State<SalesmanCreateOrder> createState() => _SalesmanCreateOrderState();
}

class _SalesmanCreateOrderState extends State<SalesmanCreateOrder> {
  String? shopId;
  String? productId;
  final qtyCtrl   = TextEditingController(text: '1');
  final priceCtrl = TextEditingController();
  final gstCtrl   = TextEditingController(text: '18');
  List<Map<String, dynamic>> items = [];
  bool saving = false;

  Map<String, dynamic>? get selProduct {
    try { return widget.products.firstWhere((p) => p['id'] == productId); }
    catch (_) { return null; }
  }

  double get sub      => items.fold(0.0, (s, i) => s + (i['total'] as double));
  double get gstPct   => double.tryParse(gstCtrl.text) ?? 0;
  double get gstAmt   => (sub * gstPct) / 100;
  double get grand    => sub + gstAmt;

  void _addItem() {
    if (selProduct == null) return _err("Select a product");
    final qty   = int.tryParse(qtyCtrl.text) ?? 0;
    final price = double.tryParse(priceCtrl.text) ?? 0;
    if (qty <= 0 || price <= 0) return _err("Enter valid qty & price");
    setState(() {
      items.add({
        'productId':   productId,
        'productName': selProduct!['name'] ?? 'Item',
        'qty':   qty,
        'price': price,
        'total': qty * price,
      });
      qtyCtrl.text = '1';
    });
  }

  Future<void> _submitOrder() async {
    if (shopId == null) return _err("Select a shop");
    if (items.isEmpty) return _err("Add at least one item");
    setState(() => saving = true);

    try {
      final shop = widget.shops.firstWhere((s) => s['id'] == shopId);
      await FirebaseFirestore.instance.collection('orders').add({
        'shopId':        shopId,
        'shopName':      shop['shopName'] ?? shop['name'] ?? '—',
        'salesmanId':    widget.uid,
        'items':         items,
        'subTotal':      sub,
        'gstPercent':    gstPct,
        'gstAmount':     gstAmt,
        'totalAmount':   grand,
        'status':        'pending',
        'paymentStatus': 'unpaid',
        'createdAt':     FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Order submitted!"),
          backgroundColor: AppTheme.green,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      _err("Failed to submit order");
    }
    if (mounted) setState(() => saving = false);
  }

  void _err(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: AppTheme.red,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text("Create Order"),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border)),
      ),
      bottomNavigationBar: _bottomBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SectionHeader(title: "Select Shop"),
          _shopPicker(),
          const SectionHeader(title: "Add Products"),
          _productPicker(),
          if (items.isNotEmpty) ...[
            SectionHeader(title: "Items", subtitle: "${items.length} added"),
            _itemsList(),
          ],
          const SectionHeader(title: "Summary"),
          _summary(),
        ],
      ),
    );
  }

  Widget _shopPicker() {
    return AppCard(
      child: DropdownButtonFormField<String>(
        value: shopId,
        hint: const Text("Choose a shop"),
        dropdownColor: AppTheme.surface2,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.storefront_outlined, color: AppTheme.textSecondary, size: 18),
          labelText: "Shop", border: InputBorder.none, enabledBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        ),
        items: widget.shops.map((s) => DropdownMenuItem(
          value: s['id'].toString(),
          child: Text(s['shopName'] ?? 'No Name'),
        )).toList(),
        onChanged: (v) => setState(() => shopId = v),
      ),
    );
  }

  Widget _productPicker() {
    return AppCard(
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: productId,
            hint: const Text("Choose a product"),
            dropdownColor: AppTheme.surface2,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.inventory_2_outlined, color: AppTheme.textSecondary, size: 18),
              labelText: "Product", border: InputBorder.none, enabledBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            ),
            items: widget.products.map((p) => DropdownMenuItem(
              value: p['id'].toString(),
              child: Text(p['name'] ?? '—'),
            )).toList(),
            onChanged: (v) {
              setState(() {
                productId = v;
                if (selProduct != null) priceCtrl.text = selProduct!['price'].toString();
              });
            },
          ),
          const AccentDivider(),
          Row(children: [
            Expanded(child: _tf(qtyCtrl, "Qty", Icons.format_list_numbered_outlined)),
            const SizedBox(width: 10),
            Expanded(child: _tf(priceCtrl, "Price ₹", Icons.currency_rupee)),
            const SizedBox(width: 10),
            Expanded(child: _tf(gstCtrl, "GST %", Icons.percent_rounded)),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text("Add Item"),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent,
                side: const BorderSide(color: AppTheme.accent),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tf(TextEditingController c, String label, IconData icon) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 14),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      ),
    );
  }

  Widget _itemsList() {
    return AppCard(
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return Column(children: [
            Row(children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(color: AppTheme.accentSoft, borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text("${i+1}", style: const TextStyle(
                  color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 12))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['productName'], style: const TextStyle(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                Text("₹${item['price']} × ${item['qty']}", style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12)),
              ])),
              Text("₹${(item['total'] as double).toStringAsFixed(2)}", style: const TextStyle(
                color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => items.removeAt(i)),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppTheme.redSoft, borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.delete_outline_rounded, color: AppTheme.red, size: 15),
                ),
              ),
            ]),
            if (!isLast) const AccentDivider(),
          ]);
        }),
      ),
    );
  }

  Widget _summary() {
    return AppCard(
      child: Column(children: [
        _row("Subtotal", "₹${sub.toStringAsFixed(2)}", false),
        const SizedBox(height: 8),
        _row("GST (${gstPct.toStringAsFixed(0)}%)", "₹${gstAmt.toStringAsFixed(2)}", false),
        const AccentDivider(),
        _row("Grand Total", "₹${grand.toStringAsFixed(2)}", true),
      ]),
    );
  }

  Widget _row(String l, String v, bool bold) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: TextStyle(
        color: bold ? AppTheme.textPrimary : AppTheme.textSecondary,
        fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
        fontSize: bold ? 15 : 13)),
      Text(v, style: TextStyle(
        color: bold ? AppTheme.accent : AppTheme.textPrimary,
        fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
        fontSize: bold ? 18 : 13)),
    ]);
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(children: [
        Expanded(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Total", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            Text("₹${grand.toStringAsFixed(2)}", style: const TextStyle(
              color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
          ],
        )),
        SizedBox(
          width: 160,
          child: ElevatedButton.icon(
            onPressed: saving ? null : _submitOrder,
            icon: saving
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.bg))
                : const Icon(Icons.send_outlined, size: 18),
            label: Text(saving ? "Saving..." : "Submit Order"),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
          ),
        ),
      ]),
    );
  }
}