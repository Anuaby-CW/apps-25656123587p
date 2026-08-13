import 'dart:async';

import '../../core/printer/printer_service.dart';
import '../../data/database/app_database.dart'; // for UserRecordIdentity extension
import '../repositories/orders_repository_contract.dart';
import '../repositories/settings_repository_contract.dart';
import '../models/enums.dart';

class ReceiptUseCase {
  ReceiptUseCase({
    required OrdersRepositoryContract ordersRepository,
    required SettingsRepositoryContract settingsRepository,
    required PrinterService printerService,
  }) : _ordersRepository = ordersRepository,
       _settingsRepository = settingsRepository,
       _printerService = printerService;

  final OrdersRepositoryContract _ordersRepository;
  final SettingsRepositoryContract _settingsRepository;
  final PrinterService _printerService;

  Future<bool> printPaidOrder(
    String orderId,
    String fallbackCashierName,
  ) async {
    final detail = await _ordersRepository.detail(orderId);
    if (!detail.isPaid) {
      throw StateError('Cetak struk hanya untuk pesanan lunas');
    }
    final settings = await _settingsRepository.allSettings();
    final printerSettings = await _settingsRepository.printerSettings();
    final preferredCashierName = fallbackCashierName.trim();
    final receipt = detail.toReceiptData(
      settings,
      preferredCashierName.isNotEmpty
          ? preferredCashierName
          : detail.cashier?.cashierName ?? 'Kasir',
    );
    return _printerService
        .printReceipt(
          receipt,
          PaperSizeSetting.fromDb(printerSettings.paperSize),
        )
        .timeout(const Duration(seconds: 5), onTimeout: () => false);
  }
}
