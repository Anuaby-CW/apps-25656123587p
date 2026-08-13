import 'dart:async';

import '../../core/config/feature_flags.dart';
import '../../core/printer/printer_service.dart';
import '../../core/utils/checkout_logger.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/id_generator.dart';
import '../../core/utils/error_message.dart';
import '../models/cart_models.dart';
import '../models/checkout_models.dart';
import '../models/enums.dart';
import '../repositories/checkout_repository_contract.dart';
import '../repositories/orders_repository_contract.dart';
import '../repositories/printer_log_repository_contract.dart';
import '../repositories/settings_repository_contract.dart';

class CheckoutUseCase {
  CheckoutUseCase({
    required CheckoutRepositoryContract checkoutRepository,
    required OrdersRepositoryContract ordersRepository,
    required PrinterLogRepositoryContract printerLogRepository,
    required SettingsRepositoryContract settingsRepository,
    required PrinterService printerService,
  }) : _checkoutRepository = checkoutRepository,
       _ordersRepository = ordersRepository,
       _printerLogRepository = printerLogRepository,
       _settingsRepository = settingsRepository,
       _printerService = printerService;

  final CheckoutRepositoryContract _checkoutRepository;
  final OrdersRepositoryContract _ordersRepository;
  final PrinterLogRepositoryContract _printerLogRepository;
  final SettingsRepositoryContract _settingsRepository;
  final PrinterService _printerService;

  Future<CheckoutResult> call(CheckoutRequest request) async {
    var currentStep = CheckoutLogStep.checkoutStarted;
    String? transactionId;
    String? transactionNumber;
    CheckoutLogger.event(currentStep, status: 'Started');
    try {
      currentStep = CheckoutLogStep.paymentValidation;
      _validateRequest(request);
      final inventoryEnabled = await _settingsRepository.inventoryEnabled();
      if (inventoryEnabled) {
        await _validateStock(request.items);
      }
      CheckoutLogger.event(currentStep);

      final now = DateTime.now();
      final orderId = IdGenerator.create();
      final orderNumber = await _nextOrderNumber(now);
      final total = request.items.fold(0, (sum, item) => sum + item.subtotal);

      String? paymentId;
      if (request.payNow) {
        paymentId = IdGenerator.create();
        transactionId = IdGenerator.create();
        transactionNumber = await _nextTransactionNumber(now);
      }

      currentStep = CheckoutLogStep.transactionSaved;
      await _checkoutRepository.saveOrder(
        orderId: orderId,
        orderNumber: orderNumber,
        cashierUserId: request.cashierUserId,
        items: request.items,
        orderType: request.orderType,
        total: total,
        now: now,
        payNow: request.payNow,
        customerName: request.customerName,
        customerPhone: request.customerPhone,
        tableNumber: request.tableNumber,
        notes: request.notes,
        amountPaid: request.amountPaid,
        paymentId: paymentId,
        transactionId: transactionId,
        transactionNumber: transactionNumber,
        applyInventory: inventoryEnabled,
      );
      CheckoutLogger.event(
        currentStep,
        transactionId: transactionId,
        reference: orderNumber,
      );

      if (!request.payNow) {
        return CheckoutResult(
          orderId: orderId,
          orderNumber: orderNumber,
          paymentStatus: PaymentStatus.unpaid,
        );
      }

      currentStep = CheckoutLogStep.receiptDataCreated;
      final printResult = await _printPaidReceipt(
        orderId,
        request.cashierName,
        transactionId,
      );
      var drawerResult = const _CashDrawerResult.notAttempted();
      if (printResult.$1 && request.amountPaid! > total) {
        drawerResult = await _openCashDrawerIfEnabled(
          transactionId: transactionId,
          orderNumber: orderNumber,
        );
      }
      return CheckoutResult(
        orderId: orderId,
        orderNumber: orderNumber,
        paymentStatus: PaymentStatus.paid,
        transactionNumber: transactionNumber,
        printed: printResult.$1,
        printError: printResult.$2,
        cashDrawerAttempted: drawerResult.attempted,
        cashDrawerOpened: drawerResult.opened,
        cashDrawerError: drawerResult.error,
      );
    } catch (error, stackTrace) {
      CheckoutLogger.failure(
        currentStep,
        error,
        stackTrace,
        transactionId: transactionId,
      );
      rethrow;
    }
  }

  void _validateRequest(CheckoutRequest request) {
    if (request.items.isEmpty) {
      throw StateError('Keranjang kosong tidak dapat di-checkout');
    }
    if (!_hasValue(request.customerName)) {
      throw StateError('Nama pelanggan wajib diisi');
    }
    if (!request.payNow && !FeatureFlags.payLater) {
      throw StateError('Bayar Nanti sedang dinonaktifkan');
    }
    if (FeatureFlags.tableNumber &&
        request.orderType == OrderType.dineIn &&
        !_hasValue(request.tableNumber)) {
      throw StateError('Nomor meja wajib diisi untuk pesanan Dine In');
    }
    for (final item in request.items) {
      if (item.quantity < 1) {
        throw StateError('Jumlah minimal 1');
      }
      if (item.manualBrewMethodName != null &&
          (item.beanName == null || item.temperatureOption == null)) {
        throw StateError(
          'Manual Brew wajib memilih metode, biji kopi, dan Hot/Ice',
        );
      }
    }
    final total = request.items.fold(0, (sum, item) => sum + item.subtotal);
    if (request.payNow) {
      final amountPaid = request.amountPaid;
      if (amountPaid == null) {
        throw StateError('Bayar Sekarang wajib input nominal pembayaran');
      }
      if (amountPaid < total) {
        throw StateError('Nominal pembayaran kurang');
      }
    } else if (request.amountPaid != null) {
      throw StateError('Bayar Nanti tidak boleh input nominal pembayaran');
    }
  }

  Future<void> _validateStock(List<CartItem> items) async {
    final requiredByProduct = <String, int>{};
    for (final item in items.where((item) => item.trackInventory)) {
      requiredByProduct[item.productId] =
          (requiredByProduct[item.productId] ?? 0) + item.quantity;
    }
    for (final entry in requiredByProduct.entries) {
      final inventory = await _checkoutRepository.inventoryForProduct(
        entry.key,
      );
      if (inventory == null || inventory.quantity < entry.value) {
        throw StateError('Stok produk tidak cukup');
      }
    }
  }

  Future<String> _nextOrderNumber(DateTime now) async {
    final prefix = 'TLG-${DateFormatter.dayKey.format(now)}-';
    final count = await _checkoutRepository.countOrdersForPrefix(prefix);
    return '$prefix${(count + 1).toString().padLeft(4, '0')}';
  }

  Future<String> _nextTransactionNumber(DateTime now) async {
    final prefix = 'TRX-${DateFormatter.dayKey.format(now)}-';
    final count = await _checkoutRepository.countTransactionsForPrefix(prefix);
    return '$prefix${(count + 1).toString().padLeft(4, '0')}';
  }

  Future<(bool, String?)> _printPaidReceipt(
    String orderId,
    String cashierName,
    String? transactionId,
  ) async {
    var currentStep = CheckoutLogStep.receiptDataCreated;
    try {
      final detail = await _ordersRepository.detail(orderId);
      final settings = await _settingsRepository.allSettings();
      final printerSettings = await _settingsRepository.printerSettings();
      final receipt = detail.toReceiptData(settings, cashierName);
      CheckoutLogger.event(
        currentStep,
        transactionId: transactionId,
        reference: receipt.orderNumber,
      );
      currentStep = CheckoutLogStep.printStarted;
      final printed = await _printerService
          .printReceipt(
            receipt,
            PaperSizeSetting.fromDb(printerSettings.paperSize),
          )
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              CheckoutLogger.event(
                CheckoutLogStep.printCompleted,
                status: 'Failed',
                transactionId: transactionId,
                reference: receipt.orderNumber,
                message: 'Print operation timed out.',
              );
              return false;
            },
          );
      return printed
          ? (true, null)
          : (false, 'Gagal mencetak struk atau waktu cetak habis');
    } catch (error, stackTrace) {
      CheckoutLogger.failure(
        currentStep,
        error,
        stackTrace,
        transactionId: transactionId,
      );
      return (false, ErrorMessage.from(error));
    }
  }

  Future<_CashDrawerResult> _openCashDrawerIfEnabled({
    required String? transactionId,
    required String orderNumber,
  }) async {
    String? printerName;
    String? printerAddress;
    try {
      final printerSettings = await _settingsRepository.printerSettings();
      printerName = printerSettings.printerName;
      printerAddress = printerSettings.printerAddress;
      if (!printerSettings.isCashDrawerEnabled) {
        return const _CashDrawerResult.notAttempted();
      }
      final opened = await _printerService.openCashDrawer().timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );
      if (opened) {
        CheckoutLogger.event(
          CheckoutLogStep.cashDrawerOpened,
          transactionId: transactionId,
          reference: orderNumber,
        );
        await _recordCashDrawerLog(
          printerName: printerName,
          printerAddress: printerAddress,
          status: 'success',
          message: 'Laci kas berhasil dibuka setelah checkout $orderNumber',
        );
        return const _CashDrawerResult.opened();
      }
      const message =
          'Laci kas tidak berhasil terbuka otomatis. Periksa koneksi printer.';
      CheckoutLogger.event(
        CheckoutLogStep.cashDrawerOpened,
        status: 'Failed',
        transactionId: transactionId,
        reference: orderNumber,
        message: message,
      );
      await _recordCashDrawerLog(
        printerName: printerName,
        printerAddress: printerAddress,
        status: 'failed',
        message: '$message Pesanan: $orderNumber',
      );
      return const _CashDrawerResult.failed(message);
    } catch (error, stackTrace) {
      final message =
          'Laci kas tidak berhasil terbuka otomatis: ${ErrorMessage.from(error)}';
      CheckoutLogger.failure(
        CheckoutLogStep.cashDrawerOpened,
        error,
        stackTrace,
        transactionId: transactionId,
        reference: orderNumber,
      );
      await _recordCashDrawerLog(
        printerName: printerName,
        printerAddress: printerAddress,
        status: 'failed',
        message: '$message Pesanan: $orderNumber',
      );
      return _CashDrawerResult.failed(message);
    }
  }

  Future<void> _recordCashDrawerLog({
    required String? printerName,
    required String? printerAddress,
    required String status,
    required String message,
  }) async {
    try {
      await _printerLogRepository.record(
        eventType: 'cash_drawer_checkout',
        printerName: printerName,
        printerAddress: printerAddress,
        status: status,
        message: message,
      );
    } on Object {
      // Kegagalan log perangkat tidak boleh mengubah hasil transaksi.
    }
  }

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;
}

class _CashDrawerResult {
  const _CashDrawerResult.notAttempted()
    : attempted = false,
      opened = false,
      error = null;

  const _CashDrawerResult.opened()
    : attempted = true,
      opened = true,
      error = null;

  const _CashDrawerResult.failed(this.error) : attempted = true, opened = false;

  final bool attempted;
  final bool opened;
  final String? error;
}
