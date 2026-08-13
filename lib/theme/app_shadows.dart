import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// Shadow dipakai hemat; ledger menggunakan [none] dan hairline border.
abstract final class AppShadows {
  /// Padanan idiomatik untuk komponen Material yang hanya menerima elevation.
  static const double surfaceElevation = 4;
  static const double floatingElevation = 10;

  static const none = <BoxShadow>[];

  static const surface = <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowWoodSurface,
      offset: Offset(0, 4),
      blurRadius: 14,
    ),
  ];

  static const floating = <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowWoodFloating,
      offset: Offset(0, 10),
      blurRadius: 28,
    ),
  ];

  static const lakeGlow = <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowLakeGlow,
      offset: Offset(0, 6),
      blurRadius: 20,
    ),
  ];
}
