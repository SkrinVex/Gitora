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

class _DiffLinePair {
  final GitDiffLine? left;
  final GitDiffLine? right;

  const _DiffLinePair({this.left, this.right});
}

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
  bool _wordWrap = false;
  double _sideSplitRatio = 0.5;

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
          l10n.noChangesSubtitle,
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
              const SizedBox(width: 14),

              // Word wrap toggle
              IconButton(
                icon: Icon(
                  _wordWrap ? Icons.wrap_text : Icons.notes,
                  size: 18,
                  color: _wordWrap
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
                tooltip: _wordWrap ? l10n.disableWordWrap : l10n.enableWordWrap,
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _wordWrap = !_wordWrap),
              ),
              const SizedBox(width: 8),

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return settings.isUnifiedDiff
                  ? _buildUnifiedView(theme, isDark, l10n, constraints)
                  : _buildSideBySideView(theme, isDark, l10n, constraints);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUnifiedView(
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
    BoxConstraints constraints,
  ) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final hunk in widget.diff.hunks) ...[
          // Hunk header bar with Stage / Unstage Hunk button
          _buildHunkHeader(hunk, theme, isDark, l10n),
          // Hunk lines
          for (final line in hunk.lines)
            _buildUnifiedLine(line, isDark, theme, l10n),
        ],
      ],
    );

    if (!_wordWrap) {
      content = SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: content,
        ),
      );
    }

    return Scrollbar(
      controller: _verticalController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _verticalController,
        child: content,
      ),
    );
  }

  Widget _buildHunkHeader(
    GitDiffHunk hunk,
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final isStaged = widget.isStaged;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: isDark
          ? AppColors.diffHunkHeaderBgDark
          : AppColors.diffHunkHeaderBgLight,
      child: Row(
        children: [
          Icon(Icons.unfold_more, size: 16, color: theme.colorScheme.primary),
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
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: () => _toggleHunk(hunk),
            icon: Icon(isStaged ? Icons.remove : Icons.add, size: 14),
            label: Text(isStaged ? l10n.unstageHunk : l10n.stageHunk),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              textStyle: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
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
      color: bgColor,
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Old line number
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(horizontal: 4),
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
            padding: const EdgeInsets.symmetric(horizontal: 4),
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
          // Copy button
          IconButton(
            icon: const Icon(Icons.copy, size: 12),
            tooltip: l10n.copyLine,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: line.text));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.copiedToClipboard),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
          ),
        ],
      ),
    );
  }

  Widget _buildSideBySideView(
    ThemeData theme,
    bool isDark,
    AppLocalizations l10n,
    BoxConstraints constraints,
  ) {
    const dividerWidth = 7.0;
    final totalWidth = constraints.maxWidth;
    final availableWidth = (totalWidth - dividerWidth).clamp(200.0, 10000.0);
    final leftWidth = (availableWidth * _sideSplitRatio).clamp(
      100.0,
      availableWidth - 100.0,
    );
    final rightWidth = availableWidth - leftWidth;

    return Scrollbar(
      controller: _verticalController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _verticalController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final hunk in widget.diff.hunks) ...[
              // Hunk header
              _buildHunkHeader(hunk, theme, isDark, l10n),

              // Paired lines
              for (final pair in _pairHunkLines(hunk.lines))
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left cell (Old / Deletion)
                      SizedBox(
                        width: leftWidth,
                        child: _buildSideCell(
                          pair.left,
                          isDark,
                          theme,
                          l10n,
                          isLeft: true,
                        ),
                      ),
                      // Draggable column divider
                      MouseRegion(
                        cursor: SystemMouseCursors.resizeLeftRight,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onDoubleTap: () =>
                              setState(() => _sideSplitRatio = 0.5),
                          onHorizontalDragUpdate: (details) {
                            setState(() {
                              _sideSplitRatio =
                                  (_sideSplitRatio +
                                          details.delta.dx / availableWidth)
                                      .clamp(0.2, 0.8);
                            });
                          },
                          child: Container(
                            width: dividerWidth,
                            color: Colors.transparent,
                            alignment: Alignment.center,
                            child: Container(
                              width: 1,
                              color: theme.colorScheme.outlineVariant.withAlpha(
                                80,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Right cell (New / Addition)
                      SizedBox(
                        width: rightWidth,
                        child: _buildSideCell(
                          pair.right,
                          isDark,
                          theme,
                          l10n,
                          isLeft: false,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSideCell(
    GitDiffLine? line,
    bool isDark,
    ThemeData theme,
    AppLocalizations l10n, {
    required bool isLeft,
  }) {
    if (line == null) {
      return Container(
        color: isDark
            ? theme.colorScheme.surfaceContainerLowest.withAlpha(80)
            : theme.colorScheme.surfaceContainerLow.withAlpha(50),
      );
    }

    Color? bgColor;
    Color textColor = theme.colorScheme.onSurface;
    if (line.isAddition) {
      bgColor = isDark
          ? AppColors.diffAddedLineBgDark
          : AppColors.diffAddedLineBgLight;
      textColor = AppColors.diffAddedText;
    } else if (line.isDeletion) {
      bgColor = isDark
          ? AppColors.diffDeletedLineBgDark
          : AppColors.diffDeletedLineBgLight;
      textColor = AppColors.diffDeletedText;
    }

    final lineNumber = isLeft ? line.oldLineNumber : line.newLineNumber;

    Widget textWidget = SelectableText(
      line.text,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        height: 1.4,
        color: textColor,
      ),
    );

    if (!_wordWrap) {
      textWidget = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: textWidget,
      );
    }

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line Number
          SizedBox(
            width: 36,
            child: Text(
              lineNumber?.toString() ?? '',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          // Code Content
          Expanded(child: textWidget),
        ],
      ),
    );
  }

  List<_DiffLinePair> _pairHunkLines(List<GitDiffLine> lines) {
    final pairs = <_DiffLinePair>[];
    int i = 0;
    while (i < lines.length) {
      final line = lines[i];
      if (line.isContext) {
        pairs.add(_DiffLinePair(left: line, right: line));
        i++;
      } else if (line.isDeletion || line.isAddition) {
        final deletions = <GitDiffLine>[];
        while (i < lines.length && lines[i].isDeletion) {
          deletions.add(lines[i]);
          i++;
        }
        final additions = <GitDiffLine>[];
        while (i < lines.length && lines[i].isAddition) {
          additions.add(lines[i]);
          i++;
        }
        final maxCount = deletions.length > additions.length
            ? deletions.length
            : additions.length;
        for (int k = 0; k < maxCount; k++) {
          final del = k < deletions.length ? deletions[k] : null;
          final add = k < additions.length ? additions[k] : null;
          pairs.add(_DiffLinePair(left: del, right: add));
        }
      } else {
        i++;
      }
    }
    return pairs;
  }

  Future<void> _toggleHunk(GitDiffHunk hunk) async {
    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    final patch = hunk.toPatchString(widget.diff.filePath);
    final isStaged = widget.isStaged;
    final title = isStaged ? 'Unstaging hunk' : 'Staging hunk';

    await ref
        .read(gitTaskProvider.notifier)
        .run(
          title: title,
          action: (progress) async {
            final gitService = ref.read(gitServiceProvider);
            if (isStaged) {
              await gitService.unstageHunk(repoPath, patch);
            } else {
              await gitService.stageHunk(repoPath, patch);
            }
            ref.read(currentRepoProvider.notifier).refresh();
          },
        );
  }
}
