import 'package:flutter/widgets.dart';

/// Radius "Tepi Talaga" beserta bentuk semantik yang sering dipakai.
abstract final class AppRadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
  static const double pill = 999;

  static const BorderRadius badge = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius input = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius card = BorderRadius.all(Radius.circular(md));
  static const BorderRadius asymmetricCard = BorderRadius.only(
    topLeft: Radius.circular(20),
    bottomRight: Radius.circular(20),
    topRight: Radius.circular(10),
    bottomLeft: Radius.circular(10),
  );
  static const BorderRadius dialog = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius dock = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(lg),
  );
}
