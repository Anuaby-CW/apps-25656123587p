/// Kelas lebar window berbasis available width, bukan jenis perangkat.
enum AppWidthClass { compact, medium, expanded, large, extraLarge }

/// Breakpoint dan ukuran struktural aplikasi.
abstract final class AppLayout {
  static const double compactBreakpoint = 600;
  static const double cashierDualPaneBreakpoint = 840;
  static const double expandedBreakpoint = cashierDualPaneBreakpoint;
  static const double largeBreakpoint = 1200;
  static const double extraLargeBreakpoint = 1600;
  static const double compactHeightBreakpoint = 480;

  /// Breakpoint runtime lama. Pertahankan sampai seluruh consumer [isWide]
  /// selesai dimigrasikan ke [widthClassFor].
  static const double wideBreakpoint = 1024;

  static const double adminContentMaxWidth = 1360;
  static const double cashierCartWidth = 380;
  static const double cashierCartMinWidth = 360;
  static const double cashierCartMaxWidth = 400;
  static const double cashierProductCardMinWidth = 140;
  static const int cashierProductCardMaxColumns = 5;
  static const double navigationRailWidth = 96;
  static const double navigationDrawerWidth = 280;

  static const double cashierServiceBarHeight = 64;
  static const double cashierBottomDockHeight = 76;
  static const double adminMastheadHeight = 72;
  static const double adminRibbonHeight = 56;
  static const double cashierControlHeight = 56;
  static const double cashierSecondaryControlHeight = 48;
  static const double adminControlHeight = 44;
  static const double adminPrimaryControlHeight = 48;

  static const double dialogSmallMaxWidth = 440;
  static const double dialogMediumMaxWidth = 560;
  static const double dialogLargeMaxWidth = 760;
  static const double adminPieChartSize = 290;
  static const double adminTrendChartHeight = 280;
  static const double progressStrokeWidth = 2;

  static bool isCompact(double width) => width < compactBreakpoint;

  static bool isMedium(double width) =>
      width >= compactBreakpoint && width < wideBreakpoint;

  static bool isWide(double width) => width >= wideBreakpoint;

  static AppWidthClass widthClassFor(double width) {
    if (width >= extraLargeBreakpoint) {
      return AppWidthClass.extraLarge;
    }
    if (width >= largeBreakpoint) {
      return AppWidthClass.large;
    }
    if (width >= expandedBreakpoint) {
      return AppWidthClass.expanded;
    }
    if (width >= compactBreakpoint) {
      return AppWidthClass.medium;
    }
    return AppWidthClass.compact;
  }

  static bool isCompactHeight(double height) =>
      height < compactHeightBreakpoint;

  /// Keputusan struktur dual-pane kasir berdasarkan ruang aktual yang
  /// diberikan kepada body POS. Window pendek tetap memakai satu pane.
  static bool shouldUseCashierDualPane({
    required double width,
    required double height,
  }) => !isCompactHeight(height) && width >= cashierDualPaneBreakpoint;

  /// Helper legacy berbasis lebar saja. Untuk keputusan struktur baru,
  /// gunakan [shouldUseCashierDualPane] agar compact-height ikut dijaga.
  static bool isCashierDualPane(double width) =>
      width >= cashierDualPaneBreakpoint;
}
