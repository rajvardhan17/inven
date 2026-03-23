class ProductionService {
  static bool canProduce(
    Map<String, double> recipe,
    List rawMaterials,
    int qty,
  ) {
    for (var item in recipe.entries) {
      final raw = rawMaterials.firstWhere(
        (e) => e.name == item.key,
      );

      if (raw.quantity < item.value * qty) {
        return false;
      }
    }
    return true;
  }

  static void produce(
    Map<String, double> recipe,
    List rawMaterials,
    List products,
    String productName,
    int qty,
  ) {
    // Deduct raw
    for (var item in recipe.entries) {
      final raw = rawMaterials.firstWhere(
        (e) => e.name == item.key,
      );
      raw.quantity -= item.value * qty;
    }

    // Add product
    final product = products.firstWhere((p) => p.name == productName);
    product.quantity += qty;
  }
}
