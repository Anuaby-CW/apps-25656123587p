/// Domain-layer contract for reporting / analytics.
///
/// Concrete implementations live in `data/repositories/` and depend on
/// infrastructure details (Drift, etc.).  Feature code should depend only
/// on this contract so that the domain layer stays infrastructure-agnostic.
library;

import '../models/report_models.dart'; // for ReportSummary

// ---------------------------------------------------------------------------
// Contract
// ---------------------------------------------------------------------------

/// Contract that every reports repository must fulfil.
abstract class ReportsRepositoryContract {
  /// Computes an aggregated [ReportSummary] for the period between [start]
  /// and [end] (inclusive).
  Future<ReportSummary> summary(DateTime start, DateTime end);
}
