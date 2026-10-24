import 'dart:async';
import 'dart:io';

class RepoWatcherService {
  StreamSubscription<FileSystemEvent>? _subscription;
  Timer? _debounceTimer;
  String? _watchedPath;
  void Function()? _onChangedCallback;
  bool _isPaused = false;

  void watch(String repoPath, void Function() onRepoChanged) {
    if (_watchedPath == repoPath && _subscription != null) {
      _onChangedCallback = onRepoChanged;
      return;
    }
    stop();

    _watchedPath = repoPath;
    _onChangedCallback = onRepoChanged;
    final dir = Directory(repoPath);
    if (!dir.existsSync()) return;

    try {
      _subscription = dir.watch(recursive: true).listen((event) {
        if (_isPaused) return;

        final path = event.path.replaceAll('\\', '/');

        // Ignore temporary locks, editor backups, build and IDE caches
        if (path.endsWith('.lock') ||
            path.endsWith('~') ||
            path.endsWith('.tmp') ||
            path.contains('/.dart_tool/') ||
            path.contains('/build/') ||
            path.contains('/.idea/') ||
            path.contains('/.vscode/') ||
            path.contains('/node_modules/')) {
          return;
        }

        // Inside .git, watch refs, HEAD, packed-refs, config, and index
        if (path.contains('/.git/')) {
          final isRefs = path.contains('/.git/refs/');
          final isHead = path.endsWith('/.git/HEAD');
          final isIndex = path.endsWith('/.git/index');
          final isConfig = path.endsWith('/.git/config');
          final isPackedRefs = path.endsWith('/.git/packed-refs');
          if (!isRefs && !isHead && !isIndex && !isConfig && !isPackedRefs) {
            return;
          }
        }

        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 400), () {
          if (!_isPaused && _onChangedCallback != null) {
            _onChangedCallback!();
          }
        });
      });
    } catch (_) {
      // Some file systems or permission issues might prevent watching
    }
  }

  void pause() {
    _isPaused = true;
    _debounceTimer?.cancel();
  }

  void resume({bool triggerNow = false}) {
    _isPaused = false;
    if (triggerNow && _onChangedCallback != null) {
      _debounceTimer?.cancel();
      _onChangedCallback!();
    }
  }

  void stop() {
    _debounceTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
    _watchedPath = null;
    _onChangedCallback = null;
    _isPaused = false;
  }
}
