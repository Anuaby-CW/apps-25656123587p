import 'cart_models.dart';
import 'enums.dart';

class CheckoutRequest {
  const CheckoutRequest({
    required this.cashierUserId,
    required this.cashierName,
    required this.items,
    required this.orderType,
    required this.payNow,
    this.customerName,
    this.customerPhone,
    this.tableNumber,
    this.notes,
    this.amountPaid,
  });

  final String cashierUserId;
  final String cashierName;
  final List<CartItem> items;
  final OrderType orderType;
  final bool payNow;
  final String? customerName;
  final String? customerPhone;
  final String? tableNumber;
  final String? notes;
  final int? amountPaid;
}

class ReceivePaymentRequest {
  const ReceivePaymentRequest({
    required this.orderId,
    required this.cashierUserId,
    required this.cashierName,
    required this.amountPaid,
  });

  final String orderId;
  final String cashierUserId;
  final String cashierName;
  final int amountPaid;
}

class CheckoutResult {
  const CheckoutResult({
    required this.orderId,
    required this.orderNumber,
    required this.paymentStatus,
    this.transactionNumber,
    this.printed = false,
    this.printError,
    this.cashDrawerAttempted = false,
    this.cashDrawerOpened = false,
    this.cashDrawerError,
  });

  final String orderId;
  final String orderNumber;
  final PaymentStatus paymentStatus;
  final String? transactionNumber;
  final bool printed;
  final String? printError;
  final bool cashDrawerAttempted;
  final bool cashDrawerOpened;
  final String? cashDrawerError;
}
