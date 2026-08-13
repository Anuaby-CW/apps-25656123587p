import 'package:flutter/services.dart';

class IdrAmountInputFormatter extends TextInputFormatter {
  const IdrAmountInputFormatter({this.maxDigits = 12});

  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = _digitsOnly(newValue.text);
    if (digits.length > maxDigits) {
      return oldValue;
    }

    final formatted = formatDigits(digits);
    final selectionEnd = newValue.selection.end < 0
        ? newValue.text.length
        : newValue.selection.end.clamp(0, newValue.text.length);
    final digitsBeforeCursor = _digitsOnly(
      newValue.text.substring(0, selectionEnd),
    ).length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: _cursorOffset(formatted, digitsBeforeCursor),
      ),
    );
  }

  static int? parse(String text) {
    final digits = _digitsOnly(text);
    return digits.isEmpty ? null : int.tryParse(digits);
  }

  static String formatAmount(int amount) => formatDigits(amount.toString());

  static String formatDigits(String input) {
    final digits = _digitsOnly(input).replaceFirst(RegExp(r'^0+(?=\d)'), '');
    return digits.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
  }

  static String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static int _cursorOffset(String formatted, int digitCount) {
    if (digitCount <= 0) {
      return 0;
    }
    var seen = 0;
    for (var index = 0; index < formatted.length; index++) {
      if (_digitsOnly(formatted[index]).isNotEmpty) {
        seen++;
      }
      if (seen == digitCount) {
        return index + 1;
      }
    }
    return formatted.length;
  }
}

List<int> quickCashAmounts(int total, {int limit = 4}) {
  if (total <= 0 || limit <= 0) {
    return const [];
  }

  int roundUp(int unit) => ((total + unit - 1) ~/ unit) * unit;

  final candidates = <int>{
    total,
    roundUp(5000),
    roundUp(10000),
    roundUp(50000),
    for (final denomination in const [
      10000,
      20000,
      50000,
      100000,
      200000,
      500000,
    ])
      if (denomination >= total) denomination,
  }.where((amount) => amount >= total).toList()..sort();

  return candidates.take(limit).toList(growable: false);
}
