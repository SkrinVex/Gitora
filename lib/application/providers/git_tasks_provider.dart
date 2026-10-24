import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitora/application/providers/log_provider.dart';

class GitTaskState {
  final bool isRunning;
  final String? taskTitle;
  final String? progressMessage;
  final String? lastError;
  final String? lastSuccess;

  const GitTaskState({
    this.isRunning = false,
    this.taskTitle,
    this.progressMessage,
    this.lastError,
    this.lastSuccess,
  });

  GitTaskState copyWith({
    bool? isRunning,
    String? taskTitle,
    String? progressMessage,
    String? lastError,
    String? lastSuccess,
  }) {
    return GitTaskState(
      isRunning: isRunning ?? this.isRunning,
      taskTitle: taskTitle,
      progressMessage: progressMessage,
      lastError: lastError,
      lastSuccess: lastSuccess,
    );
  }
}

class GitTaskNotifier extends Notifier<GitTaskState> {
  @override
  GitTaskState build() => const GitTaskState();

  Future<T?> run<T>({
    required String title,
    required Future<T> Function(void Function(String message) updateProgress)
    action,
  }) async {
    state = state.copyWith(
      isRunning: true,
      taskTitle: title,
      progressMessage: '',
      lastError: null,
      lastSuccess: null,
    );

    try {
      final result = await action((msg) {
        state = state.copyWith(
          isRunning: true,
          taskTitle: title,
          progressMessage: msg,
        );
      });

      state = state.copyWith(
        isRunning: false,
        lastSuccess: '$title completed successfully',
      );
      ref
          .read(logProvider.notifier)
          .logInfo('$title completed successfully', source: 'Git');
      return result;
    } catch (e, stackTrace) {
      final err = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isRunning: false, lastError: err);
      ref
          .read(logProvider.notifier)
          .logError(
            'Error during: $title',
            details: err,
            stackTrace: stackTrace,
            source: 'Git',
          );
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
