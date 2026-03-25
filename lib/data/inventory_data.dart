import 'package:flutter/material.dart';

// 🔥 GLOBAL INVENTORY DATA (TEMP - Replace with API/DB later)

class InventoryData {
  // 🔥 NOTIFIER (this makes UI auto refresh)
  static ValueNotifier<List<Map<String, dynamic>>> productsNotifier =
      ValueNotifier([
    {"name": "Rose Agarbatti", "qty": 100},
    {"name": "Sandal Agarbatti", "qty": 80},
  ]);

  // 🔹 RAW MATERIALS (no change needed)
  static List<Map<String, dynamic>> rawMaterials = [
    {"name": "Wood Powder", "qty": 50.0, "unit": "kg"},
    {"name": "Perfume", "qty": 20.0, "unit": "L"},
  ];

  // 🔹 ACCESS PRODUCTS (always use this)
  static List<Map<String, dynamic>> get products => productsNotifier.value;

  // 🔍 FIND PRODUCT (SAFE)
  static Map<String, dynamic>? _findProduct(String productName) {
    try {
      return products.firstWhere((p) => p["name"] == productName);
    } catch (e) {
      return null;
    }
  }

  // 🔥 INCREASE PRODUCT STOCK
  static bool addStock(String productName, int qty) {
    final product = _findProduct(productName);

    if (product == null) return false;

    product["qty"] += qty;

    // 🔥 notify UI
    productsNotifier.notifyListeners();

    return true;
  }

  // 🔥 DEDUCT STOCK
  static bool deductStock(String productName, int qty) {
    final product = _findProduct(productName);

    if (product == null) return false;

    if (product["qty"] >= qty) {
      product["qty"] -= qty;

      // 🔥 notify UI
      productsNotifier.notifyListeners();

      return true;
    }

    return false;
  }

  // 🔥 UPDATE EXACT QTY
  static bool setStock(String productName, int newQty) {
    final product = _findProduct(productName);

    if (product == null) return false;

    product["qty"] = newQty;

    // 🔥 notify UI
    productsNotifier.notifyListeners();

    return true;
  }

  // 🔥 LOW STOCK CHECK
  static List<Map<String, dynamic>> getLowStockProducts({
    int threshold = 10,
  }) {
    return products.where((p) => p["qty"] <= threshold).toList();
  }
}
