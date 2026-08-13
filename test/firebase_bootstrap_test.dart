import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talaga_coffee_pos/core/config/firebase_bootstrap.dart';

void main() {
  group('FirebaseBootstrap', () {
    test(
      'keeps Firebase disabled when no runtime config is provided',
      () async {
        var initializerCalls = 0;

        final result = await FirebaseBootstrap.initialize(
          config: const FirebaseRuntimeConfig(
            apiKey: '',
            appId: '',
            messagingSenderId: '',
            projectId: '',
          ),
          initializer: (_) async => initializerCalls++,
        );

        expect(result.status, FirebaseBootstrapStatus.disabled);
        expect(initializerCalls, 0);
      },
    );

    test('rejects partial runtime config before initialization', () async {
      var initializerCalls = 0;

      final future = FirebaseBootstrap.initialize(
        config: const FirebaseRuntimeConfig(
          apiKey: 'api-key',
          appId: '',
          messagingSenderId: '',
          projectId: FirebaseRuntimeConfig.approvedProjectId,
        ),
        initializer: (_) async => initializerCalls++,
      );

      await expectLater(
        future,
        throwsA(
          isA<FirebaseConfigurationException>().having(
            (error) => error.missingDartDefines,
            'missing dart-defines',
            containsAll(['FIREBASE_APP_ID', 'FIREBASE_MESSAGING_SENDER_ID']),
          ),
        ),
      );
      expect(initializerCalls, 0);
    });

    test('rejects runtime config for a different Firebase project', () async {
      var initializerCalls = 0;

      final future = FirebaseBootstrap.initialize(
        config: const FirebaseRuntimeConfig(
          apiKey: 'api-key',
          appId: 'android-app-id',
          messagingSenderId: 'sender-id',
          projectId: 'different-project',
        ),
        initializer: (_) async => initializerCalls++,
      );

      await expectLater(
        future,
        throwsA(isA<FirebaseProjectMismatchException>()),
      );
      expect(initializerCalls, 0);
    });

    test('passes complete runtime config to Firebase initializer', () async {
      FirebaseOptions? receivedOptions;

      final result = await FirebaseBootstrap.initialize(
        config: const FirebaseRuntimeConfig(
          apiKey: 'api-key',
          appId: 'android-app-id',
          messagingSenderId: 'sender-id',
          projectId: FirebaseRuntimeConfig.approvedProjectId,
        ),
        initializer: (options) async => receivedOptions = options,
      );

      expect(result.status, FirebaseBootstrapStatus.initialized);
      expect(receivedOptions?.apiKey, 'api-key');
      expect(receivedOptions?.appId, 'android-app-id');
      expect(receivedOptions?.messagingSenderId, 'sender-id');
      expect(
        receivedOptions?.projectId,
        FirebaseRuntimeConfig.approvedProjectId,
      );
    });

    test('accepts complete build-time runtime config when supplied', () async {
      final config = FirebaseRuntimeConfig.fromEnvironment();
      if (config.isDisabled) {
        return;
      }

      FirebaseOptions? receivedOptions;
      final result = await FirebaseBootstrap.initialize(
        config: config,
        initializer: (options) async => receivedOptions = options,
      );

      expect(result.status, FirebaseBootstrapStatus.initialized);
      expect(config.missingDartDefines, isEmpty);
      expect(
        receivedOptions?.projectId,
        FirebaseRuntimeConfig.approvedProjectId,
      );
      expect(receivedOptions?.appId, isNotEmpty);
      expect(receivedOptions?.messagingSenderId, isNotEmpty);
      expect(receivedOptions?.apiKey, isNotEmpty);
    });
  });
}
