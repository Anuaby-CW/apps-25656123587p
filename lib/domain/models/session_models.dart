import '../../data/database/app_database.dart';
import 'enums.dart';

class SessionState {
  const SessionState({this.user});

  final UserRecord? user;

  bool get isLoggedIn => user != null;
  UserRole? get role => user == null ? null : UserRole.fromDb(user!.role);
}
