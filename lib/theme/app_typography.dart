import 'package:flutter/material.dart';

import 'app_layout.dart';

/// Skala tipografi offline berbasis font sistem Android.
abstract final class AppTypography {
  static const display = TextStyle(
    fontSize: 32,
    height: 1.25,
    fontWeight: FontWeight.w700,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  static const headline = TextStyle(
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w700,
  );

  static const titleLarge = TextStyle(
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w700,
  );

  static const title = TextStyle(
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w700,
  );

  static const bodyLarge = TextStyle(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w500,
  );

  static const body = TextStyle(
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  static const bodyStrong = TextStyle(
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w700,
  );

  static const label = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  static const caption = TextStyle(
    fontSize: 11,
    height: 16 / 11,
    fontWeight: FontWeight.w500,
  );

  static const monetary = TextStyle(
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  static const _compactDisplay = TextStyle(
    fontSize: 28,
    height: 1.25,
    fontWeight: FontWeight.w700,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  static const _compactHeadline = TextStyle(
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w700,
  );

  static const _compactTitleLarge = TextStyle(
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w700,
  );

  static const compactTextTheme = TextTheme(
    displayLarge: _compactDisplay,
    displayMedium: _compactDisplay,
    displaySmall: _compactHeadline,
    headlineLarge: _compactHeadline,
    headlineMedium: _compactHeadline,
    headlineSmall: _compactTitleLarge,
    titleLarge: _compactTitleLarge,
    titleMedium: title,
    titleSmall: bodyStrong,
    bodyLarge: bodyLarge,
    bodyMedium: body,
    bodySmall: caption,
    labelLarge: bodyStrong,
    labelMedium: label,
    labelSmall: caption,
  );

  static const expandedTextTheme = TextTheme(
    displayLarge: display,
    displayMedium: display,
    displaySmall: headline,
    headlineLarge: headline,
    headlineMedium: headline,
    headlineSmall: titleLarge,
    titleLarge: titleLarge,
    titleMedium: title,
    titleSmall: bodyStrong,
    bodyLarge: bodyLarge,
    bodyMedium: body,
    bodySmall: caption,
    labelLarge: bodyStrong,
    labelMedium: label,
    labelSmall: caption,
  );

  /// Alias baseline untuk kompatibilitas consumer lama.
  static const textTheme = expandedTextTheme;

  static TextTheme textThemeForWidth(double width) =>
      textThemeForClass(AppLayout.widthClassFor(width));

  static TextTheme textThemeForClass(AppWidthClass widthClass) =>
      widthClass == AppWidthClass.compact
      ? compactTextTheme
      : expandedTextTheme;
}
