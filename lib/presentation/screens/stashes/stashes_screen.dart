import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitora/application/providers/current_repo_provider.dart';
import 'package:gitora/application/providers/git_service_provider.dart';
import 'package:gitora/application/providers/git_stashes_provider.dart';
import 'package:gitora/application/providers/git_tasks_provider.dart';
import 'package:gitora/l10n/app_localizations.dart';
import 'package:gitora/presentation/screens/stashes/create_stash_dialog.dart';
import 'package:gitora/presentation/widgets/confirm_dialog.dart';

class StashesScreen extends ConsumerWidget {
  const StashesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final stashesAsync = ref.watch(gitStashesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Toolbar
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
                Text(l10n.stashes, style: theme.textTheme.titleMedium),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _createStash(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.createStash),
                ),
              ],
            ),
          ),

          // Stashes List
          Expanded(
            child: stashesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading stashes: $e')),
              data: (stashes) {
                if (stashes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noStashes,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          onPressed: () => _createStash(context, ref),
                          icon: const Icon(Icons.add, size: 16),
                          label: Text(l10n.createStash),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: stashes.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final stash = stashes[index];

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          child: Icon(
                            Icons.archive_outlined,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                        title: Text(
                          stash.message,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                        subtitle: Text(
                          stash.refName,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.check, size: 14),
                              label: Text(l10n.applyStash),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () => _applyStash(ref, stash.index),
                            ),
                            const SizedBox(width: 6),
                            FilledButton.tonalIcon(
                              icon: const Icon(Icons.unarchive, size: 14),
                              label: Text(l10n.popStash),
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () => _popStash(ref, stash.index),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: theme.colorScheme.error,
                              ),
                              tooltip: l10n.dropStash,
                              onPressed: () =>
                                  _dropStash(context, ref, stash.index, l10n),
                            ),
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

  Future<void> _createStash(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const CreateStashDialog(),
    );

    if (result == null) return;

    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: 'Creating stash',
          action: (progress) async {
            final git = ref.read(gitServiceProvider);
            await git.createStash(
              repoPath,
              message: result['message'] as String?,
              includeUntracked: result['includeUntracked'] as bool? ?? false,
            );
            ref.read(currentRepoProvider.notifier).refresh();
          },
        );
  }

  Future<void> _applyStash(WidgetRef ref, int index) async {
    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: 'Applying stash@{$index}',
          action: (progress) async {
            final git = ref.read(gitServiceProvider);
            await git.applyStash(repoPath, index);
            ref.read(currentRepoProvider.notifier).refresh();
          },
        );
  }

  Future<void> _popStash(WidgetRef ref, int index) async {
    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: 'Popping stash@{$index}',
          action: (progress) async {
            final git = ref.read(gitServiceProvider);
            await git.popStash(repoPath, index);
            ref.read(currentRepoProvider.notifier).refresh();
          },
        );
  }

  Future<void> _dropStash(
    BuildContext context,
    WidgetRef ref,
    int index,
    AppLocalizations l10n,
  ) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: l10n.dropStash,
      message: l10n.dropStashConfirm,
      confirmLabel: l10n.delete,
      type: ConfirmDialogType.danger,
    );
    if (!confirmed) return;

    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: 'Dropping stash@{$index}',
          action: (progress) async {
            final git = ref.read(gitServiceProvider);
            await git.dropStash(repoPath, index);
            ref.read(currentRepoProvider.notifier).refresh();
          },
        );
  }
}
