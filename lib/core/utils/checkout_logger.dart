import 'package:flutter/foundation.dart';

enum CheckoutLogStep {
  checkoutStarted('Checkout Started'),
  paymentValidation('Payment Validation'),
  transactionSaved('Transaction Saved'),
  receiptDataCreated('Receipt Data Created'),
  bitmapLogoGenerated('Bitmap/Logo Generated'),
  bluetoothInitialized('Bluetooth Initialized'),
  printerConnected('Printer Connected'),
  receiptGenerated('Receipt Generated'),
  printStarted('Print Started'),
  printCompleted('Print Completed'),
  cashDrawerOpened('Cash Drawer Opened'),
  navigationFinished('Navigation Finished');

  const CheckoutLogStep(this.label);

  final String label;
}

/// Temporary checkout diagnostics. Set [enabled] to false to disable all logs.
class CheckoutLogger {
  CheckoutLogger._();

  static bool enabled = const bool.fromEnvironment(
    'CHECKOUT_LOGGING',
    defaultValue: true,
  );

  static void event(
    CheckoutLogStep step, {
    String status = 'Completed',
    String? transactionId,
    String? reference,
    String? message,
  }) {
    if (!enabled) return;
    final buffer = StringBuffer()
      ..writeln('[Checkout]')
      ..writeln('Step: ${step.label}')
      ..writeln('Status: $status');
    if (transactionId != null && transactionId.isNotEmpty) {
      buffer.writeln('TransactionId: $transactionId');
    }
    if (reference != null && reference.isNotEmpty) {
      buffer.writeln('Reference: $reference');
    }
    if (message != null && message.isNotEmpty) {
      buffer.writeln('Message: $message');
    }
    debugPrint(buffer.toString().trimRight());
  }

  static void failure(
    CheckoutLogStep step,
    Object error,
    StackTrace stackTrace, {
    String? transactionId,
    String? reference,
  }) {
    if (!enabled) return;
    final buffer = StringBuffer()
      ..writeln('[Checkout]')
      ..writeln('Step: ${step.label}')
      ..writeln('Status: Failed');
    if (transactionId != null && transactionId.isNotEmpty) {
      buffer.writeln('TransactionId: $transactionId');
    }
    if (reference != null && reference.isNotEmpty) {
      buffer.writeln('Reference: $reference');
    }
    buffer
      ..writeln('Error: $error')
      ..writeln('StackTrace: $stackTrace');
    debugPrint(buffer.toString().trimRight());
  }
}
