class ErrorMessage {
  ErrorMessage._();

  /// Removes technical exception prefixes before an error reaches the UI.
  static String from(Object? error) {
    if (error == null) {
      return 'Terjadi kesalahan. Silakan coba lagi.';
    }
    if (error is StateError) {
      return error.message.toString();
    }
    if (error is FormatException) {
      return error.message;
    }
    var message = error.toString().trim();
    for (final prefix in const [
      'Bad state: ',
      'Exception: ',
      'FormatException: ',
    ]) {
      if (message.startsWith(prefix)) {
        message = message.substring(prefix.length).trim();
      }
    }
    if (message.isEmpty) {
      return 'Terjadi kesalahan. Silakan coba lagi.';
    }
    return message;
  }
}
