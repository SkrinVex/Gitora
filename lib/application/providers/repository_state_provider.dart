import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitora/application/providers/current_repo_provider.dart';
import 'package:gitora/application/providers/git_service_provider.dart';
import 'package:gitora/application/providers/git_tasks_provider.dart';
import 'package:gitora/domain/models/git_file_change.dart';
import 'package:gitora/domain/models/git_status.dart';

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Single source of truth for repository state in Gitora.
class RepositoryState {
  final String? repoPath;
  final String? headCommit;
  final String branchName;
  final String? upstream;
  final int ahead;
  final int behind;
  final List<GitFileChange> staged;
  final List<GitFileChange> unstaged;
  final List<GitFileChange> untracked;
  final List<GitFileChange> conflicted;
  final bool isMerging;
  final bool isRebasing;
  final int totalChanges;
  final GitTaskState currentTask;
  final String? lastError;
  final bool isLoading;

  const RepositoryState({
    this.repoPath,
    this.headCommit,
    this.branchName = 'HEAD (detached)',
    this.upstream,
    this.ahead = 0,
    this.behind = 0,
    this.staged = const [],
    this.unstaged = const [],
    this.untracked = const [],
    this.conflicted = const [],
    this.isMerging = false,
    this.isRebasing = false,
    this.totalChanges = 0,
    this.currentTask = const GitTaskState(),
    this.lastError,
    this.isLoading = false,
  });

  bool get isClean =>
      staged.isEmpty &&
      unstaged.isEmpty &&
      untracked.isEmpty &&
      conflicted.isEmpty;

  bool get hasStaged => staged.isNotEmpty;
  bool get hasUnstaged =>
      unstaged.isNotEmpty || untracked.isNotEmpty || conflicted.isNotEmpty;

  bool isContentEqualTo(RepositoryState? other) {
    if (other == null) return false;
    if (identical(this, other)) return true;
    if (repoPath != other.repoPath) return false;
    if (branchName != other.branchName) return false;
    if (upstream != other.upstream) return false;
    if (ahead != other.ahead) return false;
    if (behind != other.behind) return false;
    if (headCommit != other.headCommit) return false;
    if (isMerging != other.isMerging) return false;
    if (isRebasing != other.isRebasing) return false;
    if (totalChanges != other.totalChanges) return false;
    if (currentTask.isRunning != other.currentTask.isRunning) return false;
    if (currentTask.progressMessage != other.currentTask.progressMessage)
      return false;
    if (lastError != other.lastError) return false;
    if (!_listEquals(staged, other.staged)) return false;
    if (!_listEquals(unstaged, other.unstaged)) return false;
    if (!_listEquals(untracked, other.untracked)) return false;
    if (!_listEquals(conflicted, other.conflicted)) return false;
    return true;
  }

  RepositoryState copyWith({
    String? repoPath,
    String? headCommit,
    String? branchName,
    String? upstream,
    int? ahead,
    int? behind,
    List<GitFileChange>? staged,
    List<GitFileChange>? unstaged,
    List<GitFileChange>? untracked,
    List<GitFileChange>? conflicted,
    bool? isMerging,
    bool? isRebasing,
    int? totalChanges,
    GitTaskState? currentTask,
    String? lastError,
    bool? isLoading,
  }) {
    return RepositoryState(
      repoPath: repoPath ?? this.repoPath,
      headCommit: headCommit ?? this.headCommit,
      branchName: branchName ?? this.branchName,
      upstream: upstream ?? this.upstream,
      ahead: ahead ?? this.ahead,
      behind: behind ?? this.behind,
      staged: staged ?? this.staged,
      unstaged: unstaged ?? this.unstaged,
      untracked: untracked ?? this.untracked,
      conflicted: conflicted ?? this.conflicted,
      isMerging: isMerging ?? this.isMerging,
      isRebasing: isRebasing ?? this.isRebasing,
      totalChanges: totalChanges ?? this.totalChanges,
      currentTask: currentTask ?? this.currentTask,
      lastError: lastError ?? this.lastError,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  GitStatusResult toGitStatusResult() {
    return GitStatusResult(
      branchName: branchName,
      upstream: upstream,
      ahead: ahead,
      behind: behind,
      staged: staged,
      unstaged: unstaged,
      untracked: untracked,
      conflicted: conflicted,
      isMerging: isMerging,
      isRebasing: isRebasing,
      headCommit: headCommit,
    );
  }
}

class RepositoryStateNotifier extends Notifier<RepositoryState> {
  int _generation = 0;
  bool _isRefreshing = false;
  bool _pendingRefresh = false;
  Completer<void>? _refreshCompleter;

  @override
  RepositoryState build() {
    final repoPath = ref.watch(currentRepoProvider);
    if (repoPath == null || repoPath.isEmpty) {
      return const RepositoryState();
    }

    // Schedule initial load
    Future.microtask(() {
      if (ref.mounted) {
        refresh(isInitial: true);
      }
    });

    return RepositoryState(repoPath: repoPath, isLoading: true);
  }

  Future<void> refresh({bool isInitial = false}) async {
    if (!ref.mounted) return;
    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null || repoPath.isEmpty) {
      if (ref.mounted) state = const RepositoryState();
      return;
    }

    if (_isRefreshing) {
      _pendingRefresh = true;
      if (_refreshCompleter != null) {
        await _refreshCompleter!.future;
      }
      return;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<void>();
    final gen = ++_generation;

    try {
      final gitService = ref.read(gitServiceProvider);
      final isRepo = await gitService.isGitRepository(repoPath);
      if (!ref.mounted || gen != _generation) return;
      if (!isRepo) {
        state = RepositoryState(repoPath: repoPath, isLoading: false);
        return;
      }

      final status = await gitService.getStatus(repoPath);
      if (!ref.mounted || gen != _generation) return;
      final taskState = ref.read(gitTaskProvider);

      final newState = RepositoryState(
        repoPath: repoPath,
        headCommit: status.headCommit,
        branchName: status.branchName,
        upstream: status.upstream,
        ahead: status.ahead,
        behind: status.behind,
        staged: status.staged,
        unstaged: status.unstaged,
        untracked: status.untracked,
        conflicted: status.conflicted,
        isMerging: status.isMerging,
        isRebasing: status.isRebasing,
        totalChanges: status.totalChanges,
        currentTask: taskState,
        lastError: taskState.lastError,
        isLoading: false,
      );

      // CRITICAL: Content equality check!
      // If nothing actually changed on disk, DO NOT mutate state!
      // This guarantees zero rebuilds and zero flickering when idle!
      if (!isInitial && newState.isContentEqualTo(state)) {
        return;
      }

      state = newState;
    } catch (e) {
      if (ref.mounted && gen == _generation) {
        state = state.copyWith(lastError: e.toString(), isLoading: false);
      }
    } finally {
      _isRefreshing = false;
      final completer = _refreshCompleter;
      _refreshCompleter = null;
      if (completer != null && !completer.isCompleted) {
        completer.complete();
      }

      if (_pendingRefresh && ref.mounted) {
        _pendingRefresh = false;
        await refresh();
      }
    }
  }
}

final repositoryStateProvider =
    NotifierProvider<RepositoryStateNotifier, RepositoryState>(
      RepositoryStateNotifier.new,
    );
