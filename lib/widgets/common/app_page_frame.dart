import 'package:flutter/material.dart';

import '../../theme/app_role_tokens.dart';

/// Kanvas halaman responsif yang mengikuti kepadatan role aktif.
class AppPageFrame extends StatelessWidget {
  const AppPageFrame({
    super.key,
    required this.child,
    this.scrollable = true,
    this.safeArea = true,
    this.fullBleed = false,
    this.controller,
    this.physics,
  });

  final Widget child;
  final bool scrollable;
  final bool safeArea;

  /// Menghilangkan padding halaman, misalnya untuk transaction bench kasir.
  /// Batas lebar konten admin tetap dipertahankan.
  final bool fullBleed;
  final ScrollController? controller;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleTokens = AppRoleTokens.of(context);

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = roleTokens.pagePaddingFor(
            constraints.maxWidth,
          );
          Widget content = child;

          if (!fullBleed) {
            content = Padding(
              padding: EdgeInsets.all(horizontalPadding),
              child: content,
            );
          }

          if (!roleTokens.isCashier) {
            content = Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: roleTokens.contentMaxWidth,
                ),
                child: content,
              ),
            );
          }

          if (scrollable) {
            content = SingleChildScrollView(
              controller: controller,
              physics: physics,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: content,
            );
          }

          if (safeArea) {
            content = SafeArea(child: content);
          }

          return content;
        },
      ),
    );
  }
}
