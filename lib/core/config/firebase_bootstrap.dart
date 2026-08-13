import 'package:firebase_core/firebase_core.dart';

typedef FirebaseInitializer = Future<void> Function(FirebaseOptions options);

enum FirebaseBootstrapStatus { disabled, initialized }

class FirebaseBootstrapResult {
  const FirebaseBootstrapResult(this.status);

  final FirebaseBootstrapStatus status;
}

class FirebaseConfigurationException implements Exception {
  const FirebaseConfigurationException(this.missingDartDefines);

  final List<String> missingDartDefines;

  @override
  String toString() {
    return 'Konfigurasi Firebase belum lengkap. Lengkapi dart-define: '
        '${missingDartDefines.join(', ')}.';
  }
}

class FirebaseProjectMismatchException implements Exception {
  const FirebaseProjectMismatchException();

  @override
  String toString() {
    return 'FIREBASE_PROJECT_ID tidak sesuai dengan project Talaga Coffee POS '
        'yang disetujui.';
  }
}

class FirebaseRuntimeConfig {
  const FirebaseRuntimeConfig({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
  });

  factory FirebaseRuntimeConfig.fromEnvironment() {
    return const FirebaseRuntimeConfig(
      apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
      appId: String.fromEnvironment('FIREBASE_APP_ID'),
      messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
      projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    );
  }

  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;

  static const approvedProjectId = 'talaga-coffee-pos-20260730';

  bool get isDisabled =>
      apiKey.trim().isEmpty &&
      appId.trim().isEmpty &&
      messagingSenderId.trim().isEmpty &&
      projectId.trim().isEmpty;

  List<String> get missingDartDefines {
    return [
      if (apiKey.trim().isEmpty) 'FIREBASE_API_KEY',
      if (appId.trim().isEmpty) 'FIREBASE_APP_ID',
      if (messagingSenderId.trim().isEmpty) 'FIREBASE_MESSAGING_SENDER_ID',
      if (projectId.trim().isEmpty) 'FIREBASE_PROJECT_ID',
    ];
  }

  FirebaseOptions toFirebaseOptions() {
    final missing = missingDartDefines;
    if (missing.isNotEmpty) {
      throw FirebaseConfigurationException(missing);
    }
    if (projectId.trim() != approvedProjectId) {
      throw const FirebaseProjectMismatchException();
    }

    return FirebaseOptions(
      apiKey: apiKey.trim(),
      appId: appId.trim(),
      messagingSenderId: messagingSenderId.trim(),
      projectId: projectId.trim(),
    );
  }
}

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static Future<FirebaseBootstrapResult> initialize({
    FirebaseRuntimeConfig? config,
    FirebaseInitializer? initializer,
  }) async {
    final resolvedConfig = config ?? FirebaseRuntimeConfig.fromEnvironment();
    if (resolvedConfig.isDisabled) {
      return const FirebaseBootstrapResult(FirebaseBootstrapStatus.disabled);
    }

    final options = resolvedConfig.toFirebaseOptions();
    await (initializer ?? _initializeFirebase)(options);
    return const FirebaseBootstrapResult(FirebaseBootstrapStatus.initialized);
  }

  static Future<void> _initializeFirebase(FirebaseOptions options) async {
    await Firebase.initializeApp(options: options);
  }
}
