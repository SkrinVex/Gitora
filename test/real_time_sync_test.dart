import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitora/application/providers/current_repo_provider.dart';
import 'package:gitora/application/providers/database_provider.dart';
import 'package:gitora/application/providers/git_history_provider.dart';
import 'package:gitora/application/providers/git_service_provider.dart';
import 'package:gitora/application/providers/git_status_provider.dart';
import 'package:gitora/application/providers/git_tasks_provider.dart';
import 'package:gitora/application/providers/repository_state_provider.dart';
import 'package:gitora/domain/models/repository_item.dart';
import 'package:gitora/infrastructure/db/database_service.dart';
import 'package:gitora/infrastructure/git/git_cli_service.dart';

class FakeDatabaseService implements DatabaseService {
  @override
  Future<List<RepositoryItem>> getRepositories() async => [];
  @override
  Future<void> saveRepository(RepositoryItem item) async {}
  @override
  Future<void> removeRepository(String path) async {}
  @override
  Future<void> toggleFavorite(String path) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory tempDir;
  late String repoPath;
  late GitCliService git;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'gitora_sync_test_кириллица_',
    );
    repoPath = tempDir.path;
    git = GitCliService();

    await git.initRepository(repoPath);

    // Set local git config user for commit
    await Process.run('git', [
      'config',
      'user.name',
      'Gitora Tester',
    ], workingDirectory: repoPath);
    await Process.run('git', [
      'config',
      'user.email',
      'test@gitora.dev',
    ], workingDirectory: repoPath);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    }
  });

  test(
    'Real-time Git state synchronization and unique change counting',
    () async {
      // 1. Create 3 files including Unicode name
      final f1 = File('$repoPath/file1.txt');
      final f2 = File('$repoPath/file2.txt');
      final f3 = File('$repoPath/документ.md');

      await f1.writeAsString('Content 1\n');
      await f2.writeAsString('Content 2\n');
      await f3.writeAsString('Содержимое документа\n');

      // 2. Check untracked files
      var status = await git.getStatus(repoPath);
      expect(status.untracked.length, 3);
      expect(status.staged.isEmpty, isTrue);
      expect(status.unstaged.isEmpty, isTrue);
      expect(status.totalChanges, 3);
      expect(status.isClean, isFalse);

      // 3. Stage one file (file1.txt)
      await git.stageFile(repoPath, 'file1.txt');
      status = await git.getStatus(repoPath);
      expect(status.staged.length, 1);
      expect(status.staged.first.path, 'file1.txt');
      expect(status.untracked.length, 2);
      expect(
        status.totalChanges,
        3,
        reason: 'Total unique files changed must remain 3',
      );

      // 4. Stage All
      await git.stageAll(repoPath);
      status = await git.getStatus(repoPath);
      expect(status.staged.length, 3);
      expect(status.untracked.isEmpty, isTrue);
      expect(status.unstaged.isEmpty, isTrue);
      expect(status.totalChanges, 3);

      // 5. Unstage newly added file (returns to untracked)
      await git.unstageFile(repoPath, 'file2.txt');
      status = await git.getStatus(repoPath);
      expect(status.staged.length, 2);
      expect(status.untracked.length, 1);
      expect(status.totalChanges, 3);

      // 6. Stage All again and Commit
      await git.stageAll(repoPath);
      await git.commit(repoPath, message: 'Initial commit: 3 files added');

      status = await git.getStatus(repoPath);
      expect(status.staged.isEmpty, isTrue);
      expect(status.unstaged.isEmpty, isTrue);
      expect(status.untracked.isEmpty, isTrue);
      expect(status.totalChanges, 0);
      expect(status.isClean, isTrue);
      expect(status.headCommit, isNotNull);

      // History check
      final history = await git.getHistory(repoPath, limit: 10);
      expect(history.length, 1);
      expect(history.first.message.trim(), 'Initial commit: 3 files added');

      // 7. External modification of committed file
      await f1.writeAsString('Content 1 modified externally\n');
      status = await git.getStatus(repoPath);
      expect(status.unstaged.length, 1);
      expect(status.totalChanges, 1);

      // 8. Stage modified committed file
      await git.stageFile(repoPath, 'file1.txt');
      status = await git.getStatus(repoPath);
      expect(status.staged.length, 1);
      expect(status.unstaged.isEmpty, isTrue);
      expect(status.totalChanges, 1);

      // Unstage committed file (returns to unstaged modified)
      await git.unstageFile(repoPath, 'file1.txt');
      status = await git.getStatus(repoPath);
      expect(status.staged.isEmpty, isTrue);
      expect(status.unstaged.length, 1);
      expect(status.totalChanges, 1);

      // Re-stage and then edit worktree again (partial staging)
      await git.stageFile(repoPath, 'file1.txt');
      await f1.writeAsString('Content 1 modified again in worktree\n');

      status = await git.getStatus(repoPath);
      expect(status.staged.length, 1);
      expect(status.unstaged.length, 1);
      // CRITICAL: unique file counting prevents double-counting file1.txt!
      expect(
        status.totalChanges,
        1,
        reason:
            'File modified in both index and worktree must only count as 1 changed file',
      );

      // 9. Discard unstaged changes
      await git.discardFileChanges(repoPath, 'file1.txt');
      status = await git.getStatus(repoPath);
      expect(status.staged.length, 1);
      expect(status.unstaged.isEmpty, isTrue);
      expect(status.totalChanges, 1);

      // 10. Commit staged change
      await git.commit(repoPath, message: 'Update file1.txt');
      status = await git.getStatus(repoPath);
      expect(status.isClean, isTrue);
      expect(status.totalChanges, 0);
    },
  );

  test(
    'Riverpod reactive pipeline automatically synchronizes repository state',
    () async {
      final container = ProviderContainer(
        overrides: [
          databaseServiceProvider.overrideWithValue(FakeDatabaseService()),
        ],
      );
      addTearDown(container.dispose);

      // 1. Create files
      await File('$repoPath/app.dart').writeAsString('void main() {}\n');
      await File('$repoPath/README.md').writeAsString('# Gitora Test\n');

      // Set repo
      container.read(currentRepoProvider.notifier).setRepo(repoPath);
      await container.read(repositoryStateProvider.notifier).refresh();

      // Read status in repositoryStateProvider
      var repoState = container.read(repositoryStateProvider);
      expect(repoState.repoPath, RepositoryItem.normalizePath(repoPath));
      expect(repoState.untracked.length, 2);
      expect(repoState.totalChanges, 2);
      expect(repoState.isClean, isFalse);

      // Verify gitStatusProvider mirror
      var statusAsync = container.read(gitStatusProvider);
      expect(statusAsync.value?.totalChanges, 2);

      // 2. Run Stage All through gitTaskProvider
      await container
          .read(gitTaskProvider.notifier)
          .run(
            title: 'Staging all changes',
            action: (progress) async {
              final gitService = container.read(gitServiceProvider);
              await gitService.stageAll(repoPath);
            },
          );

      // repositoryStateProvider and gitStatusProvider MUST be automatically updated!
      repoState = container.read(repositoryStateProvider);
      expect(repoState.staged.length, 2);
      expect(repoState.untracked.isEmpty, isTrue);
      expect(repoState.totalChanges, 2);

      statusAsync = container.read(gitStatusProvider);
      expect(statusAsync.value?.staged.length, 2);

      // 3. Commit through gitTaskProvider
      await container
          .read(gitTaskProvider.notifier)
          .run(
            title: 'Creating commit',
            action: (progress) async {
              final gitService = container.read(gitServiceProvider);
              await gitService.commit(
                repoPath,
                message: 'Commit from Riverpod pipeline',
              );
            },
          );

      // State MUST be clean now!
      repoState = container.read(repositoryStateProvider);
      expect(repoState.isClean, isTrue);
      expect(repoState.totalChanges, 0);
      expect(repoState.staged.isEmpty, isTrue);

      statusAsync = container.read(gitStatusProvider);
      expect(statusAsync.value?.isClean, isTrue);
      expect(statusAsync.value?.totalChanges, 0);

      // Verify gitHistoryProvider also updated
      final history = await container.read(gitHistoryProvider.future);
      expect(history.length, 1);
      expect(history.first.message.trim(), 'Commit from Riverpod pipeline');
    },
  );

  test(
    'RepositoryState isContentEqualTo prevents redundant UI updates when idle',
    () {
      const s1 = RepositoryState(
        repoPath: 'C:/project',
        branchName: 'main',
        headCommit: 'abcdef1',
        totalChanges: 0,
        ahead: 0,
        behind: 0,
        isLoading: false,
      );

      const s2 = RepositoryState(
        repoPath: 'C:/project',
        branchName: 'main',
        headCommit: 'abcdef1',
        totalChanges: 0,
        ahead: 0,
        behind: 0,
        isLoading: false,
      );

      expect(s1.isContentEqualTo(s2), isTrue);

      // Minor difference in totalChanges
      const s3 = RepositoryState(
        repoPath: 'C:/project',
        branchName: 'main',
        headCommit: 'abcdef1',
        totalChanges: 1,
        ahead: 0,
        behind: 0,
        isLoading: false,
      );

      expect(s1.isContentEqualTo(s3), isFalse);
    },
  );

  test('RepositoryItem path normalization and existence checks', () {
    expect(
      RepositoryItem.normalizePath(r'c:\users\lexa\repo'),
      'C:/users/lexa/repo',
    );
    expect(
      RepositoryItem.normalizePath(r'C:/users/lexa/repo/'),
      'C:/users/lexa/repo',
    );

    final existing = RepositoryItem(
      path: repoPath,
      name: 'TempRepo',
      lastOpened: DateTime.now(),
    );
    expect(existing.exists, isTrue);

    final missing = RepositoryItem(
      path: 'C:/non_existent_directory_gitora_test_9999',
      name: 'MissingRepo',
      lastOpened: DateTime.now(),
    );
    expect(missing.exists, isFalse);
  });
}
