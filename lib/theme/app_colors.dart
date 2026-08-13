import 'package:flutter/material.dart';

/// Palet warna tunggal untuk suasana "Tepi Talaga".
abstract final class AppColors {
  // Kayu
  static const wood950 = Color(0xFF2D211C);
  static const wood800 = Color(0xFF51382D);
  static const wood700 = Color(0xFF6C4A3A);
  static const wood600 = Color(0xFF865E48);
  static const wood400 = Color(0xFFB88769);
  static const clay300 = Color(0xFFD7A98B);
  static const cream200 = Color(0xFFEEDFCB);
  static const cream100 = Color(0xFFF7EEDF);

  // Danau
  static const lake950 = Color(0xFF173B38);
  static const lake800 = Color(0xFF24544F);
  static const lake700 = Color(0xFF326A64);
  static const lake600 = Color(0xFF477F78);
  static const lake400 = Color(0xFF79A9A2);
  static const lake300 = Color(0xFFA7C8C3);
  static const lake200 = Color(0xFFCDE0DC);
  static const lake100 = Color(0xFFE7F1EF);

  // Netral dan semantik
  static const canvas = Color(0xFFF5F0E8);
  static const surface = Color(0xFFFFFCF7);
  static const surfaceMuted = Color(0xFFEEE8DF);
  static const ink = Color(0xFF292724);
  static const inkMuted = Color(0xFF6C6861);
  static const outline = Color(0xFFD6C9BA);
  static const outlineStrong = Color(0xFFA99682);
  static const terracotta = Color(0xFFA94F3D);
  static const terracottaDark = Color(0xFF7F382D);
  static const terracottaSoft = Color(0xFFF5E2DC);
  static const ochre = Color(0xFFB67B2E);
  static const ochreSoft = Color(0xFFF5E9CF);
  static const sky = Color(0xFF4D7F91);
  static const skySoft = Color(0xFFE1EDF1);
  static const white = Color(0xFFFFFFFF);
  static const transparent = Color(0x00000000);
  static const scrim = Color(0x702D211C);

  // Warna state dan shadow diturunkan langsung dari token utama.
  static const disabledInk = Color(0x806C6861);
  static const pressedInkOverlay = Color(0x1F292724);
  static const hoverInkOverlay = Color(0x0F292724);
  static const pressedWhiteOverlay = Color(0x29FFFFFF);
  static const hoverWhiteOverlay = Color(0x14FFFFFF);
  static const woodFocus = Color(0x66B88769);
  static const lakeFocus = Color(0x6679A9A2);
  static const shadowWoodSurface = Color(0x122D211C);
  static const shadowWoodFloating = Color(0x242D211C);
  static const shadowLakeGlow = Color(0x1A173B38);

  // Dark surface dan neutral
  static const darkCanvas = Color(0xFF141816);
  static const darkSurface = Color(0xFF1D211F);
  static const darkSurfaceDim = Color(0xFF111513);
  static const darkSurfaceBright = Color(0xFF343A37);
  static const darkContainerLowest = Color(0xFF0F1311);
  static const darkContainerLow = Color(0xFF191D1B);
  static const darkContainer = Color(0xFF222724);
  static const darkContainerHigh = Color(0xFF2A302D);
  static const darkContainerHighest = Color(0xFF343B37);
  static const darkOnSurface = Color(0xFFF7EEDF);
  static const darkOnSurfaceVariant = Color(0xFFD6C9BA);
  static const darkOutline = Color(0xFFA99682);
  static const darkOutlineVariant = Color(0xFF544B43);
  static const darkInverseSurface = Color(0xFFF7EEDF);
  static const darkOnInverseSurface = Color(0xFF2D211C);
  static const darkScrim = Color(0xB32D211C);

  // Dark semantic
  static const darkError = Color(0xFFFFB4A8);
  static const darkOnError = Color(0xFF690005);
  static const darkErrorContainer = Color(0xFF93000A);
  static const darkOnErrorContainer = Color(0xFFFFDAD4);
  static const darkWarning = Color(0xFFE4B86D);
  static const darkOnWarning = Color(0xFF3B290B);
  static const darkWarningContainer = Color(0xFF5A421B);
  static const darkOnWarningContainer = Color(0xFFF5E9CF);
  static const darkInfo = Color(0xFFA8CEDB);
  static const darkOnInfo = Color(0xFF16363F);
  static const darkInfoContainer = Color(0xFF2D5360);
  static const darkOnInfoContainer = Color(0xFFE1EDF1);
  static const darkSuccess = lake300;
  static const darkOnSuccess = lake950;
  static const darkSuccessContainer = lake800;
  static const darkOnSuccessContainer = lake100;

  static const chartPalette = <Color>[
    lake700,
    wood700,
    lake400,
    clay300,
    ochre,
    sky,
    wood400,
    lake800,
    terracotta,
    lake300,
  ];

  static const darkChartPalette = <Color>[
    lake300,
    clay300,
    lake400,
    wood400,
    darkWarning,
    darkInfo,
    cream200,
    lake200,
    darkError,
    ochre,
  ];

  /// Menghasilkan warna series yang stabil; series setelah sepuluh memakai
  /// variasi HSL dari token terdekat, bukan palet Material.
  static Color chartColorAt(int index) {
    assert(index >= 0, 'Indeks chart tidak boleh negatif.');
    final normalizedIndex = index < 0 ? 0 : index;
    final base = chartPalette[normalizedIndex % chartPalette.length];
    final cycle = normalizedIndex ~/ chartPalette.length;
    if (cycle == 0) {
      return base;
    }

    final hsl = HSLColor.fromColor(base);
    final direction = cycle.isOdd ? 1.0 : -1.0;
    final step = ((cycle + 1) ~/ 2).clamp(1, 4) * 0.06;
    return hsl
        .withLightness((hsl.lightness + (direction * step)).clamp(0.22, 0.82))
        .withSaturation((hsl.saturation - (cycle * 0.025)).clamp(0.35, 0.88))
        .toColor();
  }

  static Color darkChartColorAt(int index) {
    assert(index >= 0, 'Indeks chart tidak boleh negatif.');
    final normalizedIndex = index < 0 ? 0 : index;
    final base = darkChartPalette[normalizedIndex % darkChartPalette.length];
    final cycle = normalizedIndex ~/ darkChartPalette.length;
    if (cycle == 0) {
      return base;
    }

    final hsl = HSLColor.fromColor(base);
    final direction = cycle.isOdd ? -1.0 : 1.0;
    final step = ((cycle + 1) ~/ 2).clamp(1, 4) * 0.05;
    return hsl
        .withLightness((hsl.lightness + (direction * step)).clamp(0.32, 0.88))
        .withSaturation((hsl.saturation - (cycle * 0.02)).clamp(0.3, 0.82))
        .toColor();
  }
}
