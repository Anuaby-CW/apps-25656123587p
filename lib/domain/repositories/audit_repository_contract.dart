/// Domain-layer contract for audit-log recording and retrieval.
///
/// Concrete implementations live in `data/repositories/` and depend on
/// infrastructure details (Drift, etc.).  Feature code should depend only
/// on this contract so that the domain layer stays infrastructure-agnostic.
///
/// **Drift type import** – We import `app_database.dart` for record types
/// such as [AuditLogRecord].  This is a pragmatic compromise: the generated
/// Drift data-classes are simple value objects and creating mirror DTOs
/// would add boilerplate without meaningful decoupling benefit.
library;

import '../../data/database/app_database.dart'; // for AuditLogRecord

// ---------------------------------------------------------------------------
// Contract
// ---------------------------------------------------------------------------

/// Contract that every audit repository must fulfil.
abstract class AuditRepositoryContract {
  /// Persists a single audit-log entry.
  ///
  /// [actorUserId] and [actorUsername] identify *who* performed the action.
  /// [action] is a verb/label (e.g. `"create"`, `"delete"`).
  /// [entityType] categorises the affected resource (e.g. `"order"`).
  /// [entityId] optionally identifies a specific resource instance.
  /// [description] is a human-readable summary of the event.
  /// [metadata] carries arbitrary structured data for later analysis.
  Future<void> record({
    String? actorUserId,
    String? actorUsername,
    required String action,
    required String entityType,
    String? entityId,
    required String description,
    Map<String, Object?>? metadata,
  });

  /// Returns the most recent audit-log entries, newest first.
  ///
  /// At most [limit] entries are returned (defaults to 100).
  Future<List<AuditLogRecord>> recent({int limit = 100});
}
