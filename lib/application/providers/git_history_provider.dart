import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitora/application/providers/current_repo_provider.dart';
import 'package:gitora/application/providers/git_service_provider.dart';
import 'package:gitora/application/providers/repository_state_provider.dart';
import 'package:gitora/domain/models/git_commit.dart';
import 'package:gitora/domain/models/git_file_change.dart';

class HistoryFilterState {
  final String searchQuery;
  final String? selectedCommitHash;

  const HistoryFilterState({this.searchQuery = '', this.selectedCommitHash});

  HistoryFilterState copyWith({
    String? searchQuery,
    String? selectedCommitHash,
  }) {
    return HistoryFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCommitHash: selectedCommitHash,
    );
  }
}

class HistoryFilterNotifier extends Notifier<HistoryFilterState> {
  @override
  HistoryFilterState build() => const HistoryFilterState();

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void selectCommit(String? hash) {
    state = state.copyWith(selectedCommitHash: hash);
  }
}

final historyFilterProvider =
    NotifierProvider<HistoryFilterNotifier, HistoryFilterState>(
      HistoryFilterNotifier.new,
    );

final gitHistoryProvider = FutureProvider<List<GitCommit>>((ref) async {
  final repoPath = ref.watch(currentRepoProvider);
  // Only reload history when branch or head commit changes
  ref.watch(
    repositoryStateProvider.select((s) => '${s.branchName}@${s.headCommit}'),
  );
  final filter = ref.watch(historyFilterProvider);

  if (repoPath == null || repoPath.isEmpty) {
    return [];
  }

  final gitService = ref.watch(gitServiceProvider);
  final isRepo = await gitService.isGitRepository(repoPath);
  if (!isRepo) return [];

  final commits = await gitService.getHistory(
    repoPath,
    limit: 150,
    search: filter.searchQuery,
  );

  // Compute graph lanes for commits
  _computeGraphLanes(commits);

  return commits;
});

void _computeGraphLanes(List<GitCommit> commits) {
  final activeLanes = <String?>[];

  for (final commit in commits) {
    int lane = activeLanes.indexOf(commit.hash);
    if (lane == -1) {
      lane = activeLanes.indexOf(null);
      if (lane == -1) {
        lane = activeLanes.length;
        activeLanes.add(commit.hash);
      } else {
        activeLanes[lane] = commit.hash;
      }
    }

    commit.lane = lane;

    if (commit.parentHashes.isNotEmpty) {
      activeLanes[lane] = commit.parentHashes.first;
      for (int i = 1; i < commit.parentHashes.length; i++) {
        final parentHash = commit.parentHashes[i];
        if (!activeLanes.contains(parentHash)) {
          int freeLane = activeLanes.indexOf(null);
          if (freeLane == -1) {
            activeLanes.add(parentHash);
          } else {
            activeLanes[freeLane] = parentHash;
          }
        }
      }
    } else {
      activeLanes[lane] = null;
    }
  }
}

final selectedCommitFilesProvider = FutureProvider<List<GitFileChange>>((
  ref,
) async {
  final repoPath = ref.watch(currentRepoProvider);
  final filter = ref.watch(historyFilterProvider);
  final hash = filter.selectedCommitHash;

  if (repoPath == null || hash == null) return [];

  final gitService = ref.watch(gitServiceProvider);
  return await gitService.getCommitFiles(repoPath, hash);
});
