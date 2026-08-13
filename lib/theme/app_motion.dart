import 'package:flutter/animation.dart';

/// Tempo interaksi aplikasi; loading tidak boleh mengubah geometri komponen.
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 120);
  static const standard = Duration(milliseconds: 180);
  static const emphasis = Duration(milliseconds: 240);
  static const curve = Curves.easeOutCubic;
  static const reverseCurve = Curves.easeInCubic;
}
