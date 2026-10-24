import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitora/application/providers/database_provider.dart';
import 'package:gitora/domain/models/repository_item.dart';

class RecentReposNotifier extends AsyncNotifier<List<RepositoryItem>> {
  @override
  Future<List<RepositoryItem>> build() async {
    final db = ref.watch(databaseServiceProvider);
    return await db.getRepositories();
  }

  Future<void> addOrUpdateRepository(String path) async {
    final canonical = RepositoryItem.normalizePath(path);
    final normalized = canonical.replaceAll('\\', '/');
    final name = normalized
        .split('/')
        .lastWhere((s) => s.isNotEmpty, orElse: () => 'Repository');

    final currentList = state.value ?? [];
    final existingIndex = currentList.indexWhere(
      (r) => RepositoryItem.normalizePath(r.path) == canonical,
    );
    final isFav = existingIndex != -1
        ? currentList[existingIndex].isFavorite
        : false;

    final item = RepositoryItem(
      path: canonical,
      name: name,
      lastOpened: DateTime.now(),
      isFavorite: isFav,
    );

    final db = ref.read(databaseServiceProvider);
    await db.saveRepository(item);

    // Update state directly without loading spinner
    final updatedList = [
      item,
      for (final r in currentList)
        if (RepositoryItem.normalizePath(r.path) != canonical) r,
    ];
    _sortRepositories(updatedList);
    state = AsyncData(updatedList);
  }

  // Alias for backward compatibility
  Future<void> addRepository(String path) => addOrUpdateRepository(path);

  Future<void> toggleFavorite(String path) async {
    final canonical = RepositoryItem.normalizePath(path);
    final db = ref.read(databaseServiceProvider);
    await db.toggleFavorite(canonical);

    final currentList = state.value ?? [];
    final updatedList = currentList.map((r) {
      if (RepositoryItem.normalizePath(r.path) == canonical) {
        return r.copyWith(isFavorite: !r.isFavorite);
      }
      return r;
    }).toList();

    _sortRepositories(updatedList);
    state = AsyncData(updatedList);
  }

  Future<void> removeRepository(String path) async {
    final canonical = RepositoryItem.normalizePath(path);
    final db = ref.read(databaseServiceProvider);
    await db.removeRepository(canonical);

    final currentList = state.value ?? [];
    final updatedList = currentList
        .where((r) => RepositoryItem.normalizePath(r.path) != canonical)
        .toList();

    state = AsyncData(updatedList);
  }

  void _sortRepositories(List<RepositoryItem> list) {
    list.sort((a, b) {
      if (a.isFavorite != b.isFavorite) {
        return a.isFavorite ? -1 : 1;
      }
      return b.lastOpened.compareTo(a.lastOpened);
    });
  }
}

final recentReposProvider =
    AsyncNotifierProvider<RecentReposNotifier, List<RepositoryItem>>(
      RecentReposNotifier.new,
    );
