import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final scriptPath = File('tool/verify_release_apk.ps1').absolute.path;

  test('release verifier requires strict apksigner and fingerprint checks', () {
    final script = File(scriptPath).readAsStringSync();

    expect(script, contains('verify --verbose --print-certs --Werr'));
    expect(script, contains(r'^[0-9A-F]{64}$'));
    expect(script, contains(r'$actualFingerprints.Count -ne 1'));
    expect(
      script,
      contains(r'$actualFingerprints[0] -ne $expectedFingerprint'),
    );
    expect(script, isNot(contains('TALAGA_RELEASE_STORE_PASSWORD')));
    expect(script, isNot(contains('TALAGA_RELEASE_KEY_PASSWORD')));
  });

  test(
    'release verifier accepts only the expected signer fingerprint',
    () async {
      final fixture = await _createFixture();
      addTearDown(() => fixture.directory.deleteSync(recursive: true));

      final result = await _runVerifier(
        scriptPath: scriptPath,
        fixture: fixture,
        expectedSha256: fixture.fingerprint,
      );

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(result.stdout, contains('PASS: APK signature is valid'));
    },
    skip: !Platform.isWindows,
  );

  test(
    'release verifier rejects a different signer fingerprint',
    () async {
      final fixture = await _createFixture();
      addTearDown(() => fixture.directory.deleteSync(recursive: true));

      final result = await _runVerifier(
        scriptPath: scriptPath,
        fixture: fixture,
        expectedSha256: List.filled(32, 'BB').join(':'),
      );

      expect(result.exitCode, isNot(0));
      expect(
        '${result.stdout}\n${result.stderr}',
        contains('does not match the expected production fingerprint'),
      );
    },
    skip: !Platform.isWindows,
  );
}

Future<_VerifierFixture> _createFixture() async {
  final directory = await Directory.systemTemp.createTemp(
    'talaga-release-verifier-',
  );
  final apk = File('${directory.path}${Platform.pathSeparator}app-release.apk')
    ..writeAsBytesSync(const [0]);
  final fingerprint = List.filled(32, 'AA').join(':');
  final signer =
      File('${directory.path}${Platform.pathSeparator}fake-apksigner.cmd')
        ..writeAsStringSync(
          '@echo off\n'
          'echo Verifies\n'
          'echo Verified using v2 scheme ^(APK Signature Scheme v2^): true\n'
          'echo Signer #1 certificate SHA-256 digest: '
          '${fingerprint.replaceAll(':', '')}\n'
          'exit /b 0\n',
        );

  return _VerifierFixture(
    directory: directory,
    apk: apk,
    signer: signer,
    fingerprint: fingerprint,
  );
}

Future<ProcessResult> _runVerifier({
  required String scriptPath,
  required _VerifierFixture fixture,
  required String expectedSha256,
}) {
  return Process.run('powershell.exe', [
    '-NoLogo',
    '-NoProfile',
    '-NonInteractive',
    '-ExecutionPolicy',
    'Bypass',
    '-File',
    scriptPath,
    '-ApkPath',
    fixture.apk.path,
    '-ExpectedSha256',
    expectedSha256,
    '-ApkSignerPath',
    fixture.signer.path,
  ]);
}

class _VerifierFixture {
  const _VerifierFixture({
    required this.directory,
    required this.apk,
    required this.signer,
    required this.fingerprint,
  });

  final Directory directory;
  final File apk;
  final File signer;
  final String fingerprint;
}
