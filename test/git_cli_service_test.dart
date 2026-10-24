import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitora/domain/models/git_file_change.dart';
import 'package:gitora/infrastructure/git/git_cli_service.dart';

void main() {
  late GitCliService gitService;
  late Directory tempDir;

  setUp(() async {
    gitService = GitCliService();
    tempDir = await Directory.systemTemp.createTemp('gitora_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'Real Git operations workflow: init, add, commit, diff, branch, stash',
    () async {
      final repoPath = tempDir.path;

      // 1. Check initially not a git repository
      expect(await gitService.isGitRepository(repoPath), isFalse);

      // 2. Initialize repository
      await gitService.initRepository(repoPath);
      expect(await gitService.isGitRepository(repoPath), isTrue);

      // 3. Create a test file with Cyrillic / Unicode content
      final testFile = File('${tempDir.path}/привет_мир.txt');
      await testFile.writeAsString(
        'Первая строка тестового файла\nSecond line\n',
        flush: true,
      );

      // 4. Status should show untracked file
      var status = await gitService.getStatus(repoPath);
      expect(status.untracked.length, equals(1));
      expect(status.untracked.first.path, contains('привет_мир.txt'));

      // 5. Stage the file
      await gitService.stageFile(repoPath, status.untracked.first.path);
      status = await gitService.getStatus(repoPath);
      expect(status.staged.length, equals(1));
      expect(status.staged.first.status, equals(GitFileStatus.added));

      // 6. Test Unstage
      await gitService.unstageFile(repoPath, status.staged.first.path);
      status = await gitService.getStatus(repoPath);
      expect(status.staged.isEmpty, isTrue);
      expect(status.untracked.isNotEmpty, isTrue);

      // 7. Stage all
      await gitService.stageAll(repoPath);
      status = await gitService.getStatus(repoPath);
      expect(status.staged.length, equals(1));

      // 8. Commit
      await gitService.commit(
        repoPath,
        message: 'Первый коммит: тест кириллицы',
      );
      status = await gitService.getStatus(repoPath);
      expect(status.staged.isEmpty, isTrue);
      expect(status.unstaged.isEmpty, isTrue);

      // 9. Verify history
      final history = await gitService.getHistory(repoPath, limit: 10);
      expect(history.length, equals(1));
      expect(history.first.message, contains('Первый коммит'));

      // 10. Check commit files
      final commitFiles = await gitService.getCommitFiles(
        repoPath,
        history.first.hash,
      );
      expect(commitFiles.length, equals(1));
      expect(commitFiles.first.path, contains('привет_мир.txt'));

      // 11. Modify file and check Diff
      await testFile.writeAsString(
        'Первая строка тестового файла\nНовая вторая строка!\nThird line\n',
        flush: true,
      );
      final diff = await gitService.getDiff(
        repoPath,
        filePath: commitFiles.first.path,
      );
      expect(diff.hunks.isNotEmpty, isTrue);
      expect(diff.additions, greaterThan(0));

      // 12. Create branch, list branches and switch branch
      await gitService.createBranch(repoPath, name: 'feature/test-branch');
      final branches = await gitService.getBranches(repoPath);
      expect(branches.any((b) => b.name == 'feature/test-branch'), isTrue);

      await gitService.checkout(repoPath, 'feature/test-branch');
      status = await gitService.getStatus(repoPath);
      expect(status.branchName, equals('feature/test-branch'));

      // 13. Stash changes
      await gitService.createStash(repoPath, message: 'WIP stash test');
      var stashes = await gitService.getStashes(repoPath);
      expect(stashes.length, equals(1));
      expect(stashes.first.message, contains('WIP stash test'));

      // Pop stash
      await gitService.popStash(repoPath, 0);
      stashes = await gitService.getStashes(repoPath);
      expect(stashes.isEmpty, isTrue);
    },
  );

  test('Push with no upstream automatically sets upstream and succeeds', () async {
    final repoPath = tempDir.path;
    await gitService.initRepository(repoPath);

    await Process.run('git', ['config', 'user.name', 'Gitora Tester'], workingDirectory: repoPath);
    await Process.run('git', ['config', 'user.email', 'test@gitora.dev'], workingDirectory: repoPath);

    final f = File('$repoPath/file.txt');
    await f.writeAsString('Hello World\n');
    await gitService.stageAll(repoPath);
    await gitService.commit(repoPath, message: 'Initial commit');

    // Create a bare remote repository
    final bareDir = await Directory.systemTemp.createTemp('gitora_bare_');
    addTearDown(() async {
      if (bareDir.existsSync()) {
        try {
          await bareDir.delete(recursive: true);
        } catch (_) {}
      }
    });
    await Process.run('git', ['init', '--bare'], workingDirectory: bareDir.path);

    // Add as remote origin
    await gitService.addRemote(repoPath, name: 'origin', url: bareDir.path.replaceAll('\\', '/'));

    // Check upstream is initially null
    var status = await gitService.getStatus(repoPath);
    expect(status.upstream, isNull);

    // Push with no arguments - should auto-recover and set upstream to origin!
    await gitService.push(repoPath);

    status = await gitService.getStatus(repoPath);
    expect(status.upstream, isNotNull);
    expect(status.upstream, contains('origin/'));
  });
}
