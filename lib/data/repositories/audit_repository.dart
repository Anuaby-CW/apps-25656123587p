import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/utils/id_generator.dart';
import '../../domain/repositories/audit_repository_contract.dart';
import '../database/app_database.dart';
import '../database/daos/audit_dao.dart';

class AuditRepository implements AuditRepositoryContract {
  AuditRepository(this._dao);

  final AuditDao _dao;

  @override
  Future<void> record({
    String? actorUserId,
    String? actorUsername,
    required String action,
    required String entityType,
    String? entityId,
    required String description,
    Map<String, Object?>? metadata,
  }) {
    return _dao.insert(
      AuditLogsCompanion.insert(
        id: IdGenerator.create(),
        actorUserId: Value(actorUserId),
        actorUsername: Value(actorUsername),
        action: action,
        entityType: entityType,
        entityId: Value(entityId),
        description: description,
        metadataJson: metadata == null
            ? const Value(null)
            : Value(jsonEncode(metadata)),
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<AuditLogRecord>> recent({int limit = 100}) {
    return _dao.recent(limit: limit);
  }
}
