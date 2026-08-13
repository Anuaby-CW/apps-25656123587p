import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/error_message.dart';
import '../../widgets/common/app_state_view.dart';

class AsyncStateView<T> extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const AppLoadingState(),
      error: (error, _) =>
          AppErrorState(message: ErrorMessage.from(error), onRetry: onRetry),
      data: data,
    );
  }
}
