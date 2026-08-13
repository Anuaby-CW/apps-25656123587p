import 'package:flutter/material.dart';

import '../../widgets/common/app_status_badge.dart';

/// Jalur kompatibilitas untuk badge status lama; warna kini selalu semantik.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.status = AppStatus.neutral,
  });

  final String label;
  final AppStatus status;

  @override
  Widget build(BuildContext context) {
    return AppStatusBadge(label: label, status: status);
  }
}
