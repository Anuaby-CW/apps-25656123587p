import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_formatter.dart';
import '../../core/utils/error_message.dart';
import '../../data/database/app_database.dart';
import '../../domain/models/enums.dart';
import '../../theme/app_layout.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_role_tokens.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/app_page_frame.dart';
import '../../widgets/common/app_page_header.dart';
import '../../widgets/common/app_section_card.dart';
import '../../widgets/common/app_state_view.dart';
import '../../widgets/common/app_status_badge.dart';
import '../providers/app_providers.dart';

/// Workspace "Tim Outlet" untuk mengelola akun tanpa mengubah aturan role.
class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key, required this.currentRole});

  final UserRole currentRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);
    return AppPageFrame(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPageHeader(
            eyebrow: 'OPERASIONAL',
            title: 'Tim Outlet',
            description:
                'Atur akses admin dan kasir yang bekerja di Talaga Coffee.',
            action: FilledButton.icon(
              onPressed: () => _openUserDialog(context),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Tambah Pengguna'),
            ),
          ),
          SizedBox(height: AppRoleTokens.of(context).sectionGap),
          Expanded(
            child: users.when(
              loading: () => const AppLoadingState(
                message: 'Menyiapkan daftar tim outlet…',
              ),
              error: (error, _) => AppErrorState(
                message: ErrorMessage.from(error),
                onRetry: () => ref.invalidate(usersProvider),
              ),
              data: (rows) {
                if (rows.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.groups_outlined,
                    title: 'Tim outlet belum tersedia',
                    message:
                        'Tambahkan akun admin atau kasir untuk mulai bekerja.',
                    actionLabel: 'Tambah Pengguna',
                    onAction: () => _openUserDialog(context),
                  );
                }
                return _TeamOutletList(rows: rows);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamOutletList extends StatelessWidget {
  const _TeamOutletList({required this.rows});

  final List<UserRecord> rows;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        if (constraints.maxWidth >= AppLayout.expandedBreakpoint &&
            textScale <= 1.3) {
          return AppSectionCard(
            tone: AppSectionTone.plain,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _UserLedgerHeader(),
                const Divider(height: AppSpacing.xxs),
                Expanded(
                  child: ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, index) =>
                        _UserLedgerRow(user: rows[index]),
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          itemCount: rows.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) => _UserCompactCard(user: rows[index]),
        );
      },
    );
  }
}

class _UserLedgerHeader extends StatelessWidget {
  const _UserLedgerHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = AppTypography.label.copyWith(
      color: scheme.onPrimaryContainer,
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: AppRadius.input,
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('PENGGUNA', style: style)),
          Expanded(flex: 2, child: Text('ROLE', style: style)),
          Expanded(flex: 2, child: Text('STATUS', style: style)),
          Expanded(flex: 3, child: Text('MASUK TERAKHIR', style: style)),
          const SizedBox(width: AppSpacing.hero),
        ],
      ),
    );
  }
}

class _UserLedgerRow extends ConsumerWidget {
  const _UserLedgerRow({required this.user});

  final UserRecord user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = UserRole.fromDb(user.role);
    final isCurrentUser =
        ref.watch(authControllerProvider).value?.user?.id == user.id;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _UserAvatar(role: role),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    user.username,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyStrong,
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: _RoleBadge(role: role)),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Flexible(child: _ActiveBadge(isActive: user.isActive)),
                Switch(
                  value: user.isActive,
                  onChanged: isCurrentUser
                      ? null
                      : (value) => _setActive(context, ref, user, value),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              user.lastLoginAt == null
                  ? 'Belum pernah masuk'
                  : DateFormatter.human(user.lastLoginAt!),
              maxLines: 2,
              style: AppTypography.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(
            width: AppSpacing.hero,
            child: _UserActionMenu(user: user),
          ),
        ],
      ),
    );
  }
}

class _UserCompactCard extends ConsumerWidget {
  const _UserCompactCard({required this.user});

  final UserRecord user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = UserRole.fromDb(user.role);
    final isCurrentUser =
        ref.watch(authControllerProvider).value?.user?.id == user.id;
    return AppSectionCard(
      tone: AppSectionTone.plain,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UserAvatar(role: role),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.username, style: AppTypography.title),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _RoleBadge(role: role),
                        _ActiveBadge(isActive: user.isActive),
                      ],
                    ),
                  ],
                ),
              ),
              _UserActionMenu(user: user),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(
                Icons.history_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  user.lastLoginAt == null
                      ? 'Belum pernah masuk'
                      : 'Masuk terakhir ${DateFormatter.human(user.lastLoginAt!)}',
                  style: AppTypography.caption.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openUserDialog(context, user: user),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit pengguna'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(user.isActive ? 'Aktif' : 'Nonaktif'),
              Switch(
                value: user.isActive,
                onChanged: isCurrentUser
                    ? null
                    : (value) => _setActive(context, ref, user, value),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: AppRadius.input,
      ),
      child: Padding(
        padding: AppSpacing.allSm,
        child: Icon(
          role == UserRole.admin
              ? Icons.admin_panel_settings_outlined
              : Icons.person_outline,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return AppStatusBadge(
      label: role.label,
      status: role == UserRole.admin ? AppStatus.info : AppStatus.neutral,
      icon: role == UserRole.admin
          ? Icons.shield_outlined
          : Icons.point_of_sale_outlined,
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AppStatusBadge(
      label: isActive ? 'Aktif' : 'Nonaktif',
      status: isActive ? AppStatus.success : AppStatus.neutral,
    );
  }
}

enum _UserAction { edit, delete }

class _UserActionMenu extends ConsumerWidget {
  const _UserActionMenu({required this.user});

  final UserRecord user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrentUser =
        ref.watch(authControllerProvider).value?.user?.id == user.id;
    return PopupMenuButton<_UserAction>(
      tooltip: 'Tindakan pengguna',
      onSelected: (action) {
        switch (action) {
          case _UserAction.edit:
            _openUserDialog(context, user: user);
          case _UserAction.delete:
            _confirmDelete(context, ref, user);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _UserAction.edit,
          child: ListTile(
            contentPadding: AppSpacing.zero,
            leading: Icon(Icons.edit_outlined),
            title: Text('Edit'),
          ),
        ),
        if (!isCurrentUser)
          PopupMenuItem(
            value: _UserAction.delete,
            child: ListTile(
              contentPadding: AppSpacing.zero,
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Hapus',
                style: AppTypography.bodyStrong.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Future<void> _setActive(
  BuildContext context,
  WidgetRef ref,
  UserRecord user,
  bool value,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final actorUserId = ref.read(authControllerProvider).value?.user?.id;
    if (actorUserId == null) {
      throw StateError('Sesi admin tidak tersedia');
    }
    await ref
        .read(userRepositoryProvider)
        .setActive(user, value, actorUserId: actorUserId);
    ref.invalidate(usersProvider);
  } catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(ErrorMessage.from(error))));
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  UserRecord user,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Hapus Pengguna'),
      content: SingleChildScrollView(
        child: Text(
          'Hapus akun ${user.username}? Tindakan ini tidak dapat dibatalkan.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
            foregroundColor: Theme.of(dialogContext).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Hapus'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    try {
      final actorUserId = ref.read(authControllerProvider).value?.user?.id;
      if (actorUserId == null) {
        throw StateError('Sesi admin tidak tersedia');
      }
      await ref
          .read(userRepositoryProvider)
          .deleteUser(user.id, actorUserId: actorUserId);
      ref.invalidate(usersProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Pengguna berhasil dihapus')),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(ErrorMessage.from(error))));
    }
  }
}

Future<void> _openUserDialog(BuildContext context, {UserRecord? user}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _UserDialog(user: user),
  );
}

class _UserDialog extends ConsumerStatefulWidget {
  const _UserDialog({this.user});

  final UserRecord? user;

  @override
  ConsumerState<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends ConsumerState<_UserDialog> {
  late final TextEditingController _username;
  late final TextEditingController _password;
  UserRole _role = UserRole.cashier;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _username = TextEditingController(text: widget.user?.username ?? '');
    _password = TextEditingController();
    _role = widget.user == null
        ? UserRole.cashier
        : UserRole.fromDb(widget.user!.role);
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;
    final editingSelf =
        isEdit &&
        ref.watch(authControllerProvider).value?.user?.id == widget.user!.id;
    final compact = AppLayout.isCompact(MediaQuery.sizeOf(context).width);
    final form = _UserForm(
      username: _username,
      password: _password,
      role: _role,
      isEdit: isEdit,
      lockedIdentity: editingSelf,
      onRoleChanged: (role) => setState(() => _role = role),
    );

    if (compact) {
      return Dialog.fullscreen(
        child: SafeArea(
          child: Scaffold(
            appBar: AppBar(
              title: Text(isEdit ? 'Edit Pengguna' : 'Tambah Pengguna'),
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
            body: SingleChildScrollView(
              padding: AppSpacing.allMd,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: form,
            ),
            bottomNavigationBar: SafeArea(
              minimum: AppSpacing.allMd,
              child: _UserDialogActions(
                isEdit: isEdit,
                saving: _saving,
                onResetPassword: () => _resetPassword(context),
                onCancel: () => Navigator.of(context).pop(),
                onSave: editingSelf ? null : _save,
              ),
            ),
          ),
        ),
      );
    }

    return AlertDialog(
      title: Text(isEdit ? 'Edit Pengguna' : 'Tambah Pengguna'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppLayout.dialogSmallMaxWidth,
        ),
        child: SingleChildScrollView(child: form),
      ),
      actions: [
        _UserDialogActions(
          isEdit: isEdit,
          saving: _saving,
          onResetPassword: () => _resetPassword(context),
          onCancel: () => Navigator.of(context).pop(),
          onSave: editingSelf ? null : _save,
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      if (widget.user == null) {
        await ref
            .read(userRepositoryProvider)
            .createUser(
              username: _username.text,
              password: _password.text,
              role: _role,
            );
      } else {
        final actorUserId = ref.read(authControllerProvider).value?.user?.id;
        if (actorUserId == null) {
          throw StateError('Sesi admin tidak tersedia');
        }
        await ref
            .read(userRepositoryProvider)
            .updateUser(
              user: widget.user!,
              username: _username.text,
              role: _role,
              actorUserId: actorUserId,
            );
      }
      ref.invalidate(usersProvider);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(ErrorMessage.from(error))));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _resetPassword(BuildContext context) async {
    final password = TextEditingController();
    final user = widget.user;
    if (user == null) {
      password.dispose();
      return;
    }
    final formKey = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Atur Ulang Kata Sandi'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppLayout.dialogSmallMaxWidth,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: TextFormField(
                controller: password,
                decoration: const InputDecoration(
                  labelText: 'Kata sandi baru',
                  helperText: 'Minimal 6 karakter',
                ),
                obscureText: true,
                validator: (value) => (value ?? '').length < 6
                    ? 'Kata sandi minimal 6 karakter'
                    : null,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    final value = password.text;
    password.dispose();
    if (confirmed == true && value.isNotEmpty) {
      try {
        await ref.read(userRepositoryProvider).resetPassword(user, value);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kata sandi berhasil diatur ulang')),
          );
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(ErrorMessage.from(error))));
        }
      }
    }
  }
}

class _UserForm extends StatelessWidget {
  const _UserForm({
    required this.username,
    required this.password,
    required this.role,
    required this.isEdit,
    required this.lockedIdentity,
    required this.onRoleChanged,
  });

  final TextEditingController username;
  final TextEditingController password;
  final UserRole role;
  final bool isEdit;
  final bool lockedIdentity;
  final ValueChanged<UserRole> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Identitas akun', style: AppTypography.title),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: username,
          enabled: !lockedIdentity,
          decoration: const InputDecoration(labelText: 'Nama pengguna'),
        ),
        if (lockedIdentity) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Nama pengguna, peran, dan status akun yang sedang digunakan dilindungi. Anda tetap dapat mengatur ulang kata sandi.',
            style: AppTypography.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (!isEdit) ...[
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: password,
            decoration: const InputDecoration(labelText: 'Kata sandi'),
            obscureText: true,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Text('Akses kerja', style: AppTypography.title),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          role == UserRole.admin
              ? 'Admin memantau laporan dan mengelola data outlet.'
              : 'Kasir menangani POS dan pesanan pelanggan.',
          style: AppTypography.caption.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<UserRole>(
          segments: const [
            ButtonSegment(
              value: UserRole.admin,
              label: Text('Admin'),
              icon: Icon(Icons.admin_panel_settings_outlined),
            ),
            ButtonSegment(
              value: UserRole.cashier,
              label: Text('Kasir'),
              icon: Icon(Icons.point_of_sale_outlined),
            ),
          ],
          selected: {role},
          onSelectionChanged: lockedIdentity
              ? null
              : (value) => onRoleChanged(value.first),
        ),
      ],
    );
  }
}

class _UserDialogActions extends StatelessWidget {
  const _UserDialogActions({
    required this.isEdit,
    required this.saving,
    required this.onResetPassword,
    required this.onCancel,
    required this.onSave,
  });

  final bool isEdit;
  final bool saving;
  final VoidCallback onResetPassword;
  final VoidCallback onCancel;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      alignment: WrapAlignment.end,
      children: [
        if (isEdit)
          TextButton(
            onPressed: saving ? null : onResetPassword,
            child: const Text('Atur Ulang Kata Sandi'),
          ),
        OutlinedButton(
          onPressed: saving ? null : onCancel,
          child: const Text('Batal'),
        ),
        SizedBox(
          height: AppLayout.adminPrimaryControlHeight,
          child: FilledButton.icon(
            onPressed: saving ? null : onSave,
            icon: saving
                ? const SizedBox.square(
                    dimension: AppSpacing.lg,
                    child: CircularProgressIndicator(
                      strokeWidth: AppLayout.progressStrokeWidth,
                    ),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(saving ? 'Menyimpan…' : 'Simpan'),
          ),
        ),
      ],
    );
  }
}
