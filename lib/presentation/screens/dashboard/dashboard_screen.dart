import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gitora/application/providers/current_repo_provider.dart';
import 'package:gitora/application/providers/git_service_provider.dart';
import 'package:gitora/application/providers/git_tasks_provider.dart';
import 'package:gitora/application/providers/recent_repos_provider.dart';
import 'package:gitora/application/providers/log_provider.dart';
import 'package:gitora/application/providers/settings_provider.dart';
import 'package:gitora/core/constants/app_constants.dart';
import 'package:gitora/core/theme/app_colors.dart';
import 'package:gitora/core/utils/system_launcher.dart';
import 'package:gitora/domain/models/git_system_info.dart';
import 'package:gitora/domain/models/repository_item.dart';
import 'package:gitora/l10n/app_localizations.dart';
import 'package:gitora/presentation/screens/dashboard/clone_repo_dialog.dart';
import 'package:gitora/presentation/screens/dashboard/init_repo_dialog.dart';
import 'package:gitora/presentation/widgets/gitora_logo.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final void Function(int index)? onNavigate;

  const DashboardScreen({super.key, this.onNavigate});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  GitSystemInfo _systemInfo = GitSystemInfo.empty;

  @override
  void initState() {
    super.initState();
    _checkGit();
  }

  Future<void> _checkGit() async {
    final git = ref.read(gitServiceProvider);
    final info = await git.checkSystemInfo();
    if (mounted) setState(() => _systemInfo = info);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final recentAsync = ref.watch(recentReposProvider);
    final currentPath = ref.watch(currentRepoProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        children: [
          // Hero Welcome Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer.withAlpha(200),
                  theme.colorScheme.surfaceContainerHigh,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withAlpha(80),
              ),
            ),
            child: Row(
              children: [
                const GitoraLogo(size: 64),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.appName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppConstants.appTagline,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // System info badge
                      Row(
                        children: [
                          Icon(
                            _systemInfo.isCliInstalled
                                ? Icons.check_circle
                                : Icons.warning_amber_rounded,
                            size: 16,
                            color: _systemInfo.isCliInstalled
                                ? AppColors.gitAdded
                                : Colors.amber.shade800,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _systemInfo.isCliInstalled
                                ? 'Git Engine: ${_systemInfo.cliVersion}'
                                : (_systemInfo.isLibGit2Available
                                      ? 'Embedded LibGit2 Active (${_systemInfo.libGit2Version})'
                                      : 'Git Engine Not Found'),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Quick Action Buttons
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: _openFolder,
                      icon: const Icon(Icons.folder_open, size: 18),
                      label: Text(l10n.openRepository),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: () => _cloneRepo(context),
                      icon: const Icon(Icons.cloud_download_outlined, size: 18),
                      label: Text(l10n.cloneRepository),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _initRepo(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.newRepository),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Search and Filters Bar
          Row(
            children: [
              Text(
                l10n.recentRepositories,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 260,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchRepositories,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                  ),
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Repositories List
          recentAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(child: Text('Error loading repositories: $e')),
            data: (repos) {
              final filtered = repos.where((r) {
                if (_searchQuery.isEmpty) return true;
                return r.name.toLowerCase().contains(_searchQuery) ||
                    r.path.toLowerCase().contains(_searchQuery);
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder_off_outlined,
                          size: 48,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noRecentRepositories,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Separate favorites and recents
              final favorites = filtered.where((r) => r.isFavorite).toList();
              final recents = filtered.where((r) => !r.isFavorite).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (favorites.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.favorites.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final repo in favorites)
                      _buildRepoCard(
                        repo,
                        repo.path == currentPath,
                        theme,
                        l10n,
                      ),
                    const SizedBox(height: 16),
                  ],

                  if (recents.isNotEmpty) ...[
                    if (favorites.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          l10n.recentRepositories.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                    for (final repo in recents)
                      _buildRepoCard(
                        repo,
                        repo.path == currentPath,
                        theme,
                        l10n,
                      ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRepoCard(
    RepositoryItem repo,
    bool isActive,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final dateFormat = DateFormat.yMMMd().add_jm();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        color: isActive
            ? theme.colorScheme.primaryContainer.withAlpha(50)
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withAlpha(80),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            ref.read(currentRepoProvider.notifier).setRepo(repo.path);
            widget.onNavigate?.call(1); // Navigate to Changes
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.folder,
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            repo.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withAlpha(30),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        repo.path,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.outline,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last opened: ${dateFormat.format(repo.lastOpened)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                IconButton(
                  icon: Icon(
                    repo.isFavorite ? Icons.star : Icons.star_border,
                    color: repo.isFavorite
                        ? Colors.amber.shade700
                        : theme.colorScheme.outline,
                    size: 20,
                  ),
                  tooltip: repo.isFavorite
                      ? l10n.unmarkFavorite
                      : l10n.markFavorite,
                  onPressed: () {
                    ref
                        .read(recentReposProvider.notifier)
                        .toggleFavorite(repo.path);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.folder_open, size: 20),
                  tooltip: l10n.openInExplorer,
                  onPressed: () => SystemLauncher.openInExplorer(repo.path),
                ),
                IconButton(
                  icon: const Icon(Icons.terminal, size: 20),
                  tooltip: l10n.openInTerminal,
                  onPressed: () async {
                    try {
                      final pref = ref.read(settingsProvider).preferredTerminal;
                      await SystemLauncher.openInTerminal(
                        repo.path,
                        preferredTerminal: pref,
                      );
                    } catch (e) {
                      ref
                          .read(logProvider.notifier)
                          .logError(
                            'Failed to open terminal',
                            details: e.toString(),
                            source: 'Terminal',
                          );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to open terminal: $e'),
                            backgroundColor: theme.colorScheme.error,
                          ),
                        );
                      }
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.code, size: 20),
                  tooltip: l10n.openInEditor,
                  onPressed: () => SystemLauncher.openInVSCode(repo.path),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: theme.colorScheme.outline,
                  ),
                  tooltip: l10n.removeRecent,
                  onPressed: () {
                    ref
                        .read(recentReposProvider.notifier)
                        .removeRepository(repo.path);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openFolder() async {
    final path = await FilePicker.getDirectoryPath();
    if (path != null) {
      ref.read(currentRepoProvider.notifier).setRepo(path);
      widget.onNavigate?.call(1);
    }
  }

  Future<void> _cloneRepo(BuildContext context) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const CloneRepoDialog(),
    );

    if (result == null) return;

    final url = result['url']!;
    final path = result['path']!;

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: 'Cloning repository',
          action: (progress) async {
            final git = ref.read(gitServiceProvider);
            await git.cloneRepository(
              url: url,
              targetPath: path,
              onProgress: progress,
            );
            ref.read(currentRepoProvider.notifier).setRepo(path);
            widget.onNavigate?.call(1);
          },
        );
  }

  Future<void> _initRepo(BuildContext context) async {
    final path = await showDialog<String>(
      context: context,
      builder: (_) => const InitRepoDialog(),
    );

    if (path == null) return;

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: 'Initializing repository',
          action: (progress) async {
            final git = ref.read(gitServiceProvider);
            await git.initRepository(path);
            ref.read(currentRepoProvider.notifier).setRepo(path);
            widget.onNavigate?.call(1);
          },
        );
  }
}
