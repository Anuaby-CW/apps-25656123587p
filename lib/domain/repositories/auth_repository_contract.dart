/// Domain-layer contract for authentication.
///
/// Concrete implementations live in `data/repositories/` and depend on
/// infrastructure details (Drift, etc.).  Feature code should depend only
/// on this contract so that the domain layer stays infrastructure-agnostic.
///
/// **Drift type import** – We import `app_database.dart` for record types
/// such as [UserRecord].  This is a pragmatic compromise: the generated
/// Drift data-classes are simple value objects and creating mirror DTOs
/// would add boilerplate without meaningful decoupling benefit.
library;

import '../../data/database/app_database.dart'; // for UserRecord

// ---------------------------------------------------------------------------
// Exceptions
// ---------------------------------------------------------------------------

/// Thrown when an authentication operation fails (bad credentials, locked
/// account, etc.).
///
/// Currently defined here in the domain layer.  The concrete repository
/// (`auth_repository.dart`) will be updated to import this definition once
/// the migration is complete.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

// ---------------------------------------------------------------------------
// Contract
// ---------------------------------------------------------------------------

/// Contract that every authentication repository must fulfil.
abstract class AuthRepositoryContract {
  /// Authenticates a user with the given [username] and [password].
  ///
  /// Returns the matching [UserRecord] on success.
  /// Throws [AuthException] if the credentials are invalid.
  Future<UserRecord> login(String username, String password);
}
