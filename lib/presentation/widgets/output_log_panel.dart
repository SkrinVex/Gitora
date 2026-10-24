import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gitora/application/providers/log_provider.dart';
import 'package:gitora/core/theme/app_colors.dart';
import 'package:gitora/l10n/app_localizations.dart';

class OutputLogPanel extends ConsumerStatefulWidget {
  final double height;
  final ValueChanged<double> onHeightChanged;
  final VoidCallback onClose;

  const OutputLogPanel({
    super.key,
    required this.height,
    required this.onHeightChanged,
    required this.onClose,
  });

  @override
  ConsumerState<OutputLogPanel> createState() => _OutputLogPanelState();
}

class _OutputLogPanelState extends ConsumerState<OutputLogPanel> {
  bool _isDragging = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final logState = ref.watch(logProvider);
    final l10n = AppLocalizations.of(context)!;

    final filtered = logState.filteredEntries.where((e) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return e.title.toLowerCase().contains(q) ||
          (e.details?.toLowerCase().contains(q) ?? false) ||
          e.source.toLowerCase().contains(q);
    }).toList();

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E28) : const Color(0xFFF9F9FC),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(80),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 20),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Resize handle (draggable top border)
          MouseRegion(
            cursor: SystemMouseCursors.resizeUpDown,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (_) => setState(() => _isDragging = true),
              onVerticalDragEnd: (_) => setState(() => _isDragging = false),
              onVerticalDragUpdate: (details) {
                final newHeight = (widget.height - details.delta.dy).clamp(
                  120.0,
                  600.0,
                );
                widget.onHeightChanged(newHeight);
              },
              child: Container(
                height: 6,
                color: _isDragging
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                child: Center(
                  child: Container(
                    width: 36,
                    height: 3,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant.withAlpha(100),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Header toolbar
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withAlpha(60),
                ),
              ),
            ),
            child: Row(
              children: [
                // Tabs: Errors, Warnings, Output
                _buildTabButton(
                  title: l10n.errors,
                  count: logState.errorCount,
                  isSelected: logState.selectedTabIndex == 0,
                  badgeColor: AppColors.gitDeleted,
                  onTap: () => ref.read(logProvider.notifier).selectTab(0),
                ),
                const SizedBox(width: 8),
                _buildTabButton(
                  title: l10n.warnings,
                  count: logState.warningCount,
                  isSelected: logState.selectedTabIndex == 1,
                  badgeColor: Colors.amber.shade700,
                  onTap: () => ref.read(logProvider.notifier).selectTab(1),
                ),
                const SizedBox(width: 8),
                _buildTabButton(
                  title: l10n.output,
                  count: logState.entries.length,
                  isSelected: logState.selectedTabIndex == 2,
                  badgeColor: theme.colorScheme.primary,
                  onTap: () => ref.read(logProvider.notifier).selectTab(2),
                ),

                const Spacer(),

                // Search box
                SizedBox(
                  width: 180,
                  height: 28,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: l10n.filterLogs,
                      prefixIcon: const Icon(Icons.filter_list, size: 14),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 12),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              padding: EdgeInsets.zero,
                            )
                          : null,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 8),

                // Clear button
                IconButton(
                  icon: const Icon(Icons.clear_all, size: 18),
                  tooltip: l10n.clearLogs,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => ref.read(logProvider.notifier).clear(),
                ),

                // Close button
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: l10n.close,
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          // Log list body
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      l10n.noLogsRecorded,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final entry = filtered[index];
                      return _LogItemCard(entry: entry);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required int count,
    required bool isSelected,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.surfaceContainerHighest
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected
              ? Border.all(
                  color: theme.colorScheme.outlineVariant.withAlpha(80),
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.outline,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LogItemCard extends StatefulWidget {
  final LogEntry entry;

  const _LogItemCard({required this.entry});

  @override
  State<_LogItemCard> createState() => _LogItemCardState();
}

class _LogItemCardState extends State<_LogItemCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = widget.entry;
    final l10n = AppLocalizations.of(context)!;

    Color levelColor;
    IconData levelIcon;
    switch (entry.level) {
      case LogLevel.error:
        levelColor = AppColors.gitDeleted;
        levelIcon = Icons.error_outline;
        break;
      case LogLevel.warning:
        levelColor = Colors.amber.shade700;
        levelIcon = Icons.warning_amber_outlined;
        break;
      case LogLevel.info:
        levelColor = theme.colorScheme.primary;
        levelIcon = Icons.info_outline;
        break;
    }

    final hasDetails =
        (entry.details != null && entry.details!.isNotEmpty) ||
        (entry.stackTrace != null && entry.stackTrace!.isNotEmpty);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh.withAlpha(80),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(levelIcon, size: 16, color: levelColor),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.source,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableText(
                    entry.title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  DateFormat.Hms().format(entry.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(width: 6),

                // Copy single message button
                IconButton(
                  icon: const Icon(Icons.copy, size: 14),
                  tooltip: l10n.copyMessage,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 26,
                    minHeight: 26,
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: entry.title));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.copiedToClipboard),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),

                // Copy full report button
                if (hasDetails)
                  IconButton(
                    icon: const Icon(Icons.content_paste, size: 14),
                    tooltip: l10n.copyFullReport,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 26,
                      minHeight: 26,
                    ),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: entry.toFullReport()),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.copiedToClipboard),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),

                // Expand / Collapse details button
                if (hasDetails)
                  IconButton(
                    icon: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 26,
                      minHeight: 26,
                    ),
                    onPressed: () => setState(() => _expanded = !_expanded),
                  ),
              ],
            ),

            if (_expanded && hasDetails) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(
                    120,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  [
                    if (entry.details != null && entry.details!.isNotEmpty)
                      entry.details!,
                    if (entry.stackTrace != null &&
                        entry.stackTrace!.isNotEmpty)
                      entry.stackTrace!,
                  ].join('\n\n'),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
