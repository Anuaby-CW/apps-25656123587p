import 'package:flutter_test/flutter_test.dart';
import 'package:talaga_coffee_pos/theme/app_layout.dart';

void main() {
  group('AppLayout.widthClassFor', () {
    test('compact ke medium memakai inclusive lower bound 600', () {
      expect(AppLayout.widthClassFor(599), AppWidthClass.compact);
      expect(AppLayout.widthClassFor(600), AppWidthClass.medium);
      expect(AppLayout.widthClassFor(601), AppWidthClass.medium);
    });

    test('medium ke expanded memakai inclusive lower bound 840', () {
      expect(AppLayout.widthClassFor(839), AppWidthClass.medium);
      expect(AppLayout.widthClassFor(840), AppWidthClass.expanded);
      expect(AppLayout.widthClassFor(841), AppWidthClass.expanded);
    });

    test('expanded ke large memakai inclusive lower bound 1200', () {
      expect(AppLayout.widthClassFor(1199), AppWidthClass.expanded);
      expect(AppLayout.widthClassFor(1200), AppWidthClass.large);
      expect(AppLayout.widthClassFor(1201), AppWidthClass.large);
    });

    test('large ke extra large memakai inclusive lower bound 1600', () {
      expect(AppLayout.widthClassFor(1599), AppWidthClass.large);
      expect(AppLayout.widthClassFor(1600), AppWidthClass.extraLarge);
      expect(AppLayout.widthClassFor(1601), AppWidthClass.extraLarge);
    });
  });

  group('AppLayout compact-height guard', () {
    test('tinggi tepat 480 tidak lagi compact', () {
      expect(AppLayout.isCompactHeight(479), isTrue);
      expect(AppLayout.isCompactHeight(480), isFalse);
      expect(AppLayout.isCompactHeight(481), isFalse);
    });

    test('dual-pane membutuhkan lebar expanded dan tinggi non-compact', () {
      expect(
        AppLayout.shouldUseCashierDualPane(width: 839, height: 900),
        isFalse,
      );
      expect(
        AppLayout.shouldUseCashierDualPane(width: 840, height: 479),
        isFalse,
      );
      expect(
        AppLayout.shouldUseCashierDualPane(width: 840, height: 480),
        isTrue,
      );
      expect(
        AppLayout.shouldUseCashierDualPane(width: 1200, height: 479),
        isFalse,
      );
    });
  });

  test('wideBreakpoint dan helper legacy tetap 1024', () {
    expect(AppLayout.wideBreakpoint, 1024);
    expect(AppLayout.isWide(1023), isFalse);
    expect(AppLayout.isWide(1024), isTrue);
  });
}
