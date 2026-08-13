import '../../domain/models/enums.dart';
import '../../domain/models/receipt_models.dart';

enum PrinterConnectionStatus {
  disconnected,
  connecting,
  connected,
  error;

  String get label => switch (this) {
    disconnected => 'Terputus',
    connecting => 'Menghubungkan',
    connected => 'Terhubung',
    error => 'Bermasalah',
  };
}

class PrinterDevice {
  const PrinterDevice({required this.name, required this.address});

  final String name;
  final String address;
}

abstract class PrinterService {
  PrinterConnectionStatus get status;
  Stream<PrinterConnectionStatus> get statusStream;

  Future<List<PrinterDevice>> pairedDevices();
  Future<bool> connect(PrinterDevice device);
  Future<void> disconnect();
  Future<bool> printReceipt(ReceiptData data, PaperSizeSetting paperSize);
  Future<bool> testPrint(PaperSizeSetting paperSize);
  Future<bool> openCashDrawer();
}
