import 'package:flutter/material.dart';

import '../../widgets/common/app_state_view.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox,
  });

  final String title;
  final String? message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: title,
      message: message ?? 'Data akan tampil di sini saat tersedia.',
      icon: icon,
    );
  }
}
