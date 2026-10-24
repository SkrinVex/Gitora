import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitora/application/providers/current_repo_provider.dart';
import 'package:gitora/application/providers/git_remotes_provider.dart';
import 'package:gitora/application/providers/git_service_provider.dart';
import 'package:gitora/application/providers/git_status_provider.dart';
import 'package:gitora/application/providers/git_tasks_provider.dart';
import 'package:gitora/core/theme/app_colors.dart';
import 'package:gitora/l10n/app_localizations.dart';
import 'package:gitora/presentation/screens/remotes/add_remote_dialog.dart';
import 'package:gitora/presentation/widgets/confirm_dialog.dart';

class RemotesScreen extends ConsumerWidget {
  const RemotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final remotesAsync = ref.watch(gitRemotesProvider);
    final statusAsync = ref.watch(gitStatusProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Top action bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withAlpha(80),
                ),
              ),
            ),
            child: Row(
              children: [
                Text(l10n.remotes, style: theme.textTheme.titleMedium),
                const Spacer(),
                // Global Fetch button
                OutlinedButton.icon(
                  onPressed: () => _fetch(ref, null),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text(l10n.fetch),
                ),
                const SizedBox(width: 8),
                // Pull button
                OutlinedButton.icon(
                  onPressed: () => _pull(ref, null),
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  label: Text(l10n.pull),
                ),
                const SizedBox(width: 8),
                // Push button
                FilledButton.icon(
                  onPressed: () => _push(context, ref, null, false, l10n),
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  label: Text(l10n.push),
                ),
                const SizedBox(width: 12),
                // Add Remote button
                IconButton.filledTonal(
                  onPressed: () => _addRemote(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  tooltip: l10n.addRemote,
                ),
              ],
            ),
          ),

          // Sync status banner if configured
          statusAsync.when(
            skipLoadingOnReload: true,
            loading: () => const SizedBox.shrink(),
            error: (e, st) => const SizedBox.shrink(),
            data: (status) {
              if (status == null || status.upstream == null) {
                return const SizedBox.shrink();
              }

              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withAlpha(80),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_sync,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tracking ${status.upstream}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            status.ahead == 0 && status.behind == 0
                                ? l10n.upToDate
                                : '${status.ahead > 0 ? l10n.aheadBy(status.ahead) : ""} ${status.behind > 0 ? l10n.behindBy(status.behind) : ""}',
                            style: TextStyle(
                              fontSize: 12,
                              color: status.ahead > 0
                                  ? AppColors.gitAdded
                                  : (status.behind > 0
                                        ? AppColors.gitModified
                                        : theme.colorScheme.outline),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Remotes list
          Expanded(
            child: remotesAsync.when(
              skipLoadingOnReload: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading remotes: $e')),
              data: (remotes) {
                if (remotes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_off_outlined,
                          size: 48,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No remotes configured for this repository.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          onPressed: () => _addRemote(context, ref),
                          icon: const Icon(Icons.add, size: 16),
                          label: Text(l10n.addRemote),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: remotes.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final remote = remotes[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.storage,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  remote.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (remote.isSSH
                                                ? Colors.purple
                                                : Colors.blue)
                                            .withAlpha(30),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    remote.isSSH ? 'SSH' : 'HTTPS',
                                    style: TextStyle(
                                      color: remote.isSSH
                                          ? Colors.purple
                                          : Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.refresh, size: 14),
                                  label: Text(l10n.fetch),
                                  onPressed: () => _fetch(ref, remote.name),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                OutlinedButton.icon(
                                  icon: const Icon(
                                    Icons.arrow_downward,
                                    size: 14,
                                  ),
                                  label: Text(l10n.pull),
                                  onPressed: () => _pull(ref, remote.name),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                FilledButton.icon(
                                  icon: const Icon(
                                    Icons.arrow_upward,
                                    size: 14,
                                  ),
                                  label: Text(l10n.push),
                                  onPressed: () => _push(
                                    context,
                                    ref,
                                    remote.name,
                                    false,
                                    l10n,
                                  ),
                                  style: FilledButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 18),
                                  onSelected: (action) {
                                    if (action == 'forcePush') {
                                      _push(
                                        context,
                                        ref,
                                        remote.name,
                                        true,
                                        l10n,
                                      );
                                    }
                                    if (action == 'remove') {
                                      _removeRemote(context, ref, remote.name);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'forcePush',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.warning,
                                            size: 18,
                                            color: theme.colorScheme.error,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            l10n.forcePush,
                                            style: TextStyle(
                                              color: theme.colorScheme.error,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'remove',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(l10n.delete),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Fetch URL: ${remote.fetchUrl}',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            if (remote.pushUrl != remote.fetchUrl) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Push URL: ${remote.pushUrl}',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addRemote(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const AddRemoteDialog(),
    );

    if (result == null) return;

    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: 'Adding remote ${result["name"]}',
          action: (progress) async {
            final git = ref.read(gitServiceProvider);
            await git.addRemote(
              repoPath,
              name: result['name']!,
              url: result['url']!,
            );
            ref.read(currentRepoProvider.notifier).refresh();
          },
        );
  }

  Future<void> _removeRemote(
    BuildContext context,
    WidgetRef ref,
    String name,
  ) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Remove remote $name?',
      message: 'Are you sure you want to remove remote $name?',
      confirmLabel: 'Remove',
      type: ConfirmDialogType.warning,
    );
    if (!confirmed) return;

    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: 'Removing remote $name',
          action: (progress) async {
            final git = ref.read(gitServiceProvider);
            await git.removeRemote(repoPath, name);
            ref.read(currentRepoProvider.notifier).refresh();
          },
        );
  }

  Future<void> _fetch(WidgetRef ref, String? remote) async {
    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: 'Fetching from ${remote ?? "all remotes"}',
          action: (progress) async {
            final git = ref.read(gitServiceProvider);
            await git.fetch(repoPath, remote: remote);
            ref.read(currentRepoProvider.notifier).refresh();
          },
        );
  }

  Future<void> _pull(WidgetRef ref, String? remote) async {
    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: 'Pulling changes',
          action: (progress) async {
            final git = ref.read(gitServiceProvider);
            await git.pull(repoPath, remote: remote);
            ref.read(currentRepoProvider.notifier).refresh();
          },
        );
  }

  Future<void> _push(
    BuildContext context,
    WidgetRef ref,
    String? remote,
    bool force,
    AppLocalizations l10n,
  ) async {
    if (force) {
      final confirmed = await ConfirmDialog.show(
        context,
        title: l10n.forcePush,
        message: l10n.forcePushWarning,
        confirmLabel: l10n.forcePush,
        type: ConfirmDialogType.danger,
      );
      if (!confirmed) return;
    }

    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: force ? 'Force pushing changes' : 'Pushing changes',
          action: (progress) async {
            final git = ref.read(gitServiceProvider);
            await git.push(repoPath, remote: remote, force: force);
            ref.read(currentRepoProvider.notifier).refresh();
          },
        );
  }
}
