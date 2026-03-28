import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class OrderData extends ChangeNotifier {
  static final OrderData _instance = OrderData._internal();
  factory OrderData() => _instance;

  OrderData._internal();

  final List<Map<String, dynamic>> _orders = [];
  final _uuid = const Uuid();

  List<Map<String, dynamic>> get orders => _orders;

  void addOrder(Map<String, dynamic> order) {
    _orders.add({
      ...order,
      "status": "Pending",
      "paymentStatus": "Unpaid",
      "invoiceNo": "INV-${_uuid.v4().substring(0, 6)}",
      "date": DateTime.now().toString(),
      "paymentMethod": "UPI",
    });
    notifyListeners();
  }

  void markPaid(int index) {
    _orders[index]["paymentStatus"] = "Paid";
    notifyListeners();
  }

  bool packOrder(int index) {
    _orders[index]["status"] = "Packed";
    notifyListeners();
    return true;
  }
}
