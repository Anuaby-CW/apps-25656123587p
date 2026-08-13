class ReportSummary {
  const ReportSummary({
    required this.totalRevenue,
    required this.paidTransactionCount,
    required this.unpaidOrderCount,
    required this.bestSellingProduct,
    required this.salesByCategory,
    required this.totalCashReceived,
    required this.cancelledOrderCount,
    this.productQuantities = const {},
  });

  final int totalRevenue;
  final int paidTransactionCount;
  final int unpaidOrderCount;
  final String bestSellingProduct;
  final Map<String, int> salesByCategory;
  final int totalCashReceived;
  final int cancelledOrderCount;
  final Map<String, int> productQuantities;
}

/// A single chart bucket whose values are produced by ReportsRepository.
class ReportChartPoint {
  const ReportChartPoint({
    required this.start,
    required this.end,
    required this.label,
    required this.summary,
  });

  final DateTime start;
  final DateTime end;
  final String label;
  final ReportSummary summary;
}

/// Dashboard payload composed from the same summaries used by Reports.
class DashboardAnalytics {
  const DashboardAnalytics({
    required this.range,
    required this.rangeSummary,
    required this.todaySummary,
    required this.yesterdaySummary,
    required this.chartPoints,
  });

  final ReportRange range;
  final ReportSummary rangeSummary;
  final ReportSummary todaySummary;
  final ReportSummary yesterdaySummary;
  final List<ReportChartPoint> chartPoints;
}

enum RevenueComparisonPeriod {
  weekly('Mingguan', 7),
  monthly('Bulanan', 30);

  const RevenueComparisonPeriod(this.label, this.days);

  final String label;
  final int days;
}

class RevenueComparison {
  const RevenueComparison({
    required this.period,
    required this.currentRange,
    required this.previousRange,
    required this.currentSummary,
    required this.previousSummary,
  });

  final RevenueComparisonPeriod period;
  final ReportRange currentRange;
  final ReportRange previousRange;
  final ReportSummary currentSummary;
  final ReportSummary previousSummary;

  double get revenueChangePercent {
    final previous = previousSummary.totalRevenue;
    final current = currentSummary.totalRevenue;
    if (previous == 0) {
      return current == 0 ? 0 : 100;
    }
    return ((current - previous) / previous) * 100;
  }
}

class ReportRange {
  const ReportRange({
    required this.start,
    required this.end,
    required this.label,
  });

  final DateTime start;
  final DateTime end;
  final String label;

  factory ReportRange.today(DateTime now) {
    final start = DateTime(now.year, now.month, now.day);
    return ReportRange(
      start: start,
      end: start.add(const Duration(days: 1)),
      label: 'Hari ini',
    );
  }

  factory ReportRange.yesterday(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 1));
    return ReportRange(start: start, end: today, label: 'Kemarin');
  }

  factory ReportRange.last7Days(DateTime now) {
    final tomorrow = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    final start = tomorrow.subtract(const Duration(days: 7));
    return ReportRange(start: start, end: tomorrow, label: '7 hari');
  }

  ReportRange copyWith({DateTime? start, DateTime? end, String? label}) {
    return ReportRange(
      start: start ?? this.start,
      end: end ?? this.end,
      label: label ?? this.label,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReportRange &&
        other.start == start &&
        other.end == end &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(start, end, label);
}
