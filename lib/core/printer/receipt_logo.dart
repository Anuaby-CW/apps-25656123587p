import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../utils/checkout_logger.dart';

/// Menyiapkan logo monokrom untuk perintah raster printer thermal.
///
/// Asset sumber dan hasil resize disimpan di cache agar proses cetak berikutnya
/// tidak perlu membaca serta mengolah gambar yang sama berulang kali.
class ReceiptLogo {
  ReceiptLogo._();

  static const assetPath = 'assets/images/talaga_logo_thermal.png';
  static const width58mm = 192;
  static const width80mm = 240;

  static Future<img.Image?>? _sourceFuture;
  static final Map<int, Future<img.Image?>> _resizedCache = {};

  static Future<img.Image?> forWidth(int width, {String? reference}) async {
    if (width <= 0 || width % 8 != 0) {
      throw ArgumentError.value(
        width,
        'width',
        'Lebar logo printer harus positif dan merupakan kelipatan 8.',
      );
    }

    final logo = await _resizedCache.putIfAbsent(width, () async {
      final source = await (_sourceFuture ??= _loadSource());
      if (source == null) {
        return null;
      }

      final resized = img.copyResize(
        source,
        width: width,
        interpolation: img.Interpolation.average,
      );
      img.grayscale(resized);
      return img.luminanceThreshold(resized, threshold: 0.58);
    });
    if (logo != null) {
      CheckoutLogger.event(
        CheckoutLogStep.bitmapLogoGenerated,
        reference: reference,
      );
    }
    return logo;
  }

  static Future<img.Image?> _loadSource() async {
    try {
      final data = await rootBundle.load(assetPath);
      return img.decodePng(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    } catch (error, stackTrace) {
      CheckoutLogger.failure(
        CheckoutLogStep.bitmapLogoGenerated,
        error,
        stackTrace,
      );
      // Branding bersifat tambahan; struk tetap dapat dicetak bila asset gagal.
      return null;
    }
  }
}
