import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as image;

const _sourcePath = 'assets/images/talaga_logo_chroma.png';
const _masterPath = 'assets/images/talaga_logo.png';
const _adaptivePath = 'assets/images/talaga_logo_foreground.png';
const _thermalPath = 'assets/images/talaga_logo_thermal.png';

void main() {
  final decoded = image.decodeImage(File(_sourcePath).readAsBytesSync());
  if (decoded == null) {
    throw StateError('Logo sumber tidak dapat dibaca.');
  }

  final keyed = decoded.convert(numChannels: 4);
  var minX = keyed.width;
  var minY = keyed.height;
  var maxX = 0;
  var maxY = 0;

  for (final pixel in keyed) {
    final red = pixel.r.toDouble();
    final green = pixel.g.toDouble();
    final blue = pixel.b.toDouble();
    var alpha = 255.0;
    final strongestNonGreen = math.max(red, blue);
    final greenDominance = green - strongestNonGreen;
    if (green > 100 && greenDominance > 18) {
      alpha = ((110 - greenDominance) / 92 * 255).clamp(0, 255);
      if (alpha < 255) {
        pixel.g = math.min(green, strongestNonGreen);
      }
    }
    pixel.a = alpha;
    if (alpha > 24) {
      final whiteFactor = (math.min(pixel.g, pixel.b) / 255).clamp(0.0, 1.0);
      pixel
        ..r = 143 + (112 * whiteFactor)
        ..g = 255 * whiteFactor
        ..b = 255 * whiteFactor;
    }
    if (alpha > 24) {
      minX = math.min(minX, pixel.x);
      minY = math.min(minY, pixel.y);
      maxX = math.max(maxX, pixel.x);
      maxY = math.max(maxY, pixel.y);
    }
  }

  if (minX > maxX || minY > maxY) {
    throw StateError('Siluet logo tidak ditemukan setelah chroma key.');
  }

  final cropped = image.copyCrop(
    keyed,
    x: math.max(0, minX - 2),
    y: math.max(0, minY - 2),
    width: math.min(keyed.width - minX + 2, maxX - minX + 5),
    height: math.min(keyed.height - minY + 2, maxY - minY + 5),
  );
  final master = _centeredLogo(cropped, canvasSize: 2048, logoFraction: 0.84);
  _writePng(_masterPath, master);

  final adaptive = _centeredLogo(master, canvasSize: 2048, logoFraction: 0.72);
  _writePng(_adaptivePath, adaptive);

  final thermal = image.Image(width: 384, height: 384, numChannels: 4);
  image.fill(thermal, color: image.ColorRgba8(255, 255, 255, 255));
  final thermalSource = image.copyResize(
    master,
    width: 344,
    height: 344,
    interpolation: image.Interpolation.cubic,
  );
  image.compositeImage(thermal, thermalSource, center: true);
  for (final pixel in thermal) {
    final luminance = 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;
    final value = luminance < 170 ? 0 : 255;
    pixel
      ..r = value
      ..g = value
      ..b = value
      ..a = 255;
  }
  _writePng(_thermalPath, thermal);

  const splashSizes = {
    'mdpi': 96,
    'hdpi': 144,
    'xhdpi': 192,
    'xxhdpi': 288,
    'xxxhdpi': 384,
  };
  for (final entry in splashSizes.entries) {
    final resized = image.copyResize(
      master,
      width: entry.value,
      height: entry.value,
      interpolation: image.Interpolation.cubic,
    );
    _writePng(
      'android/app/src/main/res/drawable-${entry.key}/talaga_splash_logo.png',
      resized,
    );
  }
}

image.Image _centeredLogo(
  image.Image source, {
  required int canvasSize,
  required double logoFraction,
}) {
  final targetSize = (canvasSize * logoFraction).round();
  final resized = image.copyResize(
    source,
    width: targetSize,
    height: targetSize,
    maintainAspect: true,
    interpolation: image.Interpolation.cubic,
  );
  final canvas = image.Image(
    width: canvasSize,
    height: canvasSize,
    numChannels: 4,
  );
  image.fill(canvas, color: image.ColorRgba8(0, 0, 0, 0));
  image.compositeImage(canvas, resized, center: true);
  return canvas;
}

void _writePng(String path, image.Image value) {
  final file = File(path)..parent.createSync(recursive: true);
  file.writeAsBytesSync(image.encodePng(value, level: 9));
}
