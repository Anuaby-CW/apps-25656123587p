import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_preview/device_preview.dart';

import 'core/constants/app_constants.dart';
import 'core/utils/error_message.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/dashboard/dashboard_shell.dart';
import 'presentation/providers/app_providers.dart';
import 'theme/app_theme.dart';

class TalagaCoffeePosApp extends ConsumerWidget {
  const TalagaCoffeePosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider);
    final isDark = ref.watch(darkModeProvider);
    final user = session.asData?.value.user;
    final sessionError = session.hasError
        ? ErrorMessage.from(session.error)
        : null;
    return MaterialApp(
      title: AppConstants.appName,
      // ignore: deprecated_member_use
      useInheritedMediaQuery: true,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.guest(isDark),
      locale: DevicePreview.locale(context),
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final previewChild = DevicePreview.appBuilder(context, child);
        return LayoutBuilder(
          builder: (context, constraints) => Theme(
            data: AppTheme.responsive(Theme.of(context), constraints.maxWidth),
            child: previewChild,
          ),
        );
      },
      // Login tetap berada di layar selama autentikasi berlangsung sehingga
      // field, fokus, dan pesan validasi tidak hilang ketika provider loading.
      home: user == null
          ? LoginScreen(initialError: sessionError)
          : DashboardShell(user: user),
    );
  }
}
