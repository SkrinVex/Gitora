import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitora/application/providers/repository_state_provider.dart';
import 'package:gitora/domain/models/git_status.dart';

final gitStatusProvider = Provider<AsyncValue<GitStatusResult?>>((ref) {
  final repoState = ref.watch(repositoryStateProvider);
  if (repoState.repoPath == null) {
    return const AsyncData(null);
  }
  // Only report loading on initial empty load before any data has been fetched
  if (repoState.isLoading &&
      repoState.headCommit == null &&
      repoState.totalChanges == 0 &&
      repoState.isClean) {
    return const AsyncLoading();
  }
  return AsyncData(repoState.toGitStatusResult());
});
