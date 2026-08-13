import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../constants/app_constants.dart';

class PasswordHasher {
  const PasswordHasher();

  String hash(String password) {
    final bytes = utf8.encode('${AppConstants.passwordPepper}:$password');
    return sha256.convert(bytes).toString();
  }

  bool verify(String password, String hashValue) {
    return hash(password) == hashValue;
  }
}
