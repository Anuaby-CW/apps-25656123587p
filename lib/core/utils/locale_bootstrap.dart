import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class LocaleBootstrap {
  LocaleBootstrap._();

  static const indonesiaLocale = 'id_ID';

  static Future<void> ensureInitialized() async {
    Intl.defaultLocale = indonesiaLocale;
    await initializeDateFormatting(indonesiaLocale);
  }
}
