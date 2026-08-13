/// Domain-layer contract for data-reset / housekeeping operations.
///
/// Concrete implementations live in `data/repositories/` and depend on
/// infrastructure details (Drift, etc.).  Feature code should depend only
/// on this contract so that the domain layer stays infrastructure-agnostic.
library;

// ---------------------------------------------------------------------------
// Contract
// ---------------------------------------------------------------------------

/// Contract that every reset repository must fulfil.
abstract class ResetRepositoryContract {
  /// Applies the selected database reset operations as one atomic unit.
  Future<void> resetSelected({
    required bool transactionalData,
    required bool sessionLogs,
    required bool referenceData,
    required bool customers,
  });

  /// Deletes all transactional data (orders, line items, payments, etc.)
  /// while preserving reference data and settings.
  Future<void> clearTransactionalData();

  /// Deletes all session / activity logs.
  Future<void> clearSessionLogs();

  /// Replaces local reference data with the catalog defaults bundled in the
  /// offline application.
  Future<void> clearReferenceCache();

  /// Deletes all customer records.
  Future<void> clearCustomers();
}
