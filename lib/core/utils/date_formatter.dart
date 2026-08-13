import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat compact = DateFormat('dd MMM yyyy HH:mm', 'id_ID');
  static final DateFormat dayKey = DateFormat('yyyyMMdd');
  static final DateFormat inputDate = DateFormat('yyyy-MM-dd');

  static String human(DateTime value) => compact.format(value.toLocal());
}
