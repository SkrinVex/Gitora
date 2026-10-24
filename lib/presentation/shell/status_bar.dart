import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitora/application/providers/current_repo_provider.dart';
import 'package:gitora/application/providers/git_service_provider.dart';
import 'package:gitora/application/providers/repository_state_provider.dart';
import 'package:gitora/application/providers/git_tasks_provider.dart';
import 'package:gitora/core/theme/app_colors.dart';
import 'package:gitora/application/providers/log_provider.dart';

class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final taskState = ref.watch(gitTaskProvider);
    final repoState = ref.watch(repositoryStateProvider);
    final logState = ref.watch(logProvider);
    final currentRepo = ref.watch(currentRepoProvider);

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
                value: taskState.progressPercent,
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
            if (taskState.progressPercent != null) ...[
              const SizedBox(width: 6),
              Text(
                '${(taskState.progressPercent! * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            if (taskState.progressMessage != null &&
                taskState.progressMessage!.isNotEmpty) ...[
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  '• ${taskState.progressMessage}',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.outline,
                  ),
                  overflow: TextOverflow.ellipsis,
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
          if (currentRepo != null && repoState.repoPath == currentRepo) ...[
            Row(
              children: [
                if (repoState.totalChanges > 0) ...[
                  Icon(Icons.edit_note, size: 14, color: AppColors.gitModified),
                  const SizedBox(width: 4),
                  Text(
                    '${repoState.totalChanges} uncommitted',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (repoState.ahead > 0) ...[
                  InkWell(
                    onTap: () {
                      final repoPath = ref.read(currentRepoProvider);
                      if (repoPath != null && !taskState.isRunning) {
                        ref
                            .read(gitTaskProvider.notifier)
                            .run(
                              title: 'Pushing changes',
                              action: (progress) async {
                                final git = ref.read(gitServiceProvider);
                                await git.push(
                                  repoPath,
                                  onProgress: progress,
                                );
                                ref
                                    .read(currentRepoProvider.notifier)
                                    .refresh();
                              },
                            );
                      }
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Tooltip(
                      message:
                          '${repoState.ahead} commit(s) ahead — click to Push',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.arrow_upward,
                              size: 12,
                              color: AppColors.gitAdded,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${repoState.ahead} push',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gitAdded,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (repoState.behind > 0) ...[
                  const Icon(
                    Icons.arrow_downward,
                    size: 12,
                    color: AppColors.gitDeleted,
                  ),
                  Text(
                    '${repoState.behind}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.gitDeleted,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ],
            ),
          ],

          // Output / Logs panel toggle
          InkWell(
            onTap: () => ref.read(logProvider.notifier).togglePanel(),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    logState.errorCount > 0
                        ? Icons.error_outline
                        : Icons.terminal,
                    size: 13,
                    color: logState.errorCount > 0
                        ? AppColors.gitDeleted
                        : theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    logState.errorCount > 0 ? '${logState.errorCount}' : 'Logs',
                    style: TextStyle(
                      fontSize: 11,
                      color: logState.errorCount > 0
                          ? AppColors.gitDeleted
                          : theme.colorScheme.outline,
                      fontWeight: logState.errorCount > 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),

          // by SkrinVex
          Text(
            'by SkrinVex',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary.withAlpha(200),
            ),
          ),
        ],
      ),
    );
  }
}
