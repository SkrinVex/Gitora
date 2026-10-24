import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitora/application/providers/current_repo_provider.dart';
import 'package:gitora/application/providers/repository_state_provider.dart';
import 'package:gitora/application/providers/recent_repos_provider.dart';
import 'package:gitora/application/providers/log_provider.dart';
import 'package:gitora/application/providers/settings_provider.dart';
import 'package:gitora/core/constants/app_constants.dart';
import 'package:gitora/core/utils/system_launcher.dart';
import 'package:gitora/l10n/app_localizations.dart';
import 'package:gitora/presentation/widgets/gitora_logo.dart';

class TopNavigationBar extends ConsumerWidget {
  final VoidCallback onOpenCommandPalette;
  final void Function(int index) onNavigate;

  const TopNavigationBar({
    super.key,
    required this.onOpenCommandPalette,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final currentRepo = ref.watch(currentRepoProvider);
    final branchName = ref.watch(
      repositoryStateProvider.select((s) => s.branchName),
    );
    final recentRepos = ref.watch(recentReposProvider);

    String repoName = 'No repository';
    if (currentRepo != null) {
      final normalized = currentRepo.replaceAll('\\', '/');
      repoName = normalized
          .split('/')
          .lastWhere((s) => s.isNotEmpty, orElse: () => currentRepo);
    }

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
          // Gitora Brand Logo and Name
          InkWell(
            onTap: () => onNavigate(0), // Go to Dashboard
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  const GitoraLogo(size: 24),
                  const SizedBox(width: 10),
                  Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: theme.colorScheme.primary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),
          Container(
            width: 1,
            height: 20,
            color: theme.colorScheme.outlineVariant.withAlpha(80),
          ),
          const SizedBox(width: 16),

          // Repository Selector
          PopupMenuButton<String>(
            tooltip: 'Switch Repository',
            onSelected: (path) {
              if (path == '__OPEN_NEW__') {
                _openFolder(ref);
              } else {
                ref.read(currentRepoProvider.notifier).setRepo(path);
              }
            },
            itemBuilder: (context) {
              final list = recentRepos.value ?? [];
              return [
                ...list.map(
                  (r) => PopupMenuItem(
                    value: r.path,
                    child: Row(
                      children: [
                        Icon(
                          r.path == currentRepo
                              ? Icons.check
                              : Icons.folder_outlined,
                          size: 16,
                          color: r.path == currentRepo
                              ? theme.colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r.name,
                            style: TextStyle(
                              fontWeight: r.path == currentRepo
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: '__OPEN_NEW__',
                  child: Row(
                    children: [
                      const Icon(Icons.folder_open, size: 16),
                      const SizedBox(width: 8),
                      Text(l10n.openRepository),
                    ],
                  ),
                ),
              ];
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withAlpha(60),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder,
                    size: 16,
                    color: currentRepo != null
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      repoName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: currentRepo != null
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.outline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
            ),
          ),

          // Active Branch Pill
          if (currentRepo != null && branchName.isNotEmpty) ...[
            const SizedBox(width: 10),
            InkWell(
              onTap: () => onNavigate(3), // Navigate to Branches
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withAlpha(120),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fork_right,
                      size: 15,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(
                        branchName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const Spacer(),

          // Quick Explorer, Terminal & VS Code shortcuts
          if (currentRepo != null) ...[
            IconButton(
              icon: const Icon(Icons.folder_open_outlined, size: 18),
              tooltip: l10n.openInExplorer,
              visualDensity: VisualDensity.compact,
              onPressed: () => SystemLauncher.openInExplorer(currentRepo),
            ),
            IconButton(
              icon: const Icon(Icons.terminal, size: 18),
              tooltip: l10n.openInTerminal,
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                try {
                  final pref = ref.read(settingsProvider).preferredTerminal;
                  await SystemLauncher.openInTerminal(
                    currentRepo,
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
                  if (context.mounted) {
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
              icon: const Icon(Icons.code, size: 18),
              tooltip: l10n.openInEditor,
              visualDensity: VisualDensity.compact,
              onPressed: () => SystemLauncher.openInVSCode(currentRepo),
            ),
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 20,
              color: theme.colorScheme.outlineVariant.withAlpha(80),
            ),
            const SizedBox(width: 8),
          ],

          // Command Palette Button (Ctrl+K)
          InkWell(
            onTap: onOpenCommandPalette,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withAlpha(60),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Search actions...',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withAlpha(80),
                      ),
                    ),
                    child: Text(
                      'Ctrl+K',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Settings Shortcut
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 19),
            tooltip: l10n.settings,
            visualDensity: VisualDensity.compact,
            onPressed: () => onNavigate(6), // Settings index
          ),
        ],
      ),
    );
  }

  Future<void> _openFolder(WidgetRef ref) async {
    final path = await FilePicker.getDirectoryPath();
    if (path != null) {
      ref.read(currentRepoProvider.notifier).setRepo(path);
      onNavigate(1); // Changes
    }
  }
}
