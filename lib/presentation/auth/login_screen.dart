import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/error_message.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_section_card.dart';
import '../providers/app_providers.dart';
import '../widgets/talaga_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.initialError});

  final String? initialError;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final error = auth.hasError
        ? ErrorMessage.from(auth.error)
        : widget.initialError;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          Theme.of(context).appBarTheme.systemOverlayStyle ??
          SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final split =
                  constraints.maxWidth >= AppLayout.cashierDualPaneBreakpoint &&
                  !AppLayout.isCompactHeight(constraints.maxHeight);
              if (split) {
                return Padding(
                  padding: AppSpacing.allXl,
                  child: Row(
                    children: [
                      const Expanded(flex: 5, child: _NatureWelcomePanel()),
                      const SizedBox(width: AppSpacing.xl),
                      Expanded(
                        flex: 4,
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: math.max(
                                0,
                                constraints.maxHeight - (AppSpacing.xl * 2),
                              ),
                            ),
                            child: Center(
                              child: _LoginForm(
                                formKey: _formKey,
                                usernameController: _usernameController,
                                passwordController: _passwordController,
                                isLoading: auth.isLoading,
                                error: error,
                                onFill: _fill,
                                onSubmit: _submit,
                                showLogo: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: AppSpacing.allLg,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(
                      0,
                      constraints.maxHeight - (AppSpacing.lg * 2),
                    ),
                  ),
                  child: Center(
                    child: _LoginForm(
                      formKey: _formKey,
                      usernameController: _usernameController,
                      passwordController: _passwordController,
                      isLoading: auth.isLoading,
                      error: error,
                      onFill: _fill,
                      onSubmit: _submit,
                      showLogo: true,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _fill(String username) {
    _usernameController.text = username;
    _passwordController.text = AppConstants.defaultPassword;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    ref
        .read(authControllerProvider.notifier)
        .login(_usernameController.text, _passwordController.text);
  }
}

class _NatureWelcomePanel extends StatelessWidget {
  const _NatureWelcomePanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: AppRadius.dock,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.lake950, AppColors.lake700, AppColors.wood700],
        ),
        boxShadow: AppShadows.floating,
      ),
      child: Padding(
        padding: AppSpacing.allXxl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.cream100,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: AppSpacing.allSm,
                child: TalagaLogo(size: AppSpacing.hero),
              ),
            ),
            const Spacer(),
            Text(
              'Hangat seperti kayu.\nTenang seperti talaga.',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(color: AppColors.white),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Ruang kerja Talaga Coffee untuk layanan kasir dan pengelolaan outlet.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.lake200),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.isLoading,
    required this.error,
    required this.onFill,
    required this.onSubmit,
    required this.showLogo,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool isLoading;
  final String? error;
  final ValueChanged<String> onFill;
  final VoidCallback onSubmit;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: AppLayout.dialogSmallMaxWidth,
      ),
      child: AppSectionCard(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showLogo) ...[
                const Center(child: TalagaLogo(size: AppSpacing.hero * 1.5)),
                const SizedBox(height: AppSpacing.lg),
              ],
              Text(
                'Selamat datang',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppConstants.appName,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Nama pengguna',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nama pengguna wajib diisi'
                    : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Kata sandi',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) => value == null || value.isEmpty
                    ? 'Kata sandi wajib diisi'
                    : null,
                onFieldSubmitted: (_) => onSubmit(),
              ),
              if (error case final error?) ...[
                const SizedBox(height: AppSpacing.sm),
                Semantics(
                  container: true,
                  liveRegion: true,
                  label: error,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: AppRadius.input,
                      border: Border.all(color: scheme.error),
                    ),
                    child: Padding(
                      padding: AppSpacing.allSm,
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: scheme.error),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              error,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: AppLayout.adminPrimaryControlHeight,
                child: FilledButton.icon(
                  onPressed: isLoading ? null : onSubmit,
                  icon: isLoading
                      ? const SizedBox.square(
                          dimension: AppSpacing.lg,
                          child: CircularProgressIndicator(
                            strokeWidth: AppLayout.progressStrokeWidth,
                          ),
                        )
                      : const Icon(Icons.login),
                  label: Text(isLoading ? 'Memeriksa akun…' : 'Masuk'),
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'akun demo',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.analytics_outlined),
                      label: const Text('Admin'),
                      onPressed: () =>
                          onFill(AppConstants.defaultAdminUsername),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.point_of_sale),
                      label: const Text('Kasir'),
                      onPressed: () =>
                          onFill(AppConstants.defaultCashierUsername),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
