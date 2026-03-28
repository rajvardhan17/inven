import 'package:flutter/material.dart';

class OrderData extends ChangeNotifier {
  static final OrderData _instance = OrderData._internal();
  factory OrderData() => _instance;

  OrderData._internal();

  final List<Map<String, dynamic>> _orders = [];

  List<Map<String, dynamic>> get orders => _orders;

  // 🔹 Add Order
  void addOrder(Map<String, dynamic> order) {
    _orders.add({
      ...order,
      "status": "Pending",
      "paymentStatus": "Unpaid",
    });
    notifyListeners();
  }

  // 🔹 Mark Paid
  void markPaid(int index) {
    _orders[index]["paymentStatus"] = "Paid";
    notifyListeners();
  }

  // 🔹 Pack Order
  bool packOrder(int index) {
    _orders[index]["status"] = "Packed";
    notifyListeners();
    return true;
  }
}
