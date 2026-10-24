import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitora/application/providers/database_provider.dart';
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
      // Start watcher on init
      Future.microtask(() {
        final watcher = ref.read(repoWatcherServiceProvider);
        watcher.watch(lastPath, () {
          ref.invalidate(repoStatusRefreshTriggerProvider);
        });
      });
      return lastPath;
    }
    return null;
  }

  void setRepo(String? path) {
    state = path;
    final prefs = ref.read(sharedPreferencesProvider);
    if (path != null) {
      prefs?.setString(AppConstants.prefLastRepoPath, path);

      // Save or update in database
      final db = ref.read(databaseServiceProvider);
      final normalized = path.replaceAll('\\', '/');
      final name = normalized
          .split('/')
          .lastWhere((s) => s.isNotEmpty, orElse: () => 'Repository');
      db.saveRepository(
        RepositoryItem(path: path, name: name, lastOpened: DateTime.now()),
      );

      // Watch repository directory
      final watcher = ref.read(repoWatcherServiceProvider);
      watcher.watch(path, () {
        ref.invalidate(repoStatusRefreshTriggerProvider);
      });
    } else {
      prefs?.remove(AppConstants.prefLastRepoPath);
      ref.read(repoWatcherServiceProvider).stop();
    }
  }

  void refresh() {
    ref.invalidate(repoStatusRefreshTriggerProvider);
  }
}

final currentRepoProvider = NotifierProvider<CurrentRepoNotifier, String?>(
  CurrentRepoNotifier.new,
);
