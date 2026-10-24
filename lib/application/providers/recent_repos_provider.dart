import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitora/application/providers/database_provider.dart';
import 'package:gitora/domain/models/repository_item.dart';

class RecentReposNotifier extends AsyncNotifier<List<RepositoryItem>> {
  @override
  Future<List<RepositoryItem>> build() async {
    final db = ref.watch(databaseServiceProvider);
    return await db.getRepositories();
  }

  Future<void> addRepository(String path) async {
    final normalized = path.replaceAll('\\', '/');
    final name = normalized
        .split('/')
        .lastWhere((s) => s.isNotEmpty, orElse: () => 'Repository');
    final item = RepositoryItem(
      path: path,
      name: name,
      lastOpened: DateTime.now(),
    );

    final db = ref.read(databaseServiceProvider);
    await db.saveRepository(item);
    ref.invalidateSelf();
  }

  Future<void> toggleFavorite(String path) async {
    final db = ref.read(databaseServiceProvider);
    await db.toggleFavorite(path);
    ref.invalidateSelf();
  }

  Future<void> removeRepository(String path) async {
    final db = ref.read(databaseServiceProvider);
    await db.removeRepository(path);
    ref.invalidateSelf();
  }
}

final recentReposProvider =
    AsyncNotifierProvider<RecentReposNotifier, List<RepositoryItem>>(
      RecentReposNotifier.new,
    );
