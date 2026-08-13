import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';

/// Dropdown form dengan popup yang mengikuti surface dan shape “Tepi Talaga”.
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.items,
    required this.onChanged,
    this.initialValue,
    this.decoration = const InputDecoration(),
    this.validator,
    this.enabled = true,
  });

  final T? initialValue;
  final InputDecoration decoration;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return DropdownButtonFormField<T>(
      initialValue: initialValue,
      decoration: decoration,
      items: items,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      isExpanded: true,
      dropdownColor: isDark ? scheme.surfaceContainerHigh : scheme.surface,
      borderRadius: AppRadius.card,
      style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
