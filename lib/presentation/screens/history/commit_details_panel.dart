import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gitora/application/providers/current_repo_provider.dart';
import 'package:gitora/application/providers/git_diff_provider.dart';
import 'package:gitora/application/providers/git_history_provider.dart';
import 'package:gitora/application/providers/git_service_provider.dart';
import 'package:gitora/application/providers/git_tasks_provider.dart';
import 'package:gitora/core/theme/app_colors.dart';
import 'package:gitora/domain/models/git_commit.dart';
import 'package:gitora/domain/models/git_file_change.dart';
import 'package:gitora/l10n/app_localizations.dart';
import 'package:gitora/presentation/screens/changes/diff_viewer.dart';
import 'package:gitora/presentation/widgets/confirm_dialog.dart';

class CommitDetailsPanel extends ConsumerWidget {
  final GitCommit commit;

  const CommitDetailsPanel({super.key, required this.commit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final filesAsync = ref.watch(selectedCommitFilesProvider);
    final selectedTarget = ref.watch(selectedDiffTargetProvider);
    final diffAsync = ref.watch(gitDiffProvider);

    final dateFormat = DateFormat.yMMMMd().add_jms();
    final formattedDate = dateFormat.format(commit.date);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(80),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Commit info
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withAlpha(80),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Avatar + Author + Actions
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        commit.authorName.isNotEmpty
                            ? commit.authorName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            commit.authorName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            commit.authorEmail,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Action buttons
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (val) {
                        if (val == 'checkout') {
                          _checkout(context, ref, l10n);
                        } else if (val == 'cherryPick') {
                          _cherryPick(context, ref, l10n);
                        } else if (val == 'revert') {
                          _revert(context, ref, l10n);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'checkout',
                          child: Row(
                            children: [
                              const Icon(Icons.input, size: 18),
                              const SizedBox(width: 8),
                              Text(l10n.checkoutCommit),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'cherryPick',
                          child: Row(
                            children: [
                              const Icon(Icons.content_copy, size: 18),
                              const SizedBox(width: 8),
                              Text(l10n.cherryPickCommit),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'revert',
                          child: Row(
                            children: [
                              const Icon(Icons.undo, size: 18),
                              const SizedBox(width: 8),
                              Text(l10n.revertCommit),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Commit message
                SelectableText(
                  commit.summary,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (commit.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  SelectableText(
                    commit.description,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                ],

                const SizedBox(height: 12),

                // Meta: SHA + Date
                Row(
                  children: [
                    // Copy SHA chip
                    ActionChip(
                      avatar: const Icon(Icons.tag, size: 14),
                      label: Text(
                        commit.shortHash,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                        ),
                      ),
                      tooltip: l10n.copySha,
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: commit.hash));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Commit SHA copied'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: theme.colorScheme.outline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Changed Files & Diff preview
          Expanded(
            child: filesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading files: $e')),
              data: (files) {
                if (files.isEmpty) {
                  return const Center(
                    child: Text('No files changed in this commit'),
                  );
                }

                return Row(
                  children: [
                    // Files list
                    SizedBox(
                      width: 260,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: theme.colorScheme.outlineVariant.withAlpha(
                                80,
                              ),
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Text(
                                '${l10n.changedFiles} (${files.length})',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: files.length,
                                itemBuilder: (context, index) {
                                  final file = files[index];
                                  final isSelected =
                                      selectedTarget?.filePath == file.path &&
                                      selectedTarget?.commitHash == commit.hash;

                                  return InkWell(
                                    onTap: () {
                                      ref
                                          .read(
                                            selectedDiffTargetProvider.notifier,
                                          )
                                          .state = SelectedDiffTarget(
                                        filePath: file.path,
                                        commitHash: commit.hash,
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      color: isSelected
                                          ? theme.colorScheme.secondaryContainer
                                                .withAlpha(120)
                                          : null,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 18,
                                            height: 18,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                file.status,
                                              ).withAlpha(30),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              file.statusLetter,
                                              style: TextStyle(
                                                color: _getStatusColor(
                                                  file.status,
                                                ),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              file.fileName,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Diff viewer for selected commit file
                    Expanded(
                      child:
                          selectedTarget == null ||
                              selectedTarget.commitHash != commit.hash
                          ? Center(
                              child: Text(
                                l10n.noChangesSelected,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
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
                                  : DiffViewer(diff: diff, isStaged: false),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(GitFileStatus status) {
    switch (status) {
      case GitFileStatus.added:
        return AppColors.gitAdded;
      case GitFileStatus.modified:
        return AppColors.gitModified;
      case GitFileStatus.deleted:
        return AppColors.gitDeleted;
      case GitFileStatus.renamed:
        return AppColors.gitRenamed;
      default:
        return AppColors.gitIgnored;
    }
  }

  Future<void> _checkout(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: 'Checkout commit',
          action: (progress) async {
            final git = ref.read(gitServiceProvider);
            await git.checkout(repoPath, commit.hash);
            ref.read(currentRepoProvider.notifier).refresh();
          },
        );
  }

  Future<void> _cherryPick(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: 'Cherry-pick commit',
          action: (progress) async {
            final git = ref.read(gitServiceProvider);
            await git.cherryPick(repoPath, commit.hash);
            ref.read(currentRepoProvider.notifier).refresh();
          },
        );
  }

  Future<void> _revert(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Revert commit?',
      message:
          'This will create an inverse commit to revert changes from ${commit.shortHash}.',
      confirmLabel: 'Revert',
    );
    if (!confirmed) return;

    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: 'Revert commit',
          action: (progress) async {
            final git = ref.read(gitServiceProvider);
            await git.revert(repoPath, commit.hash);
            ref.read(currentRepoProvider.notifier).refresh();
          },
        );
  }
}
