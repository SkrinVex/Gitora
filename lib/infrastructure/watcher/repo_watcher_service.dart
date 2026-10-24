import 'dart:async';
import 'dart:io';

class RepoWatcherService {
  StreamSubscription<FileSystemEvent>? _subscription;
  Timer? _debounceTimer;
  String? _watchedPath;

  void watch(String repoPath, void Function() onRepoChanged) {
    if (_watchedPath == repoPath && _subscription != null) return;
    stop();

    _watchedPath = repoPath;
    final dir = Directory(repoPath);
    if (!dir.existsSync()) return;

    try {
      _subscription = dir.watch(recursive: true).listen((event) {
        // Ignore changes inside .git/objects or temp files
        final path = event.path.replaceAll('\\', '/');
        if (path.contains('/.git/objects') || path.contains('/.git/logs')) {
          return;
        }

        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 350), () {
          onRepoChanged();
        });
      });
    } catch (_) {
      // Some file systems or permission issues might prevent watching
    }
  }

  void stop() {
    _debounceTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
    _watchedPath = null;
  }
}
