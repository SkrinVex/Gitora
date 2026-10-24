import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitora/application/providers/current_repo_provider.dart';
import 'package:gitora/application/providers/git_diff_provider.dart';
import 'package:gitora/application/providers/git_service_provider.dart';
import 'package:gitora/application/providers/git_status_provider.dart';
import 'package:gitora/application/providers/git_tasks_provider.dart';
import 'package:gitora/core/theme/app_colors.dart';
import 'package:gitora/domain/models/git_file_change.dart';
import 'package:gitora/l10n/app_localizations.dart';
import 'package:gitora/presentation/screens/changes/commit_panel.dart';
import 'package:gitora/presentation/screens/changes/diff_viewer.dart';
import 'package:gitora/presentation/widgets/confirm_dialog.dart';

class ChangesScreen extends ConsumerStatefulWidget {
  const ChangesScreen({super.key});

  @override
  ConsumerState<ChangesScreen> createState() => _ChangesScreenState();
}

class _ChangesScreenState extends ConsumerState<ChangesScreen> {
  final double _fileListWidth = 320;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusAsync = ref.watch(gitStatusProvider);
    final theme = Theme.of(context);
    final selectedTarget = ref.watch(selectedDiffTargetProvider);
    final diffAsync = ref.watch(gitDiffProvider);

    return statusAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Error loading status: $e',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      ),
      data: (status) {
        if (status == null) {
          return Center(
            child: Text(
              l10n.noRecentRepositories,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          );
        }

        final allUnstaged = [...status.unstaged, ...status.untracked];

        return Row(
          children: [
            // Left sidebar: Files list
            SizedBox(
              width: _fileListWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  border: Border(
                    right: BorderSide(
                      color: theme.colorScheme.outlineVariant.withAlpha(80),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Toolbar
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        border: Border(
                          bottom: BorderSide(
                            color: theme.colorScheme.outlineVariant.withAlpha(
                              80,
                            ),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            l10n.workingTree,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          // Stage All
                          IconButton(
                            icon: const Icon(Icons.playlist_add, size: 18),
                            tooltip: l10n.stageAll,
                            visualDensity: VisualDensity.compact,
                            onPressed: allUnstaged.isNotEmpty
                                ? () => _stageAll()
                                : null,
                          ),
                          // Unstage All
                          IconButton(
                            icon: const Icon(Icons.playlist_remove, size: 18),
                            tooltip: l10n.unstageAll,
                            visualDensity: VisualDensity.compact,
                            onPressed: status.staged.isNotEmpty
                                ? () => _unstageAll()
                                : null,
                          ),
                          // Discard All
                          IconButton(
                            icon: const Icon(
                              Icons.delete_sweep_outlined,
                              size: 18,
                            ),
                            tooltip: l10n.discardAll,
                            visualDensity: VisualDensity.compact,
                            onPressed: allUnstaged.isNotEmpty
                                ? () => _discardAll(l10n)
                                : null,
                          ),
                        ],
                      ),
                    ),

                    // File list
                    Expanded(
                      child: status.isClean
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 40,
                                      color: AppColors.gitAdded,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      l10n.noChangesTitle,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.noChangesSubtitle,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.outline,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              children: [
                                // Staged Changes Group
                                if (status.staged.isNotEmpty) ...[
                                  _buildGroupHeader(
                                    title: l10n.stagedChanges,
                                    count: status.staged.length,
                                    theme: theme,
                                    isStaged: true,
                                  ),
                                  for (final file in status.staged)
                                    _buildFileItem(
                                      file: file,
                                      isStaged: true,
                                      isSelected:
                                          selectedTarget?.filePath ==
                                              file.path &&
                                          selectedTarget?.isStaged == true,
                                      l10n: l10n,
                                      theme: theme,
                                    ),
                                  const SizedBox(height: 12),
                                ],

                                // Unstaged Changes Group
                                if (allUnstaged.isNotEmpty) ...[
                                  _buildGroupHeader(
                                    title: l10n.unstagedChanges,
                                    count: allUnstaged.length,
                                    theme: theme,
                                    isStaged: false,
                                  ),
                                  for (final file in allUnstaged)
                                    _buildFileItem(
                                      file: file,
                                      isStaged: false,
                                      isSelected:
                                          selectedTarget?.filePath ==
                                              file.path &&
                                          selectedTarget?.isStaged == false,
                                      l10n: l10n,
                                      theme: theme,
                                    ),
                                ],
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Right side: Diff Viewer and Commit Panel
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: selectedTarget == null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.difference_outlined,
                                  size: 48,
                                  color: theme.colorScheme.outlineVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.noChangesSelected,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : diffAsync.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, _) =>
                                Center(child: Text('Error loading diff: $e')),
                            data: (diff) => diff == null
                                ? const SizedBox.shrink()
                                : DiffViewer(
                                    diff: diff,
                                    isStaged: selectedTarget.isStaged,
                                  ),
                          ),
                  ),

                  // Bottom Commit Panel
                  CommitPanel(
                    branchName: status.branchName,
                    stagedCount: status.staged.length,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGroupHeader({
    required String title,
    required int count,
    required ThemeData theme,
    required bool isStaged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isStaged
                  ? AppColors.gitAdded
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: (isStaged ? AppColors.gitAdded : theme.colorScheme.outline)
                  .withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isStaged
                    ? AppColors.gitAdded
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem({
    required GitFileChange file,
    required bool isStaged,
    required bool isSelected,
    required AppLocalizations l10n,
    required ThemeData theme,
  }) {
    Color statusColor;
    switch (file.status) {
      case GitFileStatus.added:
        statusColor = AppColors.gitAdded;
        break;
      case GitFileStatus.modified:
        statusColor = AppColors.gitModified;
        break;
      case GitFileStatus.deleted:
        statusColor = AppColors.gitDeleted;
        break;
      case GitFileStatus.renamed:
        statusColor = AppColors.gitRenamed;
        break;
      case GitFileStatus.untracked:
        statusColor = AppColors.gitUntracked;
        break;
      default:
        statusColor = AppColors.gitIgnored;
    }

    return InkWell(
      onTap: () {
        ref.read(selectedDiffTargetProvider.notifier).state =
            SelectedDiffTarget(filePath: file.path, isStaged: isStaged);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.secondaryContainer.withAlpha(120)
              : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            // Status code letter badge
            Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: statusColor.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                file.statusLetter,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // File path
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.fileName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.onSecondaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (file.directory.isNotEmpty)
                    Text(
                      file.directory,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.outline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Actions: Stage / Unstage / Discard
            if (isStaged)
              IconButton(
                icon: const Icon(Icons.remove, size: 16),
                tooltip: l10n.unstageFile,
                visualDensity: VisualDensity.compact,
                onPressed: () => _unstageFile(file.path),
              )
            else ...[
              IconButton(
                icon: const Icon(Icons.add, size: 16),
                tooltip: l10n.stageFile,
                visualDensity: VisualDensity.compact,
                onPressed: () => _stageFile(file.path),
              ),
              IconButton(
                icon: const Icon(Icons.undo, size: 15),
                tooltip: l10n.discardFile,
                visualDensity: VisualDensity.compact,
                onPressed: () => _discardFile(file.path, l10n),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _stageFile(String filePath) async {
    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: 'Staging file',
          action: (progress) async {
            final gitService = ref.read(gitServiceProvider);
            await gitService.stageFile(repoPath, filePath);
            ref.read(currentRepoProvider.notifier).refresh();
          },
        );
  }

  Future<void> _unstageFile(String filePath) async {
    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: 'Unstaging file',
          action: (progress) async {
            final gitService = ref.read(gitServiceProvider);
            await gitService.unstageFile(repoPath, filePath);
            ref.read(currentRepoProvider.notifier).refresh();
          },
        );
  }

  Future<void> _stageAll() async {
    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: 'Staging all changes',
          action: (progress) async {
            final gitService = ref.read(gitServiceProvider);
            await gitService.stageAll(repoPath);
            ref.read(currentRepoProvider.notifier).refresh();
          },
        );
  }

  Future<void> _unstageAll() async {
    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: 'Unstaging all changes',
          action: (progress) async {
            final gitService = ref.read(gitServiceProvider);
            await gitService.unstageAll(repoPath);
            ref.read(currentRepoProvider.notifier).refresh();
          },
        );
  }

  Future<void> _discardFile(String filePath, AppLocalizations l10n) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: l10n.discardConfirmTitle(filePath),
      message: l10n.discardConfirmMessage,
      confirmLabel: l10n.discard,
      type: ConfirmDialogType.danger,
    );

    if (!confirmed) return;

    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: 'Discarding file changes',
          action: (progress) async {
            final gitService = ref.read(gitServiceProvider);
            await gitService.discardFileChanges(repoPath, filePath);
            ref.read(currentRepoProvider.notifier).refresh();
          },
        );
  }

  Future<void> _discardAll(AppLocalizations l10n) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: l10n.discardAllConfirmTitle,
      message: l10n.discardAllConfirmMessage,
      confirmLabel: l10n.discardAll,
      type: ConfirmDialogType.danger,
    );

    if (!confirmed) return;

    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: 'Discarding all changes',
          action: (progress) async {
            final gitService = ref.read(gitServiceProvider);
            await gitService.discardAllChanges(repoPath);
            ref.read(currentRepoProvider.notifier).refresh();
          },
        );
  }
}
