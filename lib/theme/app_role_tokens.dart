import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'app_layout.dart';
import 'app_spacing.dart';

enum AppVisualRole { guest, cashier, admin }

/// Nilai layout/density yang berubah berdasarkan konteks kerja pengguna.
@immutable
class AppRoleTokens extends ThemeExtension<AppRoleTokens> {
  const AppRoleTokens({
    required this.role,
    required this.controlHeight,
    required this.primaryControlHeight,
    required this.minTapTarget,
    required this.compactPagePadding,
    required this.mediumPagePadding,
    required this.widePagePadding,
    required this.sectionGap,
    required this.cardPadding,
    required this.contentMaxWidth,
  });

  static const guest = AppRoleTokens(
    role: AppVisualRole.guest,
    controlHeight: AppLayout.cashierSecondaryControlHeight,
    primaryControlHeight: AppLayout.cashierSecondaryControlHeight,
    minTapTarget: AppLayout.cashierSecondaryControlHeight,
    compactPagePadding: AppSpacing.md,
    mediumPagePadding: AppSpacing.lg,
    widePagePadding: AppSpacing.xl,
    sectionGap: AppSpacing.xl,
    cardPadding: AppSpacing.xl,
    contentMaxWidth: AppLayout.adminContentMaxWidth,
  );

  static const cashier = AppRoleTokens(
    role: AppVisualRole.cashier,
    controlHeight: AppLayout.cashierControlHeight,
    primaryControlHeight: AppLayout.cashierControlHeight,
    minTapTarget: AppLayout.cashierSecondaryControlHeight,
    compactPagePadding: AppSpacing.sm,
    mediumPagePadding: AppSpacing.md,
    widePagePadding: AppSpacing.md,
    sectionGap: AppSpacing.md,
    cardPadding: AppSpacing.md,
    contentMaxWidth: double.infinity,
  );

  static const admin = AppRoleTokens(
    role: AppVisualRole.admin,
    controlHeight: AppLayout.adminControlHeight,
    primaryControlHeight: AppLayout.adminPrimaryControlHeight,
    minTapTarget: AppLayout.adminPrimaryControlHeight,
    compactPagePadding: AppSpacing.md,
    mediumPagePadding: AppSpacing.lg,
    widePagePadding: AppSpacing.adminWide,
    sectionGap: AppSpacing.xl,
    cardPadding: AppSpacing.lg,
    contentMaxWidth: AppLayout.adminContentMaxWidth,
  );

  final AppVisualRole role;
  final double controlHeight;
  final double primaryControlHeight;
  final double minTapTarget;
  final double compactPagePadding;
  final double mediumPagePadding;
  final double widePagePadding;
  final double sectionGap;
  final double cardPadding;
  final double contentMaxWidth;

  bool get isGuest => role == AppVisualRole.guest;
  bool get isCashier => role == AppVisualRole.cashier;
  bool get isAdmin => role == AppVisualRole.admin;

  double pagePaddingFor(double width) {
    return switch (AppLayout.widthClassFor(width)) {
      AppWidthClass.compact => compactPagePadding,
      AppWidthClass.medium => mediumPagePadding,
      AppWidthClass.expanded ||
      AppWidthClass.large ||
      AppWidthClass.extraLarge => widePagePadding,
    };
  }

  static AppRoleTokens of(BuildContext context) =>
      Theme.of(context).extension<AppRoleTokens>() ?? guest;

  @override
  AppRoleTokens copyWith({
    AppVisualRole? role,
    double? controlHeight,
    double? primaryControlHeight,
    double? minTapTarget,
    double? compactPagePadding,
    double? mediumPagePadding,
    double? widePagePadding,
    double? sectionGap,
    double? cardPadding,
    double? contentMaxWidth,
  }) {
    return AppRoleTokens(
      role: role ?? this.role,
      controlHeight: controlHeight ?? this.controlHeight,
      primaryControlHeight: primaryControlHeight ?? this.primaryControlHeight,
      minTapTarget: minTapTarget ?? this.minTapTarget,
      compactPagePadding: compactPagePadding ?? this.compactPagePadding,
      mediumPagePadding: mediumPagePadding ?? this.mediumPagePadding,
      widePagePadding: widePagePadding ?? this.widePagePadding,
      sectionGap: sectionGap ?? this.sectionGap,
      cardPadding: cardPadding ?? this.cardPadding,
      contentMaxWidth: contentMaxWidth ?? this.contentMaxWidth,
    );
  }

  @override
  AppRoleTokens lerp(covariant AppRoleTokens? other, double t) {
    if (other == null) {
      return this;
    }
    return AppRoleTokens(
      role: t < 0.5 ? role : other.role,
      controlHeight: lerpDouble(controlHeight, other.controlHeight, t)!,
      primaryControlHeight: lerpDouble(
        primaryControlHeight,
        other.primaryControlHeight,
        t,
      )!,
      minTapTarget: lerpDouble(minTapTarget, other.minTapTarget, t)!,
      compactPagePadding: lerpDouble(
        compactPagePadding,
        other.compactPagePadding,
        t,
      )!,
      mediumPagePadding: lerpDouble(
        mediumPagePadding,
        other.mediumPagePadding,
        t,
      )!,
      widePagePadding: lerpDouble(widePagePadding, other.widePagePadding, t)!,
      sectionGap: lerpDouble(sectionGap, other.sectionGap, t)!,
      cardPadding: lerpDouble(cardPadding, other.cardPadding, t)!,
      contentMaxWidth:
          contentMaxWidth.isFinite && other.contentMaxWidth.isFinite
          ? lerpDouble(contentMaxWidth, other.contentMaxWidth, t)!
          : t < 0.5
          ? contentMaxWidth
          : other.contentMaxWidth,
    );
  }
}
