import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitora/application/providers/git_branches_provider.dart';
import 'package:gitora/application/providers/git_history_provider.dart';
import 'package:gitora/application/providers/git_remotes_provider.dart';
import 'package:gitora/application/providers/git_stashes_provider.dart';
import 'package:gitora/application/providers/recent_repos_provider.dart';
import 'package:gitora/application/providers/repository_state_provider.dart';
import 'package:gitora/application/providers/settings_provider.dart';
import 'package:gitora/core/constants/app_constants.dart';
import 'package:gitora/domain/models/repository_item.dart';
import 'package:gitora/infrastructure/watcher/repo_watcher_service.dart';

final repoWatcherServiceProvider = Provider<RepoWatcherService>((ref) {
  final watcher = RepoWatcherService();
  ref.onDispose(() => watcher.stop());
  return watcher;
});

class RepoStatusRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void trigger() => state++;
}

final repoStatusRefreshTriggerProvider =
    NotifierProvider<RepoStatusRefreshNotifier, int>(
      RepoStatusRefreshNotifier.new,
    );

class CurrentRepoNotifier extends Notifier<String?> {
  @override
  String? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final lastPath = prefs?.getString(AppConstants.prefLastRepoPath);
    if (lastPath != null && lastPath.isNotEmpty) {
      final canonical = RepositoryItem.normalizePath(lastPath);
      // Start watcher on init
      Future.microtask(() {
        final watcher = ref.read(repoWatcherServiceProvider);
        watcher.watch(canonical, () {
          ref.read(repositoryStateProvider.notifier).refresh();
          ref.invalidate(gitBranchesProvider);
          ref.invalidate(gitRemotesProvider);
          ref.invalidate(gitStashesProvider);
        });
      });
      return canonical;
    }
    return null;
  }

  void setRepo(String? path) {
    if (path != null) {
      final canonical = RepositoryItem.normalizePath(path);
      state = canonical;
      final prefs = ref.read(sharedPreferencesProvider);
      prefs?.setString(AppConstants.prefLastRepoPath, canonical);

      // Save/update in database and update recentReposProvider immediately
      ref.read(recentReposProvider.notifier).addOrUpdateRepository(canonical);

      // Watch repository directory
      final watcher = ref.read(repoWatcherServiceProvider);
      watcher.watch(canonical, () {
        ref.read(repositoryStateProvider.notifier).refresh();
        ref.invalidate(gitBranchesProvider);
        ref.invalidate(gitRemotesProvider);
        ref.invalidate(gitStashesProvider);
      });
    } else {
      state = null;
      final prefs = ref.read(sharedPreferencesProvider);
      prefs?.remove(AppConstants.prefLastRepoPath);
      ref.read(repoWatcherServiceProvider).stop();
    }
  }

  void refresh() {
    ref.read(repositoryStateProvider.notifier).refresh();
    ref.invalidate(gitBranchesProvider);
    ref.invalidate(gitRemotesProvider);
    ref.invalidate(gitStashesProvider);
    ref.invalidate(gitHistoryProvider);
  }
}

final currentRepoProvider = NotifierProvider<CurrentRepoNotifier, String?>(
  CurrentRepoNotifier.new,
);
