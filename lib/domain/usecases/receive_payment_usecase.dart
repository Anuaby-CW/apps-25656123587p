import 'dart:async';

import '../../core/printer/printer_service.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/id_generator.dart';
import '../../core/utils/error_message.dart';
import '../models/checkout_models.dart';
import '../models/enums.dart';
import '../repositories/checkout_repository_contract.dart';
import '../repositories/orders_repository_contract.dart';
import '../repositories/settings_repository_contract.dart';

class ReceivePaymentUseCase {
  ReceivePaymentUseCase({
    required CheckoutRepositoryContract checkoutRepository,
    required OrdersRepositoryContract ordersRepository,
    required SettingsRepositoryContract settingsRepository,
    required PrinterService printerService,
  }) : _checkoutRepository = checkoutRepository,
       _ordersRepository = ordersRepository,
       _settingsRepository = settingsRepository,
       _printerService = printerService;

  final CheckoutRepositoryContract _checkoutRepository;
  final OrdersRepositoryContract _ordersRepository;
  final SettingsRepositoryContract _settingsRepository;
  final PrinterService _printerService;

  Future<CheckoutResult> call(ReceivePaymentRequest request) async {
    final order = await _checkoutRepository.findOrder(request.orderId);
    if (order == null) {
      throw StateError('Pesanan tidak ditemukan');
    }
    if (order.paymentStatus != PaymentStatus.unpaid.name) {
      throw StateError('Pesanan sudah lunas');
    }
    if (order.orderStatus != OrderStatus.preparing.name &&
        order.orderStatus != OrderStatus.ready.name) {
      throw StateError('Status pesanan tidak dapat menerima pembayaran');
    }
    if (request.amountPaid < order.total) {
      throw StateError('Nominal pembayaran kurang');
    }

    final now = DateTime.now();
    final paymentId = IdGenerator.create();
    final transactionId = IdGenerator.create();
    final transactionNumber = await _nextTransactionNumber(now);
    await _checkoutRepository.recordPayment(
      orderId: order.id,
      orderTotal: order.total,
      cashierUserId: request.cashierUserId,
      amountPaid: request.amountPaid,
      paymentId: paymentId,
      transactionId: transactionId,
      transactionNumber: transactionNumber,
      now: now,
    );

    final printResult = await _printPaidReceipt(order.id, request.cashierName);
    if (printResult.$1 && request.amountPaid > order.total) {
      await _openCashDrawerIfEnabled();
    }
    return CheckoutResult(
      orderId: order.id,
      orderNumber: order.orderNumber,
      paymentStatus: PaymentStatus.paid,
      transactionNumber: transactionNumber,
      printed: printResult.$1,
      printError: printResult.$2,
    );
  }

  Future<String> _nextTransactionNumber(DateTime now) async {
    final prefix = 'TRX-${DateFormatter.dayKey.format(now)}-';
    final count = await _checkoutRepository.countTransactionsForPrefix(prefix);
    return '$prefix${(count + 1).toString().padLeft(4, '0')}';
  }

  Future<(bool, String?)> _printPaidReceipt(
    String orderId,
    String cashierName,
  ) async {
    try {
      final detail = await _ordersRepository.detail(orderId);
      final settings = await _settingsRepository.allSettings();
      final printerSettings = await _settingsRepository.printerSettings();
      final receipt = detail.toReceiptData(settings, cashierName);
      final printed = await _printerService
          .printReceipt(
            receipt,
            PaperSizeSetting.fromDb(printerSettings.paperSize),
          )
          .timeout(const Duration(seconds: 5), onTimeout: () => false);
      return printed
          ? (true, null)
          : (false, 'Gagal mencetak struk atau waktu cetak habis');
    } catch (error) {
      return (false, ErrorMessage.from(error));
    }
  }

  Future<void> _openCashDrawerIfEnabled() async {
    try {
      final printerSettings = await _settingsRepository.printerSettings();
      if (!printerSettings.isCashDrawerEnabled) {
        return;
      }
      await _printerService.openCashDrawer().timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );
    } catch (_) {
      // Pembayaran tetap tersimpan jika laci gagal dibuka.
    }
  }
}
