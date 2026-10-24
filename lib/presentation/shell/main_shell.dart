import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitora/application/providers/current_repo_provider.dart';
import 'package:gitora/application/providers/git_branches_provider.dart';
import 'package:gitora/application/providers/git_history_provider.dart';
import 'package:gitora/application/providers/git_remotes_provider.dart';
import 'package:gitora/application/providers/git_service_provider.dart';
import 'package:gitora/application/providers/git_stashes_provider.dart';
import 'package:gitora/application/providers/repository_state_provider.dart';
import 'package:gitora/application/providers/git_tasks_provider.dart';
import 'package:gitora/application/providers/settings_provider.dart';
import 'package:gitora/core/theme/app_colors.dart';
import 'package:gitora/l10n/app_localizations.dart';
import 'package:gitora/presentation/screens/branches/branch_actions_dialogs.dart';
import 'package:gitora/presentation/screens/branches/branches_screen.dart';
import 'package:gitora/presentation/screens/changes/changes_screen.dart';
import 'package:gitora/presentation/screens/dashboard/clone_repo_dialog.dart';
import 'package:gitora/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:gitora/presentation/screens/dashboard/init_repo_dialog.dart';
import 'package:gitora/presentation/screens/history/history_screen.dart';
import 'package:gitora/presentation/screens/remotes/remotes_screen.dart';
import 'package:gitora/presentation/screens/settings/settings_screen.dart';
import 'package:gitora/presentation/screens/stashes/stashes_screen.dart';
import 'package:gitora/application/providers/log_provider.dart';
import 'package:gitora/presentation/shell/status_bar.dart';
import 'package:gitora/presentation/shell/top_navigation_bar.dart';
import 'package:gitora/presentation/widgets/command_palette.dart';
import 'package:gitora/presentation/widgets/output_log_panel.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  final FocusNode _focusNode = FocusNode();
  double _outputPanelHeight = 180.0;
  DateTime _lastFocusRefresh = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      if (now.difference(_lastFocusRefresh) > const Duration(seconds: 1)) {
        _lastFocusRefresh = now;
        final currentRepo = ref.read(currentRepoProvider);
        if (currentRepo != null && currentRepo.isNotEmpty) {
          ref.read(repositoryStateProvider.notifier).refresh();
          ref.invalidate(gitBranchesProvider);
          ref.invalidate(gitRemotesProvider);
          ref.invalidate(gitStashesProvider);
        }
      }
    }
  }

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
    final currentRepo = ref.read(currentRepoProvider);
    if (currentRepo != null && currentRepo.isNotEmpty) {
      ref.read(repositoryStateProvider.notifier).refresh();
      switch (index) {
        case 1: // Changes
          break;
        case 2: // History
          ref.invalidate(gitHistoryProvider);
          break;
        case 3: // Branches
          ref.invalidate(gitBranchesProvider);
          break;
        case 4: // Remotes
          ref.invalidate(gitRemotesProvider);
          break;
        case 5: // Stashes
          ref.invalidate(gitStashesProvider);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final uncommittedCount = ref.watch(
      repositoryStateProvider.select((s) => s.totalChanges),
    );
    final logState = ref.watch(logProvider);

    final screens = [
      DashboardScreen(onNavigate: _navigateTo),
      const ChangesScreen(),
      const HistoryScreen(),
      const BranchesScreen(),
      const RemotesScreen(),
      const StashesScreen(),
      const SettingsScreen(),
    ];

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            HardwareKeyboard.instance.isControlPressed &&
            event.logicalKey == LogicalKeyboardKey.keyK) {
          _openCommandPalette(context, l10n);
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            // Top Navigation Bar
            TopNavigationBar(
              onOpenCommandPalette: () => _openCommandPalette(context, l10n),
              onNavigate: _navigateTo,
            ),

            // Content Area with NavigationRail
            Expanded(
              child: Row(
                children: [
                  NavigationRail(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (index) =>
                        setState(() => _currentIndex = index),
                    labelType: NavigationRailLabelType.all,
                    leading: const SizedBox(height: 8),
                    destinations: [
                      NavigationRailDestination(
                        icon: const Icon(Icons.dashboard_outlined),
                        selectedIcon: const Icon(Icons.dashboard_rounded),
                        label: Text(l10n.navDashboard),
                      ),
                      NavigationRailDestination(
                        icon: Badge(
                          isLabelVisible: uncommittedCount > 0,
                          label: Text('$uncommittedCount'),
                          backgroundColor: AppColors.gitModified,
                          child: const Icon(Icons.edit_note_outlined),
                        ),
                        selectedIcon: Badge(
                          isLabelVisible: uncommittedCount > 0,
                          label: Text('$uncommittedCount'),
                          backgroundColor: AppColors.gitModified,
                          child: const Icon(Icons.edit_note_rounded),
                        ),
                        label: Text(l10n.navChanges),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.route_outlined),
                        selectedIcon: const Icon(Icons.route_rounded),
                        label: Text(l10n.navHistory),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.alt_route_outlined),
                        selectedIcon: const Icon(Icons.alt_route_rounded),
                        label: Text(l10n.navBranches),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.cloud_sync_outlined),
                        selectedIcon: const Icon(Icons.cloud_sync_rounded),
                        label: Text(l10n.navRemotes),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.inventory_2_outlined),
                        selectedIcon: const Icon(Icons.inventory_2_rounded),
                        label: Text(l10n.navStashes),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.settings_outlined),
                        selectedIcon: const Icon(Icons.settings_rounded),
                        label: Text(l10n.navSettings),
                      ),
                    ],
                  ),

                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: theme.colorScheme.outlineVariant.withAlpha(60),
                  ),

                  // Screen body
                  Expanded(
                    child: IndexedStack(
                      index: _currentIndex,
                      children: screens,
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Output & Log Panel (collapsible and resizable)
            if (logState.isPanelOpen)
              OutputLogPanel(
                height: _outputPanelHeight,
                onHeightChanged: (h) => setState(() => _outputPanelHeight = h),
                onClose: () =>
                    ref.read(logProvider.notifier).togglePanel(false),
              ),

            // Bottom Status Bar
            const StatusBar(),
          ],
        ),
      ),
    );
  }

  void _openCommandPalette(BuildContext context, AppLocalizations l10n) {
    final commands = [
      CommandItem(
        id: 'open_repo',
        title: l10n.openRepository,
        subtitle: 'Select folder on local disk',
        icon: Icons.folder_open,
        shortcut: 'Ctrl+O',
        onSelect: () => _openFolder(),
      ),
      CommandItem(
        id: 'clone_repo',
        title: l10n.cloneRepository,
        subtitle: 'Clone remote Git repository',
        icon: Icons.cloud_download_outlined,
        onSelect: () => _cloneRepo(context),
      ),
      CommandItem(
        id: 'init_repo',
        title: l10n.newRepository,
        subtitle: 'Initialize a new Git repository in a folder',
        icon: Icons.add,
        onSelect: () => _initRepo(context),
      ),
      CommandItem(
        id: 'commit',
        title: l10n.commit,
        subtitle: 'Review working tree and make a commit',
        icon: Icons.check,
        shortcut: 'Ctrl+Enter',
        onSelect: () => _navigateTo(1),
      ),
      CommandItem(
        id: 'push',
        title: l10n.push,
        subtitle: 'Push commits to remote',
        icon: Icons.arrow_upward,
        shortcut: 'Ctrl+P',
        onSelect: () => _push(),
      ),
      CommandItem(
        id: 'pull',
        title: l10n.pull,
        subtitle: 'Pull latest commits from remote',
        icon: Icons.arrow_downward,
        shortcut: 'Ctrl+Shift+P',
        onSelect: () => _pull(),
      ),
      CommandItem(
        id: 'fetch',
        title: l10n.fetch,
        subtitle: 'Fetch branches and tags from remotes',
        icon: Icons.refresh,
        onSelect: () => _fetch(),
      ),
      CommandItem(
        id: 'create_branch',
        title: l10n.createBranch,
        subtitle: 'Create a new branch from current HEAD',
        icon: Icons.fork_right,
        shortcut: 'Ctrl+B',
        onSelect: () => _createBranch(context),
      ),
      CommandItem(
        id: 'switch_branch',
        title: 'Switch Branch',
        subtitle: 'Go to branches list',
        icon: Icons.alt_route,
        onSelect: () => _navigateTo(3),
      ),
      CommandItem(
        id: 'search_commits',
        title: 'Search Commits',
        subtitle: 'Search Git commit history',
        icon: Icons.search,
        onSelect: () => _navigateTo(2),
      ),
      CommandItem(
        id: 'toggle_diff',
        title: 'Toggle Diff View Mode',
        subtitle: 'Switch between Unified and Side-by-Side diff',
        icon: Icons.table_rows_outlined,
        onSelect: () =>
            ref.read(settingsProvider.notifier).toggleDiffViewMode(),
      ),
      CommandItem(
        id: 'toggle_theme',
        title: 'Toggle Theme',
        subtitle: 'Switch Light / Dark mode',
        icon: Icons.brightness_6,
        onSelect: () {
          final current = ref.read(settingsProvider).themeMode;
          ref
              .read(settingsProvider.notifier)
              .setThemeMode(
                current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
              );
        },
      ),
      CommandItem(
        id: 'open_settings',
        title: l10n.settings,
        subtitle: 'Configure appearance, Git identity and backend',
        icon: Icons.settings_outlined,
        shortcut: 'Ctrl+,',
        onSelect: () => _navigateTo(6),
      ),
    ];

    CommandPalette.show(context, commands);
  }

  Future<void> _openFolder() async {
    final path = await FilePicker.getDirectoryPath();
    if (path != null) {
      ref.read(currentRepoProvider.notifier).setRepo(path);
      _navigateTo(1);
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
            _navigateTo(1);
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
            _navigateTo(1);
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

  Future<void> _push() async {
    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: 'Pushing changes',
          action: (progress) async {
            final git = ref.read(gitServiceProvider);
            await git.push(repoPath);
            ref.read(currentRepoProvider.notifier).refresh();
          },
        );
  }

  Future<void> _pull() async {
    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: 'Pulling changes',
          action: (progress) async {
            final git = ref.read(gitServiceProvider);
            await git.pull(repoPath);
            ref.read(currentRepoProvider.notifier).refresh();
          },
        );
  }

  Future<void> _fetch() async {
    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: 'Fetching changes',
          action: (progress) async {
            final git = ref.read(gitServiceProvider);
            await git.fetch(repoPath);
            ref.read(currentRepoProvider.notifier).refresh();
          },
        );
  }
}
