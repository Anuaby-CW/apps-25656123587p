class ReceiptItem {
  const ReceiptItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.category,
    this.temperature,
    this.sugar,
    this.method,
    this.bean,
    this.addons = const [],
    this.notes,
  });

  final String name;
  final int quantity;
  final int unitPrice;
  final int subtotal;
  final String? category;
  final String? temperature;
  final String? sugar;
  final String? method;
  final String? bean;
  final List<String> addons;
  final String? notes;
}

class ReceiptData {
  const ReceiptData({
    required this.outletName,
    required this.outletAddress,
    required this.outletWhatsapp,
    required this.outletInstagram,
    required this.footer,
    required this.orderNumber,
    required this.createdAt,
    required this.cashierName,
    required this.orderType,
    required this.items,
    required this.total,
    required this.amountPaid,
    required this.changeAmount,
    this.customerName,
    this.customerPhone,
    this.tableNumber,
    this.paymentMethod = 'Tunai',
  });

  final String outletName;
  final String outletAddress;
  final String outletWhatsapp;
  final String outletInstagram;
  final String footer;
  final String orderNumber;
  final DateTime createdAt;
  final String cashierName;
  final String? customerName;
  final String? customerPhone;
  final String? tableNumber;
  final String orderType;
  final List<ReceiptItem> items;
  final int total;
  final int amountPaid;
  final int changeAmount;
  final String paymentMethod;

  bool get isDineIn => orderType == 'Dine In';
}
