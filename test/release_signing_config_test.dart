import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const signingKeys = {
    'TALAGA_RELEASE_STORE_FILE',
    'TALAGA_RELEASE_STORE_PASSWORD',
    'TALAGA_RELEASE_KEY_ALIAS',
    'TALAGA_RELEASE_KEY_PASSWORD',
  };

  test('release build never falls back to debug signing', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();

    expect(gradle, isNot(contains('signingConfigs.getByName("debug")')));
    expect(gradle, contains('signingConfigs.create("release")'));
    expect(gradle, contains('releaseSigningConfig?.let'));
  });

  test('release signing accepts only complete external configuration', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();

    for (final key in signingKeys) {
      expect(gradle, contains(key));
    }
    expect(gradle, contains('providers.gradleProperty(name)'));
    expect(gradle, contains('providers.environmentVariable(name)'));
    expect(gradle, contains('missingReleaseSigningKeys.isNotEmpty()'));
    expect(gradle, contains('configuredKeystoreFile.isAbsolute'));
    expect(gradle, contains('startsWith(repositoryRoot.toPath())'));
    expect(gradle, contains('keystoreFile.isFile'));
  });

  test('repository ignores Android keystore files', () {
    final rootIgnore = File('.gitignore').readAsStringSync();
    final androidIgnore = File('android/.gitignore').readAsStringSync();

    expect(rootIgnore, contains('*.jks'));
    expect(rootIgnore, contains('*.keystore'));
    expect(androidIgnore, contains('**/*.jks'));
    expect(androidIgnore, contains('**/*.keystore'));
  });

  test('release checklist uses the repository APK signer verifier', () {
    final checklist = File(
      'docs/engineering/RELEASE_SIGNING.md',
    ).readAsStringSync();

    expect(checklist, contains('tool/verify_release_apk.ps1'));
    expect(checklist, contains('-ExpectedSha256'));
    expect(checklist, contains('`apksigner` bukan verifier untuk file `.aab`'));
  });
}
