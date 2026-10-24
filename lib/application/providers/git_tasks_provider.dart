import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitora/application/providers/current_repo_provider.dart';
import 'package:gitora/application/providers/git_branches_provider.dart';
import 'package:gitora/application/providers/git_history_provider.dart';
import 'package:gitora/application/providers/git_remotes_provider.dart';
import 'package:gitora/application/providers/git_stashes_provider.dart';
import 'package:gitora/application/providers/log_provider.dart';
import 'package:gitora/application/providers/repository_state_provider.dart';

class GitTaskState {
  final bool isRunning;
  final String? taskTitle;
  final String? progressMessage;
  final double? progressPercent;
  final String? lastError;
  final String? lastSuccess;
  final DateTime? startedAt;

  const GitTaskState({
    this.isRunning = false,
    this.taskTitle,
    this.progressMessage,
    this.progressPercent,
    this.lastError,
    this.lastSuccess,
    this.startedAt,
  });

  GitTaskState copyWith({
    bool? isRunning,
    String? taskTitle,
    String? progressMessage,
    double? progressPercent,
    bool clearPercent = false,
    String? lastError,
    String? lastSuccess,
    DateTime? startedAt,
  }) {
    return GitTaskState(
      isRunning: isRunning ?? this.isRunning,
      taskTitle: taskTitle ?? this.taskTitle,
      progressMessage: progressMessage ?? this.progressMessage,
      progressPercent:
          clearPercent ? null : (progressPercent ?? this.progressPercent),
      lastError: lastError,
      lastSuccess: lastSuccess,
      startedAt: startedAt ?? this.startedAt,
    );
  }
}

class GitTaskNotifier extends Notifier<GitTaskState> {
  @override
  GitTaskState build() => const GitTaskState();

  Future<T?> run<T>({
    required String title,
    required Future<T> Function(
      void Function(String message, [double? percent]) updateProgress,
    )
    action,
  }) async {
    // Prevent duplicate concurrent execution of Git tasks
    if (state.isRunning) {
      return null;
    }

    // Pause file watcher during Git operations to prevent race conditions with lock files
    ref.read(repoWatcherServiceProvider).pause();

    state = state.copyWith(
      isRunning: true,
      taskTitle: title,
      progressMessage: '',
      clearPercent: true,
      lastError: null,
      lastSuccess: null,
      startedAt: DateTime.now(),
    );

    try {
      final result = await action((msg, [percent]) {
        state = state.copyWith(
          isRunning: true,
          taskTitle: title,
          progressMessage: msg,
          progressPercent: percent,
        );
      });

      state = state.copyWith(
        isRunning: false,
        clearPercent: true,
        lastSuccess: '$title completed successfully',
      );
      ref
          .read(logProvider.notifier)
          .logInfo('$title completed successfully', source: 'Git');

      // Resume watcher and trigger automatic state synchronization
      ref.read(repoWatcherServiceProvider).resume();
      await ref.read(repositoryStateProvider.notifier).refresh();
      ref.invalidate(gitBranchesProvider);
      ref.invalidate(gitRemotesProvider);
      ref.invalidate(gitStashesProvider);
      ref.invalidate(gitHistoryProvider);

      return result;
    } catch (e, stackTrace) {
      final err = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isRunning: false,
        clearPercent: true,
        lastError: err,
      );
      ref
          .read(logProvider.notifier)
          .logError(
            'Error during: $title',
            details: err,
            stackTrace: stackTrace,
            source: 'Git',
          );

      // Resume watcher and trigger refresh to reflect current disk state
      ref.read(repoWatcherServiceProvider).resume();
      await ref.read(repositoryStateProvider.notifier).refresh();
      ref.invalidate(gitBranchesProvider);
      ref.invalidate(gitRemotesProvider);
      ref.invalidate(gitStashesProvider);

      return null;
    }
  }

  void clearMessages() {
    state = state.copyWith(lastError: null, lastSuccess: null);
  }
}

final gitTaskProvider = NotifierProvider<GitTaskNotifier, GitTaskState>(
  GitTaskNotifier.new,
);
