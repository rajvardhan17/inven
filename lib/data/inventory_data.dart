// 🔥 GLOBAL INVENTORY DATA (TEMP - Replace with API/DB later)

class InventoryData {
  // 🔹 RAW MATERIALS
  static List<Map<String, dynamic>> rawMaterials = [
    {"name": "Wood Powder", "qty": 50.0, "unit": "kg"},
    {"name": "Perfume", "qty": 20.0, "unit": "L"},
  ];

  // 🔹 FINISHED PRODUCTS
  static List<Map<String, dynamic>> products = [
    {"name": "Rose Agarbatti", "qty": 100},
    {"name": "Sandal Agarbatti", "qty": 80},
  ];

  // 🔍 FIND PRODUCT (SAFE)
  static Map<String, dynamic>? _findProduct(String productName) {
    try {
      return products.firstWhere((p) => p["name"] == productName);
    } catch (e) {
      return null;
    }
  }

  // 🔥 INCREASE PRODUCT STOCK (Production use)
  static bool addStock(String productName, int qty) {
    final product = _findProduct(productName);

    if (product == null) return false;

    product["qty"] += qty;
    return true;
  }

  // 🔥 DEDUCT STOCK (SAFE)
  static bool deductStock(String productName, int qty) {
    final product = _findProduct(productName);

    if (product == null) return false;

    if (product["qty"] >= qty) {
      product["qty"] -= qty;
      return true;
    }

    return false; // ❌ Not enough stock
  }

  // 🔥 UPDATE EXACT QTY (Manual edit)
  static bool setStock(String productName, int newQty) {
    final product = _findProduct(productName);

    if (product == null) return false;

    product["qty"] = newQty;
    return true;
  }

  // 🔥 LOW STOCK CHECK
  static List<Map<String, dynamic>> getLowStockProducts({
    int threshold = 10,
  }) {
    return products.where((p) => p["qty"] <= threshold).toList();
  }
}
