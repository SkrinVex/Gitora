import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitora/application/providers/current_repo_provider.dart';
import 'package:gitora/application/providers/git_service_provider.dart';
import 'package:gitora/application/providers/git_tasks_provider.dart';
import 'package:gitora/application/providers/settings_provider.dart';
import 'package:gitora/core/theme/app_colors.dart';
import 'package:gitora/domain/models/git_diff.dart';
import 'package:gitora/l10n/app_localizations.dart';

class DiffViewer extends ConsumerStatefulWidget {
  final GitDiffModel diff;
  final bool isStaged;

  const DiffViewer({super.key, required this.diff, this.isStaged = false});

  @override
  ConsumerState<DiffViewer> createState() => _DiffViewerState();
}

class _DiffViewerState extends ConsumerState<DiffViewer> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.diff.isBinary) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insert_drive_file_outlined,
                size: 48,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.binaryFileNotice,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (widget.diff.isEmpty) {
      return Center(
        child: Text(
          'No differences detected in this file.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      );
    }

    return Column(
      children: [
        // Top toolbar
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
              Icon(
                Icons.description_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.diff.filePath,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Additions and Deletions badges
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gitAdded.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '+${widget.diff.additions}',
                  style: const TextStyle(
                    color: AppColors.gitAdded,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gitDeleted.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '-${widget.diff.deletions}',
                  style: const TextStyle(
                    color: AppColors.gitDeleted,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Segmented view switcher (Unified vs Side-by-side)
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text(l10n.unifiedDiff),
                    icon: const Icon(Icons.table_rows_outlined, size: 16),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text(l10n.sideBySideDiff),
                    icon: const Icon(Icons.view_column_outlined, size: 16),
                  ),
                ],
                selected: {settings.isUnifiedDiff},
                onSelectionChanged: (set) {
                  ref.read(settingsProvider.notifier).toggleDiffViewMode();
                },
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),

        // Main Diff Body
        Expanded(
          child: Scrollbar(
            controller: _verticalController,
            thumbVisibility: true,
            child: Scrollbar(
              controller: _horizontalController,
              notificationPredicate: (notif) => notif.depth == 1,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _verticalController,
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: settings.isUnifiedDiff
                      ? _buildUnifiedView(theme, isDark, l10n)
                      : _buildSideBySideView(theme, isDark, l10n),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnifiedView(
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final hunk in widget.diff.hunks) ...[
          // Hunk header bar with "Stage Hunk" button
          Container(
            width: 900,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: isDark
                ? AppColors.diffHunkHeaderBgDark
                : AppColors.diffHunkHeaderBgLight,
            child: Row(
              children: [
                Icon(
                  Icons.unfold_more,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hunk.header,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                if (!widget.isStaged)
                  FilledButton.tonalIcon(
                    onPressed: () => _stageHunk(hunk),
                    icon: const Icon(Icons.add, size: 14),
                    label: Text(l10n.stageHunk),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      textStyle: const TextStyle(fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          // Hunk lines
          for (final line in hunk.lines)
            _buildUnifiedLine(line, isDark, theme, l10n),
        ],
      ],
    );
  }

  Widget _buildUnifiedLine(
    GitDiffLine line,
    bool isDark,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    Color? bgColor;
    Color textColor = theme.colorScheme.onSurface;
    String prefix = ' ';

    if (line.isAddition) {
      bgColor = isDark
          ? AppColors.diffAddedLineBgDark
          : AppColors.diffAddedLineBgLight;
      textColor = AppColors.diffAddedText;
      prefix = '+';
    } else if (line.isDeletion) {
      bgColor = isDark
          ? AppColors.diffDeletedLineBgDark
          : AppColors.diffDeletedLineBgLight;
      textColor = AppColors.diffDeletedText;
      prefix = '-';
    }

    return Container(
      width: 900,
      color: bgColor,
      child: Row(
        children: [
          // Old line number
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: theme.colorScheme.outlineVariant.withAlpha(50),
                ),
              ),
            ),
            child: Text(
              line.oldLineNumber?.toString() ?? '',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.5,
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          // New line number
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: theme.colorScheme.outlineVariant.withAlpha(50),
                ),
              ),
            ),
            child: Text(
              line.newLineNumber?.toString() ?? '',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.5,
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          // Prefix (+, -, ' ')
          Container(
            width: 24,
            alignment: Alignment.center,
            child: Text(
              prefix,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          // Content
          Expanded(
            child: SelectableText(
              line.text,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                height: 1.4,
                color: textColor,
              ),
            ),
          ),
          // Copy button on hover/tap
          IconButton(
            icon: const Icon(Icons.copy, size: 12),
            tooltip: l10n.copyLine,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: line.text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Line copied to clipboard'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildSideBySideView(
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final hunk in widget.diff.hunks) ...[
          Container(
            width: 1100,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: isDark
                ? AppColors.diffHunkHeaderBgDark
                : AppColors.diffHunkHeaderBgLight,
            child: Row(
              children: [
                Icon(
                  Icons.unfold_more,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  hunk.header,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                if (!widget.isStaged)
                  FilledButton.tonalIcon(
                    onPressed: () => _stageHunk(hunk),
                    icon: const Icon(Icons.add, size: 14),
                    label: Text(l10n.stageHunk),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      textStyle: const TextStyle(fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          // Render side by side rows
          for (final line in hunk.lines)
            Container(
              width: 1100,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant.withAlpha(30),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Left side (Old version)
                  Expanded(
                    child: Container(
                      color: line.isDeletion
                          ? (isDark
                                ? AppColors.diffDeletedLineBgDark
                                : AppColors.diffDeletedLineBgLight)
                          : null,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text(
                              line.oldLineNumber?.toString() ?? '',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              line.isAddition ? '' : line.text,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: line.isDeletion
                                    ? AppColors.diffDeletedText
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Divider
                  Container(
                    width: 1,
                    height: 22,
                    color: theme.colorScheme.outlineVariant.withAlpha(80),
                  ),
                  // Right side (New version)
                  Expanded(
                    child: Container(
                      color: line.isAddition
                          ? (isDark
                                ? AppColors.diffAddedLineBgDark
                                : AppColors.diffAddedLineBgLight)
                          : null,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text(
                              line.newLineNumber?.toString() ?? '',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              line.isDeletion ? '' : line.text,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: line.isAddition
                                    ? AppColors.diffAddedText
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Future<void> _stageHunk(GitDiffHunk hunk) async {
    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    final patch = hunk.toPatchString(widget.diff.filePath);
    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: 'Staging hunk',
          action: (progress) async {
            final gitService = ref.read(gitServiceProvider);
            await gitService.stageHunk(repoPath, patch);
            ref.read(currentRepoProvider.notifier).refresh();
          },
        );
  }
}
