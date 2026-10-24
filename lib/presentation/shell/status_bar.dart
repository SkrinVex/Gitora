import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitora/application/providers/current_repo_provider.dart';
import 'package:gitora/application/providers/git_status_provider.dart';
import 'package:gitora/application/providers/git_tasks_provider.dart';
import 'package:gitora/application/providers/settings_provider.dart';
import 'package:gitora/core/theme/app_colors.dart';
import 'package:gitora/infrastructure/git/hybrid_git_service.dart';

class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final taskState = ref.watch(gitTaskProvider);
    final statusAsync = ref.watch(gitStatusProvider);
    final settings = ref.watch(settingsProvider);
    final currentRepo = ref.watch(currentRepoProvider);

    String backendText = 'Engine: ';
    switch (settings.backendMode) {
      case GitBackendMode.auto:
        backendText += 'Hybrid (LibGit2 + CLI)';
        break;
      case GitBackendMode.libgit2Only:
        backendText += 'LibGit2';
        break;
      case GitBackendMode.cliOnly:
        backendText += 'Git CLI';
        break;
    }

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(80),
          ),
        ),
      ),
      child: Row(
        children: [
          // Background task running indicator
          if (taskState.isRunning) ...[
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              taskState.taskTitle ?? 'Working...',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            if (taskState.progressMessage != null &&
                taskState.progressMessage!.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                '• ${taskState.progressMessage}',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
            const SizedBox(width: 16),
          ] else if (taskState.lastError != null) ...[
            Icon(Icons.error_outline, size: 14, color: theme.colorScheme.error),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                taskState.lastError!,
                style: TextStyle(fontSize: 11, color: theme.colorScheme.error),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else if (taskState.lastSuccess != null) ...[
            Icon(
              Icons.check_circle_outline,
              size: 14,
              color: AppColors.gitAdded,
            ),
            const SizedBox(width: 6),
            Text(
              taskState.lastSuccess!,
              style: const TextStyle(fontSize: 11, color: AppColors.gitAdded),
            ),
          ],

          const Spacer(),

          // Status of active repository
          if (currentRepo != null) ...[
            statusAsync.when(
              data: (status) {
                if (status == null) return const SizedBox.shrink();

                return Row(
                  children: [
                    if (status.totalChanges > 0) ...[
                      Icon(
                        Icons.edit_note,
                        size: 14,
                        color: AppColors.gitModified,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${status.totalChanges} uncommitted',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (status.ahead > 0) ...[
                      const Icon(
                        Icons.arrow_upward,
                        size: 12,
                        color: AppColors.gitAdded,
                      ),
                      Text(
                        '${status.ahead}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.gitAdded,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (status.behind > 0) ...[
                      const Icon(
                        Icons.arrow_downward,
                        size: 12,
                        color: AppColors.gitDeleted,
                      ),
                      Text(
                        '${status.behind}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.gitDeleted,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
            ),
          ],

          // Backend text
          Text(
            backendText,
            style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }
}
