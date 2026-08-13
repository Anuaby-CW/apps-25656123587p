import 'package:drift/drift.dart';

import '../../core/auth/password_hasher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/id_generator.dart';
import '../../domain/models/enums.dart';
import '../../domain/repositories/user_repository_contract.dart';
import '../database/app_database.dart';
import '../database/daos/users_dao.dart';

class UserRepository implements UserRepositoryContract {
  UserRepository(this._dao, {PasswordHasher hasher = const PasswordHasher()})
    : _hasher = hasher;

  final UsersDao _dao;
  final PasswordHasher _hasher;

  @override
  Stream<List<UserRecord>> watchUsers() => _dao.watchUsers();

  @override
  Future<void> deleteUser(String id, {required String actorUserId}) async {
    final user = await _dao.findById(id);
    if (user == null) {
      throw StateError('Pengguna tidak ditemukan');
    }
    if (id == actorUserId) {
      throw StateError('Akun yang sedang digunakan tidak dapat dihapus');
    }
    if (await _dao.ownsActiveShift(id)) {
      throw StateError(
        'Pengguna sedang memiliki shift aktif. Tutup shift sebelum menghapus akun.',
      );
    }
    if (user.role == UserRole.admin.name && user.isActive) {
      await _ensureAnotherActiveAdmin();
    }
    if (await _dao.hasOperationalHistory(id)) {
      throw StateError(
        'Pengguna memiliki riwayat transaksi dan tidak dapat dihapus. '
        'Nonaktifkan akun untuk menjaga audit trail.',
      );
    }
    await _dao.deleteUser(id);
  }

  @override
  Future<void> createUser({
    required String username,
    required String password,
    required UserRole role,
  }) async {
    final normalizedUsername = _validatedUsername(username);
    _validatePassword(password);
    final now = DateTime.now();
    await _dao.upsert(
      UsersCompanion.insert(
        id: IdGenerator.create(),
        username: normalizedUsername,
        passwordHash: _hasher.hash(password),
        role: role.name,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<void> updateUser({
    required UserRecord user,
    required String username,
    required UserRole role,
    required String actorUserId,
  }) async {
    if (user.id == actorUserId) {
      throw StateError(
        'Username dan role akun yang sedang digunakan tidak dapat diubah',
      );
    }
    if (role.name != user.role && await _dao.ownsActiveShift(user.id)) {
      throw StateError(
        'Role pengguna dengan shift aktif tidak dapat diubah. Tutup shift terlebih dahulu.',
      );
    }
    final normalizedUsername = _validatedUsername(username);
    if (user.role == UserRole.admin.name &&
        role != UserRole.admin &&
        user.isActive) {
      await _ensureAnotherActiveAdmin();
    }
    await _dao.updateUser(
      user.id,
      UsersCompanion(
        username: Value(normalizedUsername),
        role: Value(role.name),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> resetPassword(UserRecord user, String password) {
    _validatePassword(password);
    return _dao.updateUser(
      user.id,
      UsersCompanion(
        passwordHash: Value(_hasher.hash(password)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<UserRecord> updateDisplayName(
    UserRecord user,
    String displayName,
  ) async {
    final value = displayName.trim();
    if (value.isEmpty) {
      throw StateError('Nama kasir wajib diisi');
    }
    final updatedAt = DateTime.now();
    await _dao.updateUser(
      user.id,
      UsersCompanion(displayName: Value(value), updatedAt: Value(updatedAt)),
    );
    return user.copyWith(displayName: Value(value), updatedAt: updatedAt);
  }

  @override
  Future<void> setActive(
    UserRecord user,
    bool active, {
    required String actorUserId,
  }) async {
    if (!active && user.id == actorUserId) {
      throw StateError('Akun yang sedang digunakan tidak dapat dinonaktifkan');
    }
    if (!active && await _dao.ownsActiveShift(user.id)) {
      throw StateError(
        'Pengguna sedang memiliki shift aktif. Tutup shift sebelum menonaktifkan akun.',
      );
    }
    if (!active && user.role == UserRole.admin.name) {
      if (user.isActive) await _ensureAnotherActiveAdmin();
    }
    await _dao.updateUser(
      user.id,
      UsersCompanion(isActive: Value(active), updatedAt: Value(DateTime.now())),
    );
  }

  @override
  Future<void> resetDefaultUsers() async {
    final now = DateTime.now();
    await _dao.upsert(
      UsersCompanion.insert(
        id: 'user_admin',
        username: AppConstants.defaultAdminUsername,
        passwordHash: _hasher.hash(AppConstants.defaultPassword),
        role: UserRole.admin.name,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await _dao.upsert(
      UsersCompanion.insert(
        id: 'user_kasir',
        username: AppConstants.defaultCashierUsername,
        passwordHash: _hasher.hash(AppConstants.defaultPassword),
        role: UserRole.cashier.name,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> _ensureAnotherActiveAdmin() async {
    final activeAdmins = await _dao.activeAdminCount();
    if (activeAdmins <= 1) {
      throw StateError('Minimal harus ada satu admin aktif');
    }
  }

  String _validatedUsername(String username) {
    final value = username.trim();
    if (value.isEmpty) {
      throw StateError('Nama pengguna wajib diisi');
    }
    return value;
  }

  void _validatePassword(String password) {
    if (password.length < 6) {
      throw StateError('Kata sandi minimal 6 karakter');
    }
  }
}
