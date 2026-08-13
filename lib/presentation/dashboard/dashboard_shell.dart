import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routing/app_destination.dart';
import '../../data/database/app_database.dart';
import '../../domain/models/enums.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../addons/addons_screen.dart';
import '../audit/audit_trail_screen.dart';
import '../beans/beans_screen.dart';
import '../categories/categories_screen.dart';
import '../inventory/inventory_screen.dart';
import '../orders/orders_screen.dart';
import '../pos/pos_screen.dart';
import '../products/products_screen.dart';
import '../providers/app_providers.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../transactions/transactions_screen.dart';
import '../users/user_management_screen.dart';
import '../widgets/talaga_logo.dart';
import 'dashboard_overview_screen.dart';

class DashboardShell extends ConsumerWidget {
  const DashboardShell({super.key, required this.user});

  final UserRecord user;

  static final Map<AppDestination, GlobalKey> _destinationKeys = {
    for (final destination in AppDestination.values)
      destination: GlobalKey(debugLabel: 'workspace-${destination.name}'),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = UserRole.fromDb(user.role);
    final destinations = AppDestination.forRole(role);
    final selected = ref.watch(selectedDestinationProvider);
    final effectiveSelected = selected.isAllowed(role)
        ? selected
        : AppDestination.initialForRole(role);

    if (selected != effectiveSelected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(selectedDestinationProvider.notifier)
            .select(effectiveSelected);
      });
    }

    final isDark = ref.watch(darkModeProvider);
    final content = KeyedSubtree(
      key: _destinationKeys[effectiveSelected],
      child: _Content(destination: effectiveSelected, role: role),
    );
    final visualTheme = role == UserRole.admin
        ? AppTheme.admin(isDark)
        : AppTheme.cashier(isDark);

    return LayoutBuilder(
      builder: (context, constraints) => Theme(
        data: AppTheme.responsive(visualTheme, constraints.maxWidth),
        child: role == UserRole.admin
            ? _AdminWorkspaceShell(
                user: user,
                destinations: destinations,
                selected: effectiveSelected,
                content: content,
              )
            : _CashierWorkspaceShell(
                user: user,
                destinations: destinations,
                selected: effectiveSelected,
                content: content,
              ),
      ),
    );
  }
}

class _CashierWorkspaceShell extends ConsumerWidget {
  const _CashierWorkspaceShell({
    required this.user,
    required this.destinations,
    required this.selected,
    required this.content,
  });

  final UserRecord user;
  final List<AppDestination> destinations;
  final AppDestination selected;
  final Widget content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryDestinations = destinations
        .where((destination) => destination != AppDestination.settings)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final widthClass = AppLayout.widthClassFor(constraints.maxWidth);
        final compactHeight = AppLayout.isCompactHeight(constraints.maxHeight);
        final compactNavigation =
            widthClass == AppWidthClass.compact || compactHeight;
        final persistentDrawer =
            !compactHeight &&
            (widthClass == AppWidthClass.large ||
                widthClass == AppWidthClass.extraLarge);
        final showRail = !compactNavigation && !persistentDrawer;

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: compactNavigation && selected == AppDestination.settings
                ? IconButton(
                    tooltip: 'Kembali ke POS',
                    onPressed: () => _select(ref, AppDestination.pos),
                    icon: const Icon(Icons.arrow_back),
                  )
                : null,
            title: _WorkspaceTitle(
              title: selected == AppDestination.settings
                  ? 'Pengaturan Kasir'
                  : selected.label,
              subtitle: compactNavigation
                  ? null
                  : '${user.cashierName} • Kasir',
              showLogo: !compactNavigation,
            ),
            actions: [
              IconButton(
                icon: Icon(
                  ref.watch(darkModeProvider)
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
                tooltip: 'Ganti mode tampilan',
                onPressed: () => ref.read(darkModeProvider.notifier).toggle(),
              ),
              PopupMenuButton<_CashierMenuAction>(
                tooltip: 'Menu akun kasir',
                icon: const Icon(Icons.account_circle_outlined),
                onSelected: (action) {
                  switch (action) {
                    case _CashierMenuAction.settings:
                      _select(ref, AppDestination.settings);
                      return;
                    case _CashierMenuAction.logout:
                      ref.read(authControllerProvider.notifier).logout();
                      return;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Text('${user.cashierName} • Kasir'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: _CashierMenuAction.settings,
                    child: ListTile(
                      contentPadding: AppSpacing.zero,
                      leading: Icon(Icons.settings_outlined),
                      title: Text('Pengaturan'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: _CashierMenuAction.logout,
                    child: ListTile(
                      contentPadding: AppSpacing.zero,
                      leading: Icon(Icons.logout),
                      title: Text('Keluar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ),
          body: persistentDrawer
              ? Row(
                  children: [
                    _CashierNavigationPanel(
                      user: user,
                      selected: selected,
                      destinations: destinations,
                      onSelected: (destination) => _select(ref, destination),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: content),
                  ],
                )
              : showRail
              ? Row(
                  children: [
                    _AdaptiveNavigationRail(
                      selected: selected,
                      destinations: destinations,
                      onSelected: (destination) => _select(ref, destination),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: content),
                  ],
                )
              : content,
          bottomNavigationBar:
              compactNavigation &&
                  selected != AppDestination.settings &&
                  primaryDestinations.length >= 2
              ? NavigationBar(
                  height: AppLayout.cashierBottomDockHeight,
                  selectedIndex: primaryDestinations.indexOf(selected),
                  onDestinationSelected: (index) =>
                      _select(ref, primaryDestinations[index]),
                  destinations: [
                    for (final destination in primaryDestinations)
                      NavigationDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.icon),
                        label: destination.label,
                      ),
                  ],
                )
              : null,
        );
      },
    );
  }

  void _select(WidgetRef ref, AppDestination destination) {
    ref.read(selectedDestinationProvider.notifier).select(destination);
  }
}

enum _CashierMenuAction { settings, logout }

class _AdminWorkspaceShell extends ConsumerWidget {
  const _AdminWorkspaceShell({
    required this.user,
    required this.destinations,
    required this.selected,
    required this.content,
  });

  final UserRecord user;
  final List<AppDestination> destinations;
  final AppDestination selected;
  final Widget content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final widthClass = AppLayout.widthClassFor(constraints.maxWidth);
        final compactHeight = AppLayout.isCompactHeight(constraints.maxHeight);
        final compactNavigation =
            widthClass == AppWidthClass.compact || compactHeight;
        final persistentDrawer =
            !compactHeight &&
            (widthClass == AppWidthClass.large ||
                widthClass == AppWidthClass.extraLarge);
        final showRail = !compactNavigation && !persistentDrawer;

        return Scaffold(
          drawer: compactNavigation
              ? _AdminGroupedDrawer(
                  user: user,
                  selected: selected,
                  allowedDestinations: destinations,
                  onSelected: (destination) {
                    Navigator.of(context).pop();
                    _select(ref, destination);
                  },
                )
              : null,
          appBar: AppBar(
            automaticallyImplyLeading: compactNavigation,
            title: _WorkspaceTitle(
              title: compactNavigation ? selected.label : AppConstants.appName,
              subtitle: compactNavigation
                  ? null
                  : '${_groupFor(selected).label} • ${selected.label}',
              showLogo: !compactNavigation,
            ),
            actions: [
              if (!compactNavigation)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Center(
                    child: Text(
                      '${user.username} • Admin',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).appBarTheme.foregroundColor?.withValues(alpha: 0.78),
                      ),
                    ),
                  ),
                ),
              if (!compactNavigation) ...[
                IconButton(
                  icon: Icon(
                    ref.watch(darkModeProvider)
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                  ),
                  tooltip: 'Ganti mode tampilan',
                  onPressed: () => ref.read(darkModeProvider.notifier).toggle(),
                ),
                IconButton(
                  tooltip: 'Keluar',
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).logout(),
                  icon: const Icon(Icons.logout),
                ),
              ] else
                PopupMenuButton<_AdminMenuAction>(
                  tooltip: 'Menu akun admin',
                  icon: const Icon(Icons.account_circle_outlined),
                  onSelected: (action) {
                    switch (action) {
                      case _AdminMenuAction.toggleTheme:
                        ref.read(darkModeProvider.notifier).toggle();
                        return;
                      case _AdminMenuAction.logout:
                        ref.read(authControllerProvider.notifier).logout();
                        return;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      enabled: false,
                      child: Text('${user.username} • Admin'),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: _AdminMenuAction.toggleTheme,
                      child: ListTile(
                        contentPadding: AppSpacing.zero,
                        leading: Icon(
                          ref.watch(darkModeProvider)
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                        ),
                        title: const Text('Ganti mode tampilan'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: _AdminMenuAction.logout,
                      child: ListTile(
                        contentPadding: AppSpacing.zero,
                        leading: Icon(Icons.logout),
                        title: Text('Keluar'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ),
          body: persistentDrawer
              ? Row(
                  children: [
                    _AdminGroupedDrawer(
                      user: user,
                      selected: selected,
                      allowedDestinations: destinations,
                      persistent: true,
                      onSelected: (destination) => _select(ref, destination),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: content),
                  ],
                )
              : showRail
              ? Row(
                  children: [
                    _AdaptiveNavigationRail(
                      selected: selected,
                      destinations: destinations,
                      onSelected: (destination) => _select(ref, destination),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: content),
                  ],
                )
              : content,
        );
      },
    );
  }

  void _select(WidgetRef ref, AppDestination destination) {
    ref.read(selectedDestinationProvider.notifier).select(destination);
  }
}

enum _AdminMenuAction { toggleTheme, logout }

class _WorkspaceTitle extends StatelessWidget {
  const _WorkspaceTitle({
    required this.title,
    required this.subtitle,
    required this.showLogo,
  });

  final String title;
  final String? subtitle;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final foreground =
        Theme.of(context).appBarTheme.foregroundColor ??
        Theme.of(context).colorScheme.onSurface;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLogo) ...[
          const DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.cream100,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: AppSpacing.allXxs,
              child: TalagaLogo(size: AppSpacing.xxl),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: foreground),
              ),
              if (subtitle case final subtitle?)
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: foreground.withValues(alpha: 0.76),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdaptiveNavigationRail extends StatelessWidget {
  const _AdaptiveNavigationRail({
    required this.selected,
    required this.destinations,
    required this.onSelected,
  });

  final AppDestination selected;
  final List<AppDestination> destinations;
  final ValueChanged<AppDestination> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: AppLayout.navigationRailWidth,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.sm,
            ),
            itemCount: destinations.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xxs),
            itemBuilder: (context, index) {
              final destination = destinations[index];
              final isSelected = destination == selected;
              return Semantics(
                button: true,
                selected: isSelected,
                label: destination.label,
                child: Tooltip(
                  message: destination.label,
                  child: Material(
                    color: isSelected
                        ? scheme.primaryContainer
                        : AppColors.transparent,
                    borderRadius: AppRadius.input,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => onSelected(destination),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: AppLayout.cashierServiceBarHeight,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxs,
                            vertical: AppSpacing.xs,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                destination.icon,
                                color: isSelected
                                    ? scheme.onPrimaryContainer
                                    : scheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                destination.label,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: isSelected
                                          ? scheme.onPrimaryContainer
                                          : scheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
}

class _CashierNavigationPanel extends StatelessWidget {
  const _CashierNavigationPanel({
    required this.user,
    required this.selected,
    required this.destinations,
    required this.onSelected,
  });

  final UserRecord user;
  final AppDestination selected;
  final List<AppDestination> destinations;
  final ValueChanged<AppDestination> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppLayout.navigationDrawerWidth,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              _NavigationPanelHeader(
                title: 'Ruang Kasir',
                subtitle: user.cashierName,
              ),
              Expanded(
                child: ListView.separated(
                  padding: AppSpacing.allSm,
                  itemCount: destinations.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.xxs),
                  itemBuilder: (context, index) {
                    final destination = destinations[index];
                    return ListTile(
                      selected: destination == selected,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.input,
                      ),
                      leading: Icon(destination.icon),
                      title: Text(destination.label),
                      onTap: () => onSelected(destination),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminGroupedDrawer extends StatelessWidget {
  const _AdminGroupedDrawer({
    required this.user,
    required this.selected,
    required this.allowedDestinations,
    required this.onSelected,
    this.persistent = false,
  });

  final UserRecord user;
  final AppDestination selected;
  final List<AppDestination> allowedDestinations;
  final ValueChanged<AppDestination> onSelected;
  final bool persistent;

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: Column(
        children: [
          _NavigationPanelHeader(title: 'Ruang Admin', subtitle: user.username),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                for (final group in _adminGroups) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.xs,
                    ),
                    child: Text(
                      group.label.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  for (final destination in group.destinations)
                    if (allowedDestinations.contains(destination))
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        child: ListTile(
                          selected: destination == selected,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.input,
                          ),
                          leading: Icon(destination.icon),
                          title: Text(destination.label),
                          onTap: () => onSelected(destination),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (!persistent) {
      return Drawer(width: AppLayout.navigationDrawerWidth, child: body);
    }

    return SizedBox(
      width: AppLayout.navigationDrawerWidth,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: body,
      ),
    );
  }
}

class _NavigationPanelHeader extends StatelessWidget {
  const _NavigationPanelHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: AppSpacing.allLg,
      color: scheme.primaryContainer,
      child: Row(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.cream100,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: AppSpacing.allXxs,
              child: TalagaLogo(size: AppSpacing.section),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminNavigationGroup {
  const _AdminNavigationGroup({
    required this.label,
    required this.destinations,
  });

  final String label;
  final List<AppDestination> destinations;
}

const _adminGroups = [
  _AdminNavigationGroup(
    label: 'Pantau',
    destinations: [
      AppDestination.dashboard,
      AppDestination.pos,
      AppDestination.orders,
      AppDestination.transactions,
      AppDestination.reports,
    ],
  ),
  _AdminNavigationGroup(
    label: 'Menu & Racikan',
    destinations: [
      AppDestination.products,
      AppDestination.categories,
      AppDestination.addons,
      AppDestination.beans,
    ],
  ),
  _AdminNavigationGroup(
    label: 'Operasional',
    destinations: [
      AppDestination.inventory,
      AppDestination.users,
      AppDestination.auditTrail,
    ],
  ),
  _AdminNavigationGroup(
    label: 'Outlet',
    destinations: [AppDestination.settings],
  ),
];

_AdminNavigationGroup _groupFor(AppDestination destination) => _adminGroups
    .firstWhere((group) => group.destinations.contains(destination));

class _Content extends StatelessWidget {
  const _Content({required this.destination, required this.role});

  final AppDestination destination;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    if (!destination.isAllowed(role)) {
      return const Center(child: Text('Akses ditolak'));
    }
    return switch (destination) {
      AppDestination.dashboard => const DashboardOverviewScreen(),
      AppDestination.pos => const PosScreen(),
      AppDestination.orders => OrdersScreen(role: role),
      AppDestination.transactions => const TransactionsScreen(),
      AppDestination.reports => const ReportsScreen(),
      AppDestination.products => const ProductsScreen(),
      AppDestination.categories => const CategoriesScreen(),
      AppDestination.inventory => const InventoryScreen(),
      AppDestination.beans => const BeansScreen(),
      AppDestination.addons => const AddonsScreen(),
      AppDestination.users => UserManagementScreen(currentRole: role),
      AppDestination.auditTrail => const AuditTrailScreen(),
      AppDestination.settings => SettingsScreen(role: role),
    };
  }
}
