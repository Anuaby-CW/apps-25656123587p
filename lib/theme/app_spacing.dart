import 'package:flutter/widgets.dart';

/// Skala spacing 4 dp dan padding role yang terdokumentasi.
abstract final class AppSpacing {
  static const double none = 0;
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double adminWide = 28;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double section = 48;
  static const double hero = 64;

  static const EdgeInsets zero = EdgeInsets.zero;
  static const EdgeInsets allXxs = EdgeInsets.all(xxs);
  static const EdgeInsets allXs = EdgeInsets.all(xs);
  static const EdgeInsets allSm = EdgeInsets.all(sm);
  static const EdgeInsets allMd = EdgeInsets.all(md);
  static const EdgeInsets allLg = EdgeInsets.all(lg);
  static const EdgeInsets allXl = EdgeInsets.all(xl);
  static const EdgeInsets allXxl = EdgeInsets.all(xxl);
}
