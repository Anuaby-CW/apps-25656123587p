import 'package:flutter/material.dart';

import '../../core/utils/idr_amount_input_formatter.dart';
import '../../core/utils/money_formatter.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_spacing.dart';

class QuickCashInput extends StatelessWidget {
  const QuickCashInput({
    super.key,
    required this.controller,
    required this.total,
    required this.onChanged,
    this.labelText = 'Uang tunai diterima',
  });

  final TextEditingController controller;
  final int total;
  final ValueChanged<String> onChanged;
  final String labelText;

  @override
  Widget build(BuildContext context) {
    final amounts = quickCashAmounts(total);
    return Semantics(
      container: true,
      label: 'Pembayaran tunai',
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: labelText,
              prefixText: 'Rp ',
              prefixIcon: const Icon(Icons.payments_outlined),
            ),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: const [IdrAmountInputFormatter()],
            onChanged: onChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pilih nominal cepat',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final amount in amounts)
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppLayout.cashierSecondaryControlHeight,
                  ),
                  child: ActionChip(
                    avatar: amount == total
                        ? const Icon(Icons.price_check)
                        : null,
                    label: Text(
                      amount == total
                          ? 'Uang Pas'
                          : MoneyFormatter.format(amount),
                    ),
                    onPressed: () => _setAmount(amount),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _setAmount(int amount) {
    final text = IdrAmountInputFormatter.formatAmount(amount);
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    onChanged(text);
  }
}
