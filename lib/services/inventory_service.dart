class InventoryService {
  static List<Map<String, dynamic>> checkLowStock(
    List<Map<String, dynamic>> rawMaterials,
    List<Map<String, dynamic>> products,
  ) {
    List<Map<String, dynamic>> alerts = [];

    // 🔹 Raw Material Check
    for (var item in rawMaterials) {
      if (item["qty"] < 10) {
        alerts.add({"name": item["name"], "qty": item["qty"], "type": "raw"});
      }
    }

    // 🔹 Product Check
    for (var item in products) {
      if (item["qty"] < 20) {
        alerts
            .add({"name": item["name"], "qty": item["qty"], "type": "product"});
      }
    }

    return alerts;
  }
}
