import 'package:cloud_firestore/cloud_firestore.dart';

enum InvoiceStatus {
  paid,
  pending,
  overdue,
  draft,
  sent,
}

class InvoiceModel {
  final String id;
  final String invoiceNo;
  final String customerName;
  final String? customerAddress;
  final String? placeOfSupply;
  final DateTime date;
  final DateTime dueDate;
  final double subTotal;
  final double paymentMade;
  final InvoiceStatus status;
  final List<InvoiceItem> items;
  final String? orderId;
  final String? shopId;

  InvoiceModel({
    required this.id,
    required this.invoiceNo,
    required this.customerName,
    this.customerAddress,
    this.placeOfSupply,
    required this.date,
    required this.dueDate,
    required this.subTotal,
    this.paymentMade = 0.0,
    required this.status,
    required this.items,
    this.orderId,
    this.shopId,
  });

  double get totalCgst => items.fold(0, (sum, item) => sum + item.cgstAmount);
  double get totalSgst => items.fold(0, (sum, item) => sum + item.sgstAmount);
  double get totalAmount => subTotal + totalCgst + totalSgst;
  double get balanceDue => totalAmount - paymentMade;

  bool get isOverdue => status == InvoiceStatus.overdue || (status != InvoiceStatus.paid && dueDate.isBefore(DateTime.now()));

  factory InvoiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsRaw = data['items'];
    List<dynamic> itemsList = [];
    if (itemsRaw is List) {
      itemsList = itemsRaw;
    } else if (itemsRaw is Map) {
      itemsList = itemsRaw.values.toList();
    }
    
    return InvoiceModel(
      id: doc.id,
      invoiceNo: data['invoiceNo'] ?? 'INV-000',
      customerName: data['shopName'] ?? data['customerName'] ?? 'Unknown',
      customerAddress: data['shopAddress'] ?? data['customerAddress'],
      placeOfSupply: data['placeOfSupply'],
      date: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 7)),
      subTotal: (data['subTotal'] ?? 0.0).toDouble(),
      paymentMade: (data['status'] == 'paid') ? (data['totalAmount'] ?? 0.0).toDouble() : 0.0,
      status: _statusFromKey(data['status']),
      items: itemsList
          .where((e) => e is Map)
          .map((e) => InvoiceItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      orderId: data['orderId'],
      shopId: data['shopId'],
    );
  }

  static InvoiceStatus _statusFromKey(String? key) {
    switch (key?.toLowerCase()) {
      case 'paid': return InvoiceStatus.paid;
      case 'pending': return InvoiceStatus.pending;
      case 'overdue': return InvoiceStatus.overdue;
      case 'unpaid': return InvoiceStatus.pending;
      default: return InvoiceStatus.pending;
    }
  }
}

class InvoiceItem {
  final String description;
  final String hsn;
  final double quantity;
  final String unit;
  final double rate;
  final double cgstPercent;
  final double sgstPercent;

  InvoiceItem({
    required this.description,
    required this.hsn,
    required this.quantity,
    this.unit = 'pcs',
    required this.rate,
    this.cgstPercent = 2.5,
    this.sgstPercent = 2.5,
  });

  double get baseAmount => quantity * rate;
  double get cgstAmount => (baseAmount * cgstPercent) / 100;
  double get sgstAmount => (baseAmount * sgstPercent) / 100;
  double get totalAmount => baseAmount + cgstAmount + sgstAmount;

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      description: map['productName'] ?? map['description'] ?? '',
      hsn: map['hsn'] ?? '0000',
      quantity: (map['qty'] ?? map['quantity'] ?? 0).toDouble(),
      unit: map['unit'] ?? 'pcs',
      rate: (map['price'] ?? map['rate'] ?? 0).toDouble(),
      cgstPercent: (map['cgstPercent'] ?? 2.5).toDouble(),
      sgstPercent: (map['sgstPercent'] ?? 2.5).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productName': description,
      'hsn': hsn,
      'qty': quantity,
      'unit': unit,
      'price': rate,
      'cgstPercent': cgstPercent,
      'sgstPercent': sgstPercent,
      'total': totalAmount,
    };
  }
}
