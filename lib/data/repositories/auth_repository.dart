import 'package:drift/drift.dart';

import '../../core/auth/password_hasher.dart';
import '../../domain/repositories/auth_repository_contract.dart';
import '../database/app_database.dart';
import '../database/daos/users_dao.dart';

export '../../domain/repositories/auth_repository_contract.dart' show AuthException;

class AuthRepository implements AuthRepositoryContract {
  AuthRepository(
    this._usersDao, {
    PasswordHasher hasher = const PasswordHasher(),
  }) : _hasher = hasher;

  final UsersDao _usersDao;
  final PasswordHasher _hasher;

  @override
  Future<UserRecord> login(String username, String password) async {
    final user = await _usersDao.findByUsername(username.trim());
    if (user == null || !_hasher.verify(password, user.passwordHash)) {
      throw const AuthException('Nama pengguna atau kata sandi salah');
    }
    if (!user.isActive) {
      throw const AuthException('Pengguna nonaktif tidak dapat login');
    }
    final now = DateTime.now();
    await _usersDao.updateLastLogin(user.id, now);
    return user.copyWith(lastLoginAt: Value(now), updatedAt: now);
  }
}
