import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitora/infrastructure/git/git_cli_service.dart';

void main() {
  late GitCliService gitService;
  late Directory tempDir;

  setUp(() async {
    gitService = GitCliService();
    tempDir = await Directory.systemTemp.createTemp('gitora_hunk_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'Multi-hunk partial staging and unstaging on real Git repository',
    () async {
      final repoPath = tempDir.path;

      // 1. Initialize repo
      await gitService.initRepository(repoPath);

      // 2. Create a 40-line file
      final initialLines = List.generate(40, (i) => 'Original line $i');
      final testFile = File('$repoPath/multi_hunk_file.txt');
      await testFile.writeAsString('${initialLines.join('\n')}\n', flush: true);

      // Initial commit
      await gitService.stageAll(repoPath);
      await gitService.commit(repoPath, message: 'Initial 40 lines commit');

      // 3. Create two widely separated hunks (Line 5 and Line 35)
      final modifiedLines = List<String>.from(initialLines);
      modifiedLines[5] = 'MODIFIED LINE 5 (HUNK 1)';
      modifiedLines[35] = 'MODIFIED LINE 35 (HUNK 2)';
      await testFile.writeAsString(
        '${modifiedLines.join('\n')}\n',
        flush: true,
      );

      // 4. Verify that diff detects 2 distinct hunks
      final diffUnstaged = await gitService.getDiff(
        repoPath,
        filePath: 'multi_hunk_file.txt',
      );
      expect(
        diffUnstaged.hunks.length,
        equals(2),
        reason: 'Must detect two distinct hunks separated by distance',
      );

      // 5. Stage ONLY the first hunk
      final hunk1Patch = diffUnstaged.hunks[0].toPatchString(
        'multi_hunk_file.txt',
      );
      await gitService.stageHunk(repoPath, hunk1Patch);

      // 6. Check Git status: file must be in both staged AND unstaged lists
      var status = await gitService.getStatus(repoPath);
      expect(status.staged.any((f) => f.path == 'multi_hunk_file.txt'), isTrue);
      expect(
        status.unstaged.any((f) => f.path == 'multi_hunk_file.txt'),
        isTrue,
      );

      // 7. Inspect staged diff: should contain ONLY Hunk 1 modifications
      final stagedDiff = await gitService.getDiff(
        repoPath,
        filePath: 'multi_hunk_file.txt',
        isStaged: true,
      );
      expect(stagedDiff.hunks.length, equals(1));
      expect(
        stagedDiff.hunks[0].lines.any(
          (l) => l.text.contains('MODIFIED LINE 5'),
        ),
        isTrue,
      );
      expect(
        stagedDiff.hunks[0].lines.any(
          (l) => l.text.contains('MODIFIED LINE 35'),
        ),
        isFalse,
      );

      // 8. Test UNSTAGE HUNK: Unstage hunk 1 back to working directory
      final unstagePatch = stagedDiff.hunks[0].toPatchString(
        'multi_hunk_file.txt',
      );
      await gitService.unstageHunk(repoPath, unstagePatch);

      // Now nothing should be staged
      status = await gitService.getStatus(repoPath);
      expect(status.staged.isEmpty, isTrue);
      expect(
        status.unstaged.any((f) => f.path == 'multi_hunk_file.txt'),
        isTrue,
      );

      // 9. Stage both hunks sequentially
      final freshDiff = await gitService.getDiff(
        repoPath,
        filePath: 'multi_hunk_file.txt',
      );
      expect(freshDiff.hunks.length, equals(2));
      await gitService.stageHunk(
        repoPath,
        freshDiff.hunks[0].toPatchString('multi_hunk_file.txt'),
      );
      await gitService.stageHunk(
        repoPath,
        freshDiff.hunks[1].toPatchString('multi_hunk_file.txt'),
      );

      // Both should be staged, nothing unstaged
      status = await gitService.getStatus(repoPath);
      expect(status.staged.any((f) => f.path == 'multi_hunk_file.txt'), isTrue);
      expect(status.unstaged.isEmpty, isTrue);
    },
  );

  test('Partial staging with CRLF (\\r\\n) Windows line endings', () async {
    final repoPath = tempDir.path;
    await gitService.initRepository(repoPath);

    // Create file with CRLF endings
    final crlfFile = File('$repoPath/crlf_sample.txt');
    await crlfFile.writeAsString(
      'Line One\r\nLine Two\r\nLine Three\r\nLine Four\r\n',
      flush: true,
    );
    await gitService.stageAll(repoPath);
    await gitService.commit(repoPath, message: 'CRLF initial');

    // Modify line 2 with CRLF
    await crlfFile.writeAsString(
      'Line One\r\nLine Two MODIFIED\r\nLine Three\r\nLine Four\r\n',
      flush: true,
    );

    final diff = await gitService.getDiff(
      repoPath,
      filePath: 'crlf_sample.txt',
    );
    expect(diff.hunks.isNotEmpty, isTrue);

    // Stage hunk must succeed without throwing "patch does not apply"
    final patch = diff.hunks.first.toPatchString('crlf_sample.txt');
    await gitService.stageHunk(repoPath, patch);

    final status = await gitService.getStatus(repoPath);
    expect(status.staged.any((f) => f.path == 'crlf_sample.txt'), isTrue);
    expect(status.unstaged.isEmpty, isTrue);
  });

  test('Partial staging with Unicode and Cyrillic paths and contents', () async {
    final repoPath = tempDir.path;
    await gitService.initRepository(repoPath);

    final testDir = Directory('$repoPath/модуль');
    await testDir.create(recursive: true);
    final unicodeFile = File('${testDir.path}/исходник.dart');
    await unicodeFile.writeAsString(
      '// Тестовый файл\nvoid main() {\n  print("Привет, мир!");\n  int x = 42;\n}\n',
      flush: true,
    );
    await gitService.stageAll(repoPath);
    await gitService.commit(repoPath, message: 'Unicode initial');

    // Modify file
    await unicodeFile.writeAsString(
      '// Тестовый файл\nvoid main() {\n  print("Привет, Gitora!");\n  int x = 100;\n}\n',
      flush: true,
    );

    final statusBefore = await gitService.getStatus(repoPath);
    expect(statusBefore.unstaged.length, equals(1));
    final relativePath = statusBefore.unstaged.first.path;

    final diff = await gitService.getDiff(repoPath, filePath: relativePath);
    expect(diff.hunks.isNotEmpty, isTrue);

    final patch = diff.hunks.first.toPatchString(relativePath);
    await gitService.stageHunk(repoPath, patch);

    final statusAfter = await gitService.getStatus(repoPath);
    expect(statusAfter.staged.any((f) => f.path == relativePath), isTrue);
    expect(statusAfter.unstaged.isEmpty, isTrue);
  });
}
