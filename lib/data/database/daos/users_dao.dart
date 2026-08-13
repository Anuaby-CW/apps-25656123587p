import 'package:drift/drift.dart';

import '../app_database.dart';

class UsersDao {
  UsersDao(this._db);

  final AppDatabase _db;

  Future<UserRecord?> findByUsername(String username) {
    return (_db.select(
      _db.users,
    )..where((tbl) => tbl.username.equals(username))).getSingleOrNull();
  }

  Future<UserRecord?> findById(String id) {
    return (_db.select(
      _db.users,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Stream<List<UserRecord>> watchUsers() {
    return (_db.select(
      _db.users,
    )..orderBy([(tbl) => OrderingTerm.asc(tbl.username)])).watch();
  }

  Future<List<UserRecord>> listUsers() {
    return (_db.select(
      _db.users,
    )..orderBy([(tbl) => OrderingTerm.asc(tbl.username)])).get();
  }

  Future<int> activeAdminCount() {
    final count = _db.users.id.count();
    final query = _db.selectOnly(_db.users)
      ..addColumns([count])
      ..where(_db.users.role.equals('admin') & _db.users.isActive.equals(true));
    return query.map((row) => row.read(count) ?? 0).getSingle();
  }

  Future<bool> hasOperationalHistory(String userId) async {
    final orderCount = _db.orders.id.count();
    final ordersQuery = _db.selectOnly(_db.orders)
      ..addColumns([orderCount])
      ..where(_db.orders.cashierUserId.equals(userId));
    if ((await ordersQuery
            .map((row) => row.read(orderCount) ?? 0)
            .getSingle()) >
        0) {
      return true;
    }

    final pettyCashCount = _db.pettyCash.id.count();
    final pettyCashQuery = _db.selectOnly(_db.pettyCash)
      ..addColumns([pettyCashCount])
      ..where(_db.pettyCash.cashierUserId.equals(userId));
    return (await pettyCashQuery
            .map((row) => row.read(pettyCashCount) ?? 0)
            .getSingle()) >
        0;
  }

  Future<bool> ownsActiveShift(String userId) async {
    final rows =
        await (_db.select(_db.settings)..where(
              (tbl) => tbl.key.isIn(const ['shift_active', 'shift_cashier_id']),
            ))
            .get();
    final values = {for (final row in rows) row.key: row.value};
    return values['shift_active'] == 'true' &&
        values['shift_cashier_id'] == userId;
  }

  Future<void> updateLastLogin(String id, DateTime value) {
    return (_db.update(_db.users)..where((tbl) => tbl.id.equals(id))).write(
      UsersCompanion(lastLoginAt: Value(value), updatedAt: Value(value)),
    );
  }

  Future<void> upsert(UsersCompanion user) {
    return _db.into(_db.users).insertOnConflictUpdate(user);
  }

  Future<void> deleteUser(String id) {
    return (_db.delete(_db.users)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> updateUser(String id, UsersCompanion user) {
    return (_db.update(
      _db.users,
    )..where((tbl) => tbl.id.equals(id))).write(user);
  }
}
