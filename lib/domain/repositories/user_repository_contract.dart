/// Domain contract for UserRepository. Concrete implementation in data layer.
library;

import '../../data/database/app_database.dart';
import '../models/enums.dart';

abstract class UserRepositoryContract {
  Stream<List<UserRecord>> watchUsers();

  Future<void> deleteUser(String id, {required String actorUserId});

  Future<void> createUser({
    required String username,
    required String password,
    required UserRole role,
  });

  Future<void> updateUser({
    required UserRecord user,
    required String username,
    required UserRole role,
    required String actorUserId,
  });

  Future<void> resetPassword(UserRecord user, String password);

  Future<UserRecord> updateDisplayName(UserRecord user, String displayName);

  Future<void> setActive(
    UserRecord user,
    bool active, {
    required String actorUserId,
  });

  Future<void> resetDefaultUsers();
}
