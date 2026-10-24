import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitora/application/providers/current_repo_provider.dart';
import 'package:gitora/application/providers/git_branches_provider.dart';
import 'package:gitora/application/providers/git_service_provider.dart';
import 'package:gitora/application/providers/git_tasks_provider.dart';
import 'package:gitora/core/theme/app_colors.dart';
import 'package:gitora/domain/models/git_branch.dart';
import 'package:gitora/l10n/app_localizations.dart';
import 'package:gitora/presentation/screens/branches/branch_actions_dialogs.dart';
import 'package:gitora/presentation/widgets/confirm_dialog.dart';

class BranchesScreen extends ConsumerStatefulWidget {
  const BranchesScreen({super.key});

  @override
  ConsumerState<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends ConsumerState<BranchesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final branchesAsync = ref.watch(gitBranchesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Toolbar with TabBar and Search + New Branch button
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
                SizedBox(
                  width: 320,
                  child: TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(text: l10n.localBranches),
                      Tab(text: l10n.remoteBranches),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Filter branches...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      isDense: true,
                    ),
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim().toLowerCase()),
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: () => _createBranch(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.createBranch),
                ),
              ],
            ),
          ),

          // Tab views
          Expanded(
            child: branchesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('Error loading branches: $e')),
              data: (branches) {
                final localBranches = branches
                    .where((b) => !b.isRemote)
                    .toList();
                final remoteBranches = branches
                    .where((b) => b.isRemote)
                    .toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBranchList(localBranches, false, theme, l10n),
                    _buildBranchList(remoteBranches, true, theme, l10n),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchList(
    List<GitBranch> list,
    bool isRemoteTab,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final filtered = list
        .where((b) => b.name.toLowerCase().contains(_searchQuery))
        .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No branches found',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final branch = filtered[index];

        return Card(
          child: ListTile(
            leading: Icon(
              branch.isCurrent
                  ? Icons.check_circle
                  : (isRemoteTab ? Icons.cloud_outlined : Icons.fork_right),
              color: branch.isCurrent
                  ? AppColors.gitAdded
                  : theme.colorScheme.primary,
            ),
            title: Row(
              children: [
                Text(
                  branch.displayName,
                  style: TextStyle(
                    fontWeight: branch.isCurrent
                        ? FontWeight.bold
                        : FontWeight.w500,
                  ),
                ),
                if (branch.isCurrent) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gitAdded.withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      l10n.currentBranch,
                      style: const TextStyle(
                        color: AppColors.gitAdded,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Text(
              'Commit: ${branch.targetHash.length > 7 ? branch.targetHash.substring(0, 7) : branch.targetHash}',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.5,
                color: theme.colorScheme.outline,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!branch.isCurrent)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.logout, size: 14),
                    label: Text(l10n.checkout),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _checkout(branch.name),
                  ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (action) {
                    if (action == 'merge') _merge(branch.name, l10n);
                    if (action == 'rebase') _rebase(branch.name, l10n);
                    if (action == 'rename') _rename(branch.name);
                    if (action == 'delete') _delete(branch, l10n);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'merge',
                      child: Row(
                        children: [
                          const Icon(Icons.call_merge, size: 18),
                          const SizedBox(width: 8),
                          Text(l10n.mergeInto(branch.displayName, 'current')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'rebase',
                      child: Row(
                        children: [
                          const Icon(Icons.alt_route, size: 18),
                          const SizedBox(width: 8),
                          Text(l10n.rebaseOnto('current', branch.displayName)),
                        ],
                      ),
                    ),
                    if (!isRemoteTab)
                      PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text(l10n.renameBranch),
                          ],
                        ),
                      ),
                    if (!isRemoteTab && !branch.isCurrent)
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.deleteBranch,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _createBranch(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const CreateBranchDialog(),
    );

    if (name == null || name.isEmpty) return;

    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: 'Creating branch $name',
          action: (progress) async {
            final git = ref.read(gitServiceProvider);
            await git.createBranch(repoPath, name: name);
            ref.read(currentRepoProvider.notifier).refresh();
          },
        );
  }

  Future<void> _checkout(String name) async {
    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: 'Checking out branch $name',
          action: (progress) async {
            final git = ref.read(gitServiceProvider);
            await git.checkout(repoPath, name);
            ref.read(currentRepoProvider.notifier).refresh();
          },
        );
  }

  Future<void> _rename(String oldName) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => RenameBranchDialog(currentName: oldName),
    );

    if (newName == null || newName.isEmpty) return;

    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: 'Renaming branch',
          action: (progress) async {
            final git = ref.read(gitServiceProvider);
            await git.renameBranch(
              repoPath,
              oldName: oldName,
              newName: newName,
            );
            ref.read(currentRepoProvider.notifier).refresh();
          },
        );
  }

  Future<void> _delete(GitBranch branch, AppLocalizations l10n) async {
    if (branch.isCurrent) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.cannotDeleteActiveBranch)));
      return;
    }

    final confirmed = await ConfirmDialog.show(
      context,
      title: l10n.deleteBranch,
      message: l10n.deleteBranchConfirm(branch.displayName),
      confirmLabel: l10n.delete,
      type: ConfirmDialogType.danger,
    );

    if (!confirmed) return;

    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: 'Deleting branch ${branch.displayName}',
          action: (progress) async {
            final git = ref.read(gitServiceProvider);
            await git.deleteBranch(repoPath, branch.name);
            ref.read(currentRepoProvider.notifier).refresh();
          },
        );
  }

  Future<void> _merge(String branchName, AppLocalizations l10n) async {
    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: 'Merging $branchName',
          action: (progress) async {
            final git = ref.read(gitServiceProvider);
            await git.merge(repoPath, branchName);
            ref.read(currentRepoProvider.notifier).refresh();
          },
        );
  }

  Future<void> _rebase(String branchName, AppLocalizations l10n) async {
    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: 'Rebasing onto $branchName',
          action: (progress) async {
            final git = ref.read(gitServiceProvider);
            await git.rebase(repoPath, branchName);
            ref.read(currentRepoProvider.notifier).refresh();
          },
        );
  }
}
