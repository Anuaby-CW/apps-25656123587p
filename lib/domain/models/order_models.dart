import 'dart:convert';

import '../../data/database/app_database.dart';
import 'enums.dart';
import 'receipt_models.dart';

class OrderDetail {
  const OrderDetail({
    required this.order,
    required this.items,
    this.payment,
    this.transaction,
    this.cashier,
  });

  final OrderRecord order;
  final List<OrderItemRecord> items;
  final PaymentRecord? payment;
  final TransactionRecord? transaction;
  final UserRecord? cashier;

  bool get isPaid => order.paymentStatus == 'paid';
  bool get isUnpaid => order.paymentStatus == 'unpaid';

  ReceiptData toReceiptData(Map<String, String> settings, String cashierName) {
    final paymentRecord = payment;
    final transactionRecord = transaction;
    if (paymentRecord == null || transactionRecord == null) {
      throw StateError(
        'Struk hanya dapat dibuat untuk pesanan lunas dengan data pembayaran dan transaksi',
      );
    }

    return ReceiptData(
      outletName: settings['outlet_name'] ?? 'Talaga Coffee',
      outletAddress: settings['outlet_address'] ?? '',
      outletWhatsapp: settings['outlet_whatsapp'] ?? '',
      outletInstagram: _instagramUsername(settings['outlet_instagram']),
      footer: settings['receipt_footer'] ?? 'Terima kasih',
      orderNumber: order.orderNumber,
      createdAt: paymentRecord.paidAt,
      cashierName: cashierName,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      tableNumber: order.tableNumber,
      orderType: order.orderType == 'takeAway' ? 'Take Away' : 'Dine In',
      items: items.map(_receiptItemFromOrderItem).toList(),
      total: order.total,
      amountPaid: paymentRecord.amountPaid,
      changeAmount: paymentRecord.changeAmount,
      paymentMethod: PaymentMethod.fromDb(paymentRecord.paymentMethod).label,
    );
  }

  ReceiptItem _receiptItemFromOrderItem(OrderItemRecord item) {
    final addons = <String>[];
    final rawAddons = item.addonsJson;
    if (rawAddons != null && rawAddons.isNotEmpty) {
      final decoded = jsonDecode(rawAddons);
      if (decoded is List) {
        for (final addon in decoded) {
          if (addon is Map && addon['name'] != null) {
            addons.add(addon['name'].toString());
          }
        }
      }
    }

    return ReceiptItem(
      name: item.productNameSnapshot,
      category: item.categoryNameSnapshot,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      subtotal: item.subtotal,
      temperature: item.temperatureOption,
      sugar: _sugarLabel(item.sugarOption),
      method: item.manualBrewMethodNameSnapshot,
      bean: item.beanNameSnapshot,
      addons: addons,
      notes: item.notes,
    );
  }

  String? _sugarLabel(String? value) => switch (value) {
    'No Sugar' => 'Tanpa Gula',
    'Less Sugar' => 'Sedikit Gula',
    'Normal Sugar' => 'Normal',
    _ => value,
  };

  String _instagramUsername(String? value) {
    final username = value?.trim() ?? '';
    if (username.isEmpty || username.startsWith('@')) {
      return username;
    }
    return '@$username';
  }
}
