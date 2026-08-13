import 'dart:async';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../permissions/bluetooth_permission_service.dart';
import '../utils/checkout_logger.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/receipt_models.dart';
import 'printer_service.dart';
import 'receipt_formatter_58mm.dart';
import 'receipt_formatter_80mm.dart';

class AndroidBluetoothPrinterService implements PrinterService {
  AndroidBluetoothPrinterService({
    ReceiptFormatter58mm? formatter58,
    ReceiptFormatter80mm? formatter80,
    BluetoothPermissionService? permissionService,
  }) : _formatter58 = formatter58 ?? ReceiptFormatter58mm(),
       _formatter80 = formatter80 ?? ReceiptFormatter80mm(),
       _permissionService =
           permissionService ?? AndroidBluetoothPermissionService();

  final ReceiptFormatter58mm _formatter58;
  final ReceiptFormatter80mm _formatter80;
  final BluetoothPermissionService _permissionService;
  final _statusController =
      StreamController<PrinterConnectionStatus>.broadcast();

  PrinterConnectionStatus _status = PrinterConnectionStatus.disconnected;

  @override
  PrinterConnectionStatus get status => _status;

  @override
  Stream<PrinterConnectionStatus> get statusStream => _statusController.stream;

  @override
  Future<List<PrinterDevice>> pairedDevices() async {
    if (!await _hasBluetoothPermission()) return const [];
    try {
      final devices = await PrintBluetoothThermal.pairedBluetooths.timeout(
        const Duration(seconds: 10),
      );
      return devices
          .map(
            (device) =>
                PrinterDevice(name: device.name, address: device.macAdress),
          )
          .toList();
    } on Object {
      _setStatus(PrinterConnectionStatus.error);
      return const [];
    }
  }

  @override
  Future<bool> connect(PrinterDevice device) async {
    if (!await _hasBluetoothPermission()) {
      _setStatus(PrinterConnectionStatus.error);
      return false;
    }
    _setStatus(PrinterConnectionStatus.connecting);
    try {
      final connected = await PrintBluetoothThermal.connect(
        macPrinterAddress: device.address,
      ).timeout(const Duration(seconds: 15), onTimeout: () => false);
      _setStatus(
        connected
            ? PrinterConnectionStatus.connected
            : PrinterConnectionStatus.error,
      );
      return connected;
    } on Object {
      _setStatus(PrinterConnectionStatus.error);
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    if (await _hasBluetoothPermission()) {
      try {
        await PrintBluetoothThermal.disconnect;
      } on Object {
        _setStatus(PrinterConnectionStatus.error);
        return;
      }
    }
    _setStatus(PrinterConnectionStatus.disconnected);
  }

  @override
  Future<bool> printReceipt(
    ReceiptData data,
    PaperSizeSetting paperSize,
  ) async {
    var step = CheckoutLogStep.receiptGenerated;
    try {
      final bytes = switch (paperSize) {
        PaperSizeSetting.mm58 => await _formatter58.format(data),
        PaperSizeSetting.mm80 => await _formatter80.format(data),
      };

      step = CheckoutLogStep.bluetoothInitialized;
      if (!await _prepareBluetoothForCheckout(data.orderNumber)) return false;
      CheckoutLogger.event(
        CheckoutLogStep.receiptGenerated,
        reference: data.orderNumber,
      );

      step = CheckoutLogStep.printStarted;
      CheckoutLogger.event(
        CheckoutLogStep.printStarted,
        status: 'Started',
        reference: data.orderNumber,
      );
      final success = await PrintBluetoothThermal.writeBytes(bytes);
      _setStatus(
        success
            ? PrinterConnectionStatus.connected
            : PrinterConnectionStatus.error,
      );
      CheckoutLogger.event(
        CheckoutLogStep.printCompleted,
        status: success ? 'Completed' : 'Failed',
        reference: data.orderNumber,
      );
      return success;
    } catch (error, stackTrace) {
      _setStatus(PrinterConnectionStatus.error);
      CheckoutLogger.failure(
        step,
        error,
        stackTrace,
        reference: data.orderNumber,
      );
      return false;
    }
  }

  @override
  Future<bool> testPrint(PaperSizeSetting paperSize) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(
      paperSize == PaperSizeSetting.mm58 ? PaperSize.mm58 : PaperSize.mm80,
      profile,
    );
    final bytes = <int>[
      ...generator.reset(),
      ...generator.text(
        'Talaga Coffee POS',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
      ...generator.text(
        'Cetak uji berhasil',
        styles: const PosStyles(align: PosAlign.center),
      ),
      ...generator.hr(),
      ...generator.text('Printer ESC/POS siap digunakan.'),
      ...generator.feed(2),
      ...generator.cut(),
    ];
    return _write(bytes);
  }

  @override
  Future<bool> openCashDrawer() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    return _write(generator.drawer());
  }

  Future<bool> _write(List<int> bytes) async {
    if (!await _hasBluetoothPermission()) {
      _setStatus(PrinterConnectionStatus.error);
      return false;
    }
    try {
      final connected = await PrintBluetoothThermal.connectionStatus;
      if (!connected) {
        _setStatus(PrinterConnectionStatus.disconnected);
        return false;
      }
      final success = await PrintBluetoothThermal.writeBytes(bytes);
      _setStatus(
        success
            ? PrinterConnectionStatus.connected
            : PrinterConnectionStatus.error,
      );
      return success;
    } on Object {
      _setStatus(PrinterConnectionStatus.error);
      return false;
    }
  }

  Future<bool> _prepareBluetoothForCheckout(String reference) async {
    final permission = await _permissionService.status();
    if (permission != BluetoothPermissionState.granted) {
      _setStatus(PrinterConnectionStatus.error);
      CheckoutLogger.event(
        CheckoutLogStep.bluetoothInitialized,
        status: 'Failed',
        reference: reference,
        message: 'Bluetooth permission is not granted.',
      );
      return false;
    }
    CheckoutLogger.event(
      CheckoutLogStep.bluetoothInitialized,
      reference: reference,
    );

    final connected = await PrintBluetoothThermal.connectionStatus;
    _setStatus(
      connected
          ? PrinterConnectionStatus.connected
          : PrinterConnectionStatus.disconnected,
    );
    CheckoutLogger.event(
      CheckoutLogStep.printerConnected,
      status: connected ? 'Completed' : 'Failed',
      reference: reference,
    );
    return connected;
  }

  Future<bool> _hasBluetoothPermission() async {
    return await _permissionService.status() ==
        BluetoothPermissionState.granted;
  }

  void _setStatus(PrinterConnectionStatus status) {
    _status = status;
    _statusController.add(status);
  }
}
