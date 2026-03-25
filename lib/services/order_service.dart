import 'package:inven/data/inventory_data.dart';

class OrderService {
  static bool packOrder(
    Map<String, dynamic> order,
  ) {
    // 🔹 First check all items
    for (var item in order["items"]) {
      final product = InventoryData.products.firstWhere(
        (p) => p["name"] == item["product"],
        orElse: () => {},
      );

      if (product.isEmpty || product["qty"] < item["qty"]) {
        return false;
      }
    }

    // 🔹 Then deduct safely
    for (var item in order["items"]) {
      InventoryData.deductStock(
        item["product"],
        item["qty"],
      );
    }

    return true;
  }
}
