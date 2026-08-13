import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('firebase config targets the Jakarta default Firestore database', () {
    final config =
        jsonDecode(File('firebase.json').readAsStringSync())
            as Map<String, dynamic>;

    expect(config, {
      'firestore': {
        'database': '(default)',
        'location': 'asia-southeast2',
        'rules': 'firestore.rules',
        'indexes': 'firestore.indexes.json',
      },
    });
  });

  test('Firebase project alias is dedicated to Talaga Coffee POS', () {
    final config =
        jsonDecode(File('.firebaserc').readAsStringSync())
            as Map<String, dynamic>;

    expect(config['projects'], {'default': 'talaga-coffee-pos-20260730'});
  });

  test('runtime config template is empty and real config remains ignored', () {
    final template =
        jsonDecode(File('firebase.runtime.example.json').readAsStringSync())
            as Map<String, dynamic>;
    final gitignore = File('.gitignore').readAsStringSync();

    expect(template, {
      'FIREBASE_API_KEY': '',
      'FIREBASE_APP_ID': '',
      'FIREBASE_MESSAGING_SENDER_ID': '',
      'FIREBASE_PROJECT_ID': '',
    });
    expect(gitignore, contains('/firebase.runtime.json'));
    expect(gitignore, contains('!/firebase.runtime.example.json'));
  });

  test('Firestore rules deny every document read and write by default', () {
    final rules = File('firestore.rules').readAsStringSync().trim();

    expect(
      rules,
      equals('''
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if false;
    }
  }
}'''),
    );
  });
}
