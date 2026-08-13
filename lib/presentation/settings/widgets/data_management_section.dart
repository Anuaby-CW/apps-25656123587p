import 'package:flutter/material.dart';

import '../../../domain/models/enums.dart';
import '../../../theme/app_layout.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/common/app_section_card.dart';
import 'reset_data_admin_panel.dart';

class DataManagementSection extends StatelessWidget {
  const DataManagementSection({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    if (role == UserRole.cashier) {
      return _buildCashierSection();
    } else if (role == UserRole.admin) {
      return _buildAdminSection(context);
    }
    return const SizedBox.shrink();
  }

  Widget _buildCashierSection() {
    return AppSectionCard(
      tone: AppSectionTone.warm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Builder(
                builder: (context) => Icon(
                  Icons.shield_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Operasional Terlindungi',
                      style: AppTypography.title,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Riwayat transaksi, kas kecil, dan shift hanya dapat direset oleh admin. Keranjang aktif dapat dikosongkan langsung dari layar POS.',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminSection(BuildContext context) {
    return AppSectionCard(
      tone: AppSectionTone.warm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reset Data Lanjutan', style: AppTypography.title),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Reset data SQLite yang dipakai UI secara terpilah: transaksi, log, atau katalog dan persediaan.',
                      style: AppTypography.caption.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: AppLayout.adminPrimaryControlHeight,
            child: FilledButton.icon(
              onPressed: () => _showAdminResetDialog(context),
              icon: const Icon(Icons.restore_page_outlined),
              label: const Text('Buka Panel Reset Data'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAdminResetDialog(BuildContext context) async {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ResetDataAdminPanel()));
  }
}
