import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_strings.dart';
import '../../core/di/injection.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../auth/cubit/auth_cubit.dart';
import '../auth/cubit/auth_state.dart';
import 'cubit/settings_cubit.dart';
import 'cubit/settings_state.dart';

/// Settings screen — profile, notifications, sync, app info, logout.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SettingsCubit>()..load(),
      child: const _SettingsBody(),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile section
              _SectionCard(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          user?.name.substring(0, 1).toUpperCase() ?? '?',
                          style: AppTypography.h2
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Employee',
                              style: AppTypography.body1.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? '',
                              style: AppTypography.body2.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notification settings
              _SectionCard(
                children: [
                  _SectionHeader(title: AppStrings.notificationSettings),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        state.notificationsEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_off,
                        color: state.notificationsEnabled
                            ? AppColors.primary
                            : AppColors.disabled,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.notificationsEnabled
                              ? AppStrings.notificationsEnabled
                              : AppStrings.notificationsDisabled,
                          style: AppTypography.body2,
                        ),
                      ),
                      if (!state.notificationsEnabled)
                        TextButton(
                          onPressed: () {
                            AppSettings.openAppSettings(
                              type: AppSettingsType.notification,
                            );
                          },
                          child: const Text(
                            AppStrings.enableNotifications,
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sync status
              _SectionCard(
                children: [
                  _SectionHeader(title: AppStrings.syncStatus),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.sync,
                        color: state.isSyncing
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.lastSynced,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              state.lastSyncAt != null
                                  ? DateFormat.yMMMd()
                                      .add_jm()
                                      .format(state.lastSyncAt!)
                                  : AppStrings.neverSynced,
                              style: AppTypography.body2,
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: state.isSyncing
                            ? null
                            : () =>
                                context.read<SettingsCubit>().syncNow(),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: state.isSyncing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                AppStrings.syncNow,
                                style: TextStyle(fontSize: 13),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // App info
              _SectionCard(
                children: [
                  _SectionHeader(title: AppStrings.appInfo),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(AppStrings.version, style: AppTypography.body2),
                      const Spacer(),
                      Text(
                        state.appVersion ?? '1.0.0',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Logout button
              _SectionCard(
                children: [
                  InkWell(
                    onTap: () => _confirmLogout(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.logout,
                            color: AppColors.statusOverdue,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppStrings.logout,
                            style: AppTypography.body1.copyWith(
                              color: AppColors.statusOverdue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.logout),
        content: const Text(AppStrings.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().logout();
            },
            child: Text(
              AppStrings.logout,
              style: const TextStyle(color: AppColors.statusOverdue),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.body1.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
