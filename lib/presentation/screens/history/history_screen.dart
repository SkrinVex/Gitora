import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gitora/application/providers/git_history_provider.dart';
import 'package:gitora/domain/models/git_commit.dart';
import 'package:gitora/l10n/app_localizations.dart';
import 'package:gitora/presentation/screens/history/commit_details_panel.dart';
import 'package:gitora/presentation/screens/history/commit_graph_painter.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  static const double _itemHeight = 56.0;
  static const double _laneWidth = 18.0;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final historyAsync = ref.watch(gitHistoryProvider);
    final filter = ref.watch(historyFilterProvider);

    return Column(
      children: [
        // Top search bar
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
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchCommits,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(historyFilterProvider.notifier)
                                  .setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    ref
                        .read(historyFilterProvider.notifier)
                        .setSearchQuery(val);
                  },
                ),
              ),
            ],
          ),
        ),

        // Main area: Commit graph list + Commit Details panel
        Expanded(
          child: historyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading history: $e')),
            data: (commits) {
              if (commits.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history_toggle_off,
                        size: 48,
                        color: theme.colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noCommitsFound,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Compute maximum lane index to size the graph column properly
              int maxLane = 0;
              for (final c in commits) {
                if (c.lane > maxLane) maxLane = c.lane;
              }
              final graphWidth = (maxLane + 2) * _laneWidth;

              GitCommit? selectedCommit;
              int selectedIndex = -1;
              if (filter.selectedCommitHash != null) {
                selectedIndex = commits.indexWhere(
                  (c) => c.hash == filter.selectedCommitHash,
                );
                if (selectedIndex != -1) {
                  selectedCommit = commits[selectedIndex];
                }
              }

              return Row(
                children: [
                  // Left side: Commit graph list
                  Expanded(
                    flex: selectedCommit != null ? 5 : 10,
                    child: Stack(
                      children: [
                        // Background CustomPainter for lines and nodes
                        Positioned(
                          left: 0,
                          top: 0,
                          width: graphWidth,
                          height: commits.length * _itemHeight,
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: CommitGraphPainter(
                                commits: commits,
                                selectedIndex: selectedIndex,
                                itemHeight: _itemHeight,
                                laneWidth: _laneWidth,
                              ),
                            ),
                          ),
                        ),

                        // Scrollable list of commit rows
                        ListView.builder(
                          controller: _scrollController,
                          itemCount: commits.length,
                          itemExtent: _itemHeight,
                          itemBuilder: (context, index) {
                            final commit = commits[index];
                            final isSelected =
                                commit.hash == filter.selectedCommitHash;

                            return InkWell(
                              onTap: () {
                                ref
                                    .read(historyFilterProvider.notifier)
                                    .selectCommit(commit.hash);
                              },
                              child: Container(
                                color: isSelected
                                    ? theme.colorScheme.primaryContainer
                                          .withAlpha(60)
                                    : null,
                                padding: EdgeInsets.only(
                                  left: graphWidth + 12,
                                  right: 16,
                                ),
                                child: Row(
                                  children: [
                                    // Commit message
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            commit.summary,
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              fontSize: 13.5,
                                              color: isSelected
                                                  ? theme.colorScheme.primary
                                                  : theme.colorScheme.onSurface,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            commit.authorName,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: theme.colorScheme.outline,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    // Date
                                    Text(
                                      _formatDate(commit.date),
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: theme.colorScheme.outline,
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    // Short SHA
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        commit.shortHash,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Right side: Commit Details panel
                  if (selectedCommit != null)
                    Expanded(
                      flex: 5,
                      child: CommitDetailsPanel(commit: selectedCommit),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }
}
