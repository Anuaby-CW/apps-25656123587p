import 'printer_service.dart';

enum CashDrawerCommandStatus {
  notReady,
  ready,
  commandSent,
  failed;

  String get label => switch (this) {
    notReady => 'Belum siap',
    ready => 'Siap',
    commandSent => 'Perintah terkirim',
    failed => 'Gagal',
  };
}

class CashDrawerService {
  CashDrawerService(this._printerService);

  final PrinterService _printerService;

  CashDrawerCommandStatus get readiness {
    return _printerService.status == PrinterConnectionStatus.connected
        ? CashDrawerCommandStatus.ready
        : CashDrawerCommandStatus.notReady;
  }

  Future<CashDrawerCommandStatus> testOpen() async {
    if (_printerService.status != PrinterConnectionStatus.connected) {
      return CashDrawerCommandStatus.notReady;
    }
    final sent = await _printerService.openCashDrawer();
    return sent
        ? CashDrawerCommandStatus.commandSent
        : CashDrawerCommandStatus.failed;
  }
}
