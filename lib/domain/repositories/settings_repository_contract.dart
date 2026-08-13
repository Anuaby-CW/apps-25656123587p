/// Domain-layer contract for application settings.
///
/// Concrete implementations live in `data/repositories/` and depend on
/// infrastructure details (Drift, etc.).  Feature code should depend only
/// on this contract so that the domain layer stays infrastructure-agnostic.
///
/// **Drift type import** – We import `app_database.dart` for record types
/// such as [PrinterSettingRecord].  This is a pragmatic compromise: the
/// generated Drift data-classes are simple value objects and creating mirror
/// DTOs would add boilerplate without meaningful decoupling benefit.
library;

import '../../data/database/app_database.dart'; // for PrinterSettingRecord

// ---------------------------------------------------------------------------
// Contract
// ---------------------------------------------------------------------------

/// Contract that every settings repository must fulfil.
abstract class SettingsRepositoryContract {
  /// Returns all persisted settings as a flat key→value map.
  Future<Map<String, String>> allSettings();

  /// Returns whether the inventory-tracking feature is currently enabled.
  Future<bool> inventoryEnabled();

  /// Enables or disables the inventory-tracking feature.
  Future<void> setInventoryEnabled(bool enabled);

  /// Persists outlet-related settings (name, address, social links, receipt
  /// footer, etc.) in a single batch.
  Future<void> saveOutletSettings({
    required String outletName,
    required String outletAddress,
    required String outletWhatsapp,
    required String outletInstagram,
    required String receiptFooter,
  });

  /// Returns the current printer configuration as a [PrinterSettingRecord].
  Future<PrinterSettingRecord> printerSettings();

  /// Persists printer-related settings.  Only the supplied (non-null) fields
  /// are updated; the rest remain unchanged.
  Future<void> savePrinter({
    String? printerName,
    String? printerAddress,
    String? paperSize,
    bool? cashDrawerEnabled,
    String? lastConnectionStatus,
  });

  /// Persists a custom setting key-value pair.
  Future<void> saveSetting(String key, String value);
}
