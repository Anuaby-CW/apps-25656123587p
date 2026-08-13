import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

void main() {
  group('Aset logo Talaga Coffee', () {
    test('logo utama beresolusi tinggi, persegi, dan transparan', () {
      final logo = _decode('assets/images/talaga_logo.png');

      expect(logo.width, 2048);
      expect(logo.height, 2048);
      expect(logo.getPixel(0, 0).a, 0);
      expect(
        logo.any((pixel) => pixel.a > 0),
        isTrue,
        reason: 'Logo tidak boleh kosong.',
      );
    });

    test('logo thermal hanya berisi piksel hitam-putih yang solid', () {
      final logo = _decode('assets/images/talaga_logo_thermal.png');

      expect(logo.width, 384);
      expect(logo.height, 384);
      for (final pixel in logo) {
        expect(pixel.a, 255);
        expect(pixel.r, anyOf(0, 255));
        expect(pixel.g, pixel.r);
        expect(pixel.b, pixel.r);
      }
    });

    test('logo splash tersedia pada setiap density Android', () {
      const expectedSizes = {
        'mdpi': 96,
        'hdpi': 144,
        'xhdpi': 192,
        'xxhdpi': 288,
        'xxxhdpi': 384,
      };

      for (final entry in expectedSizes.entries) {
        final logo = _decode(
          'android/app/src/main/res/drawable-${entry.key}/'
          'talaga_splash_logo.png',
        );
        expect(logo.width, entry.value);
        expect(logo.height, entry.value);
      }
    });
  });
}

image.Image _decode(String path) {
  final decoded = image.decodePng(File(path).readAsBytesSync());
  expect(decoded, isNotNull, reason: '$path harus berupa PNG yang valid.');
  return decoded!;
}
