import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';

class CreateOrderScreen extends StatefulWidget {
  final List<Map<String, dynamic>> shops;
  final List<Map<String, dynamic>> products;

  const CreateOrderScreen({
    super.key,
    required this.shops,
    required this.products,
  });

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  String? selectedShopId;
  String? selectedProductId;

  final qtyController   = TextEditingController(text: '1');
  final priceController = TextEditingController();
  final gstController   = TextEditingController(text: '18');

  List<Map<String, dynamic>> orderItems = [];

  Map<String, dynamic>? get selectedProduct {
    try {
      return widget.products.firstWhere((p) => p['id'].toString() == selectedProductId);
    } catch (_) {
      return null;
    }
  }

  double get subTotal    => orderItems.fold(0.0, (s, i) => s + (i['total'] as double));
  double get gstPercent  => double.tryParse(gstController.text) ?? 0;
  double get gstAmount   => (subTotal * gstPercent) / 100;
  double get grandTotal  => subTotal + gstAmount;

  void _addItem() {
    if (selectedProduct == null) return _err("Please select a product");
    final qty   = int.tryParse(qtyController.text) ?? 0;
    final price = double.tryParse(priceController.text) ?? 0;
    if (qty <= 0 || price <= 0) return _err("Enter valid quantity & price");

    setState(() {
      orderItems.add({
        'productId':   selectedProductId,
        'productName': selectedProduct!['name'] ?? 'Item',
        'qty':         qty,
        'price':       price,
        'total':       qty * price,
      });
      qtyController.text = '1';
    });
  }

  void _removeItem(int index) => setState(() => orderItems.removeAt(index));

  void _placeOrder() {
    if (selectedShopId == null) return _err("Please select a shop");
    if (orderItems.isEmpty)    return _err("Add at least one item");

    final shop = widget.shops.firstWhere((s) => s['id'].toString() == selectedShopId);
    Navigator.pop(context, {
      'shopId':       selectedShopId,
      'shopName':     shop['shopName'] ?? shop['name'] ?? 'Unknown',
      'items':        orderItems,
      'subTotal':     subTotal,
      'gstPercent':   gstPercent,
      'gstAmount':    gstAmount,
      'totalAmount':  grandTotal,
      'status':       'pending',
      'paymentStatus':'unpaid',
      'createdAt':    DateTime.now(),
    });
  }

  void _err(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.surface2,
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      bottomNavigationBar: _placeOrderBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SectionHeader(title: "Select Shop"),
          _shopPicker(),
          const SectionHeader(title: "Add Products"),
          _productPicker(),
          if (orderItems.isNotEmpty) ...[
            SectionHeader(title: "Order Items", subtitle: "${orderItems.length} item(s) added"),
            _itemsList(),
          ],
          const SectionHeader(title: "Bill Summary"),
          _billSummary(),
        ],
      ),
    );
  }

  Widget _shopPicker() {
    return AppCard(
      child: DropdownButtonFormField<String>(
        value: selectedShopId,
        hint: const Text(
              "Choose a product",
              style: TextStyle(
                color: AppTheme.textPrimary, // or textPrimary if you want full white
                fontSize: 14,
              ),
            ),
        dropdownColor: AppTheme.surface2,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
        decoration: InputDecoration(
  filled: true,
  fillColor: AppTheme.surface2,

  labelText: "Shop",
  labelStyle: const TextStyle(
    color: AppTheme.textSecondary,
    fontSize: 12,
  ),

  prefixIcon: const Icon(
    Icons.store_outlined,
    color: AppTheme.textSecondary,
    size: 18,
  ),

  contentPadding: const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 14,
  ),

  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
    borderSide: const BorderSide(color: AppTheme.border),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
    borderSide: const BorderSide(color: AppTheme.border),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
    borderSide: const BorderSide(
      color: AppTheme.accent,
      width: 1.4,
    ),
  ),
),
        items: widget.shops.map((s) => DropdownMenuItem(
          value: s['id'].toString(),
          child: Text(s['shopName'] ?? 'No Name'),
        )).toList(),
        onChanged: (v) => setState(() => selectedShopId = v),
      ),
    );
  }

  Widget _productPicker() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: selectedProductId,
            hint: const Text(
              "Choose a product",
              style: TextStyle(
                color: AppTheme.textPrimary, // or textPrimary if you want full white
                fontSize: 14,
              ),
            ),
            dropdownColor: AppTheme.surface2,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.surface2,

              labelText: "Product",
              labelStyle: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),

              prefixIcon: const Icon(
                Icons.inventory_2_outlined,
                color: AppTheme.textSecondary,
                size: 18,
              ),

              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                borderSide: const BorderSide(
                  color: AppTheme.accent,
                  width: 1.4,
                ),
              ),
            ),

            items: widget.products.map((p) => DropdownMenuItem(
              value: p['id'].toString(),
              child: Text(p['name'] ?? 'No Name'),
            )).toList(),
            onChanged: (v) {
              setState(() {
                selectedProductId = v;
                final p = selectedProduct;
                if (p != null) priceController.text = p['price'].toString();
              });
            },
          ),
          const AccentDivider(),
          Row(
            children: [
              Expanded(child: _inlineField(qtyController, "Qty", Icons.format_list_numbered_outlined, TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _inlineField(priceController, "Price (₹)", Icons.currency_rupee, TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _inlineField(gstController, "GST %", Icons.percent_rounded, TextInputType.number)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text("Add to Order"),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent,
                side: const BorderSide(color: AppTheme.accent),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inlineField(TextEditingController c, String label, IconData icon, TextInputType type) {
    return TextField(
      controller: c,
      keyboardType: type,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),

      // ✅ FIX START (added only)
      cursorColor: AppTheme.accent,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppTheme.surface2,
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        hintStyle: const TextStyle(color: AppTheme.textMuted),
        prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 15),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide: const BorderSide(color: AppTheme.accent, width: 1.4),
        ),
      ),
      // ✅ FIX END
    );
  }

  // (rest of your file unchanged...)

  // ── Items List ────────────────────────────────────────────
  Widget _itemsList() {
    return AppCard(
      child: Column(
        children: List.generate(orderItems.length, (i) {
          final item = orderItems[i];
          final isLast = i == orderItems.length - 1;

          return Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.accentSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text("${i + 1}", style: const TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      )),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['productName'], style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        )),
                        Text("₹${item['price']} × ${item['qty']}",
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(
                    "₹${(item['total'] as double).toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _removeItem(i),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.redSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                        color: AppTheme.red, size: 16),
                    ),
                  ),
                ],
              ),
              if (!isLast) const AccentDivider(),
            ],
          );
        }),
      ),
    );
  }

  // ── Bill Summary ──────────────────────────────────────────
  Widget _billSummary() {
    return AppCard(
      child: Column(
        children: [
          _billRow("Subtotal", "₹${subTotal.toStringAsFixed(2)}", false),
          const SizedBox(height: 8),
          _billRow("GST (${gstPercent.toStringAsFixed(0)}%)", "₹${gstAmount.toStringAsFixed(2)}", false),
          const AccentDivider(),
          _billRow("Grand Total", "₹${grandTotal.toStringAsFixed(2)}", true),
        ],
      ),
    );
  }

  Widget _billRow(String label, String value, bool bold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          color: bold ? AppTheme.textPrimary : AppTheme.textSecondary,
          fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
          fontSize: bold ? 15 : 13,
        )),
        Text(value, style: TextStyle(
          color: bold ? AppTheme.accent : AppTheme.textPrimary,
          fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
          fontSize: bold ? 18 : 13,
        )),
      ],
    );
  }

  // ── Bottom Bar ────────────────────────────────────────────
  Widget _placeOrderBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Total", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                Text("₹${grandTotal.toStringAsFixed(2)}", style: const TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: -0.5,
                )),
              ],
            ),
          ),
          SizedBox(
            width: 160,
            child: ElevatedButton.icon(
              onPressed: _placeOrder,
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text("Place Order"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}