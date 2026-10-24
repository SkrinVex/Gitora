import 'dart:convert';
import 'dart:io';
import 'package:gitora/domain/models/git_branch.dart';
import 'package:gitora/domain/models/git_commit.dart';
import 'package:gitora/domain/models/git_diff.dart';
import 'package:gitora/domain/models/git_file_change.dart';
import 'package:gitora/domain/models/git_remote.dart';
import 'package:gitora/domain/models/git_stash.dart';
import 'package:gitora/domain/models/git_status.dart';
import 'package:gitora/domain/models/git_system_info.dart';
import 'package:gitora/domain/models/git_user_config.dart';
import 'package:gitora/domain/services/git_service.dart';
import 'package:git2dart/git2dart.dart' as g2d;

class GitCliService implements GitService {
  String _customGitPath;

  GitCliService({this._customGitPath = 'git'});

  void setCustomGitPath(String path) {
    _customGitPath = path.isEmpty ? 'git' : path;
  }

  String get gitExecutable => _customGitPath;

  Future<ProcessResult> _run(
    List<String> args, {
    String? workingDirectory,
    bool throwOnError = true,
  }) async {
    // core.quotepath=false ensures Cyrillic and Unicode file paths are unescaped
    final fullArgs = ['-c', 'core.quotepath=false', ...args];
    try {
      final result = await Process.run(
        _customGitPath,
        fullArgs,
        workingDirectory: workingDirectory,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      if (throwOnError && result.exitCode != 0) {
        final err = result.stderr.toString().trim();
        final out = result.stdout.toString().trim();
        throw Exception(
          err.isNotEmpty
              ? err
              : (out.isNotEmpty
                    ? out
                    : 'Git command failed (${args.join(" ")}) with code ${result.exitCode}'),
        );
      }
      return result;
    } on ProcessException catch (e) {
      throw Exception('Failed to execute git process: ${e.message}');
    }
  }

  @override
  Future<GitSystemInfo> checkSystemInfo() async {
    bool cliOk = false;
    String cliVersion = '';
    String cliPath = _customGitPath;

    try {
      final res = await _run(['--version'], throwOnError: false);
      if (res.exitCode == 0) {
        cliOk = true;
        cliVersion = res.stdout.toString().trim();
      }
    } catch (_) {}

    bool libGit2Ok = false;
    String libGit2Ver = '';
    try {
      libGit2Ver = g2d.Libgit2.version;
      libGit2Ok = libGit2Ver.isNotEmpty;
    } catch (_) {}

    return GitSystemInfo(
      isCliInstalled: cliOk,
      cliVersion: cliVersion,
      cliPath: cliPath,
      isLibGit2Available: libGit2Ok,
      libGit2Version: libGit2Ver,
    );
  }

  @override
  Future<GitUserConfig> getUserConfig() async {
    String name = '';
    String email = '';
    try {
      final nameRes = await _run([
        'config',
        '--global',
        'user.name',
      ], throwOnError: false);
      if (nameRes.exitCode == 0) {
        name = nameRes.stdout.toString().trim();
      }
      final emailRes = await _run([
        'config',
        '--global',
        'user.email',
      ], throwOnError: false);
      if (emailRes.exitCode == 0) {
        email = emailRes.stdout.toString().trim();
      }
    } catch (_) {}
    return GitUserConfig(name: name, email: email);
  }

  @override
  Future<void> setUserConfig({
    required String name,
    required String email,
  }) async {
    await _run(['config', '--global', 'user.name', name]);
    await _run(['config', '--global', 'user.email', email]);
  }

  @override
  Future<bool> isGitRepository(String path) async {
    try {
      final res = await _run(
        ['rev-parse', '--is-inside-work-tree'],
        workingDirectory: path,
        throwOnError: false,
      );
      return res.exitCode == 0 && res.stdout.toString().trim() == 'true';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> initRepository(String path) async {
    await _run(['init'], workingDirectory: path);
  }

  @override
  Future<void> cloneRepository({
    required String url,
    required String targetPath,
    void Function(String message)? onProgress,
  }) async {
    final process = await Process.start(_customGitPath, [
      '-c',
      'core.quotepath=false',
      'clone',
      '--progress',
      url,
      targetPath,
    ]);

    process.stderr.transform(utf8.decoder).listen((data) {
      onProgress?.call(data.trim());
    });
    process.stdout.transform(utf8.decoder).listen((data) {
      onProgress?.call(data.trim());
    });

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception(
        'Failed to clone repository from $url into $targetPath (exit code: $exitCode)',
      );
    }
  }

  @override
  Future<GitStatusResult> getStatus(String repoPath) async {
    final res = await _run([
      'status',
      '--porcelain=v2',
      '--branch',
    ], workingDirectory: repoPath);

    final lines = res.stdout.toString().split('\n');
    String branch = 'HEAD (detached)';
    String? upstream;
    int ahead = 0;
    int behind = 0;

    final staged = <GitFileChange>[];
    final unstaged = <GitFileChange>[];
    final untracked = <GitFileChange>[];

    for (final line in lines) {
      if (line.isEmpty) continue;

      if (line.startsWith('# branch.head ')) {
        branch = line.substring('# branch.head '.length).trim();
      } else if (line.startsWith('# branch.upstream ')) {
        upstream = line.substring('# branch.upstream '.length).trim();
      } else if (line.startsWith('# branch.ab ')) {
        final parts = line.substring('# branch.ab '.length).trim().split(' ');
        if (parts.length >= 2) {
          ahead = int.tryParse(parts[0].replaceAll('+', '')) ?? 0;
          behind = int.tryParse(parts[1].replaceAll('-', '')) ?? 0;
        }
      } else if (line.startsWith('1 ') || line.startsWith('2 ')) {
        // Normal changed entry
        // Format: 1 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <path>
        // Format (renamed): 2 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <X><score> <path><tab><origPath>
        final parts = line.split(' ');
        if (parts.length >= 9) {
          final xy = parts[1];
          final stagedChar = xy[0];
          final unstagedChar = xy[1];

          String path = parts.sublist(8).join(' ');
          String? origPath;
          if (line.startsWith('2 ')) {
            final tabIndex = path.indexOf('\t');
            if (tabIndex != -1) {
              origPath = path.substring(tabIndex + 1);
              path = path.substring(0, tabIndex);
            }
          }

          if (stagedChar != '.') {
            staged.add(
              GitFileChange(
                path: path,
                oldPath: origPath,
                status: _parseStatusCode(stagedChar),
                isStaged: true,
              ),
            );
          }

          if (unstagedChar != '.') {
            unstaged.add(
              GitFileChange(
                path: path,
                oldPath: origPath,
                status: _parseStatusCode(unstagedChar),
                isStaged: false,
              ),
            );
          }
        }
      } else if (line.startsWith('? ')) {
        // Untracked file
        final path = line.substring(2).trim();
        untracked.add(
          GitFileChange(
            path: path,
            status: GitFileStatus.untracked,
            isStaged: false,
          ),
        );
      } else if (line.startsWith('u ')) {
        // Unmerged / conflict
        final parts = line.split(' ');
        final path = parts.length >= 11
            ? parts.sublist(10).join(' ')
            : line.substring(2).trim();
        unstaged.add(
          GitFileChange(
            path: path,
            status: GitFileStatus.conflicted,
            isStaged: false,
          ),
        );
      }
    }

    return GitStatusResult(
      branchName: branch,
      upstream: upstream,
      ahead: ahead,
      behind: behind,
      staged: staged,
      unstaged: unstaged,
      untracked: untracked,
    );
  }

  GitFileStatus _parseStatusCode(String char) {
    switch (char) {
      case 'M':
        return GitFileStatus.modified;
      case 'A':
        return GitFileStatus.added;
      case 'D':
        return GitFileStatus.deleted;
      case 'R':
        return GitFileStatus.renamed;
      case 'C':
        return GitFileStatus.copied;
      case 'T':
        return GitFileStatus.typeChange;
      case 'U':
        return GitFileStatus.conflicted;
      case '?':
        return GitFileStatus.untracked;
      default:
        return GitFileStatus.unknown;
    }
  }

  @override
  Future<List<GitCommit>> getHistory(
    String repoPath, {
    int limit = 100,
    int skip = 0,
    String? search,
  }) async {
    // Delimiter for parsing
    const delim = '---GITORA_COMMIT_DELIM---';
    final format = '%H%n%an%n%ae%n%at%n%P%n%B%n$delim';

    final args = ['log', '--format=$format', '-n', '$limit', '--skip', '$skip'];
    if (search != null && search.trim().isNotEmpty) {
      args.addAll(['--grep', search.trim(), '-i']);
    }

    final res = await _run(
      args,
      workingDirectory: repoPath,
      throwOnError: false,
    );
    if (res.exitCode != 0) {
      // Empty repo or no commits
      return [];
    }

    final raw = res.stdout.toString();
    final blocks = raw.split(delim);
    final commits = <GitCommit>[];

    for (final block in blocks) {
      final trimmed = block.trim();
      if (trimmed.isEmpty) continue;

      final lines = trimmed.split('\n');
      if (lines.length >= 5) {
        final hash = lines[0].trim();
        final author = lines[1].trim();
        final email = lines[2].trim();
        final timestamp = int.tryParse(lines[3].trim()) ?? 0;
        final parents = lines[4].trim().isEmpty
            ? <String>[]
            : lines[4].trim().split(' ');
        final message = lines.sublist(5).join('\n').trim();

        commits.add(
          GitCommit(
            hash: hash,
            authorName: author,
            authorEmail: email,
            date: DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
            parentHashes: parents,
            message: message,
          ),
        );
      }
    }

    return commits;
  }

  @override
  Future<List<GitFileChange>> getCommitFiles(
    String repoPath,
    String hash,
  ) async {
    final res = await _run(
      ['show', '--name-status', '--oneline', hash],
      workingDirectory: repoPath,
      throwOnError: false,
    );

    if (res.exitCode != 0) return [];

    final lines = res.stdout.toString().split('\n');
    final changes = <GitFileChange>[];

    // First line is commit subject
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = line.split('\t');
      if (parts.length >= 2) {
        final statusCode = parts[0][0];
        final path = parts[parts.length - 1];
        final oldPath = parts.length > 2 ? parts[1] : null;

        changes.add(
          GitFileChange(
            path: path,
            oldPath: oldPath,
            status: _parseStatusCode(statusCode),
            isStaged: false,
          ),
        );
      }
    }

    return changes;
  }

  @override
  Future<GitDiffModel> getDiff(
    String repoPath, {
    required String filePath,
    bool isStaged = false,
    String? commitHash,
  }) async {
    final args = ['diff'];
    if (commitHash != null) {
      args.addAll(['$commitHash~1', commitHash, '--', filePath]);
    } else if (isStaged) {
      args.addAll(['--cached', '--', filePath]);
    } else {
      args.addAll(['--', filePath]);
    }

    final res = await _run(
      args,
      workingDirectory: repoPath,
      throwOnError: false,
    );
    final raw = res.stdout.toString();

    // If diff is empty and it's an untracked or new file, let's read disk content directly
    if (raw.trim().isEmpty && commitHash == null && !isStaged) {
      final file = File('$repoPath/$filePath');
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          final lines = content.split('\n');
          final diffLines = <GitDiffLine>[];
          for (int i = 0; i < lines.length; i++) {
            diffLines.add(
              GitDiffLine(
                type: DiffLineType.addition,
                text: lines[i],
                newLineNumber: i + 1,
              ),
            );
          }

          final hunk = GitDiffHunk(
            header: '@@ -0,0 +1,${lines.length} @@',
            oldStart: 0,
            oldCount: 0,
            newStart: 1,
            newCount: lines.length,
            lines: diffLines,
          );

          return GitDiffModel(
            filePath: filePath,
            hunks: [hunk],
            rawDiff: content,
          );
        } catch (_) {
          return GitDiffModel.binary(filePath);
        }
      }
    }

    if (raw.contains('Binary files ') && raw.contains('differ')) {
      return GitDiffModel.binary(filePath);
    }

    return _parseDiffOutput(filePath, raw);
  }

  GitDiffModel _parseDiffOutput(String filePath, String raw) {
    final lines = raw.split('\n');
    final hunks = <GitDiffHunk>[];
    GitDiffHunk? currentHunk;
    List<GitDiffLine> currentHunkLines = [];
    String currentHeader = '';
    int oldLine = 0;
    int newLine = 0;
    int oldStart = 0;
    int oldCount = 0;
    int newStart = 0;
    int newCount = 0;

    final hunkHeaderRegex = RegExp(
      r'^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@(.*)$',
    );

    for (final line in lines) {
      final match = hunkHeaderRegex.firstMatch(line);
      if (match != null) {
        if (currentHunk != null) {
          hunks.add(
            GitDiffHunk(
              header: currentHeader,
              oldStart: oldStart,
              oldCount: oldCount,
              newStart: newStart,
              newCount: newCount,
              lines: currentHunkLines,
            ),
          );
        }

        currentHeader = line;
        currentHunkLines = [];
        oldStart = int.tryParse(match.group(1) ?? '1') ?? 1;
        oldCount = int.tryParse(match.group(2) ?? '1') ?? 1;
        newStart = int.tryParse(match.group(3) ?? '1') ?? 1;
        newCount = int.tryParse(match.group(4) ?? '1') ?? 1;
        oldLine = oldStart;
        newLine = newStart;
        currentHunk = GitDiffHunk(
          header: currentHeader,
          oldStart: oldStart,
          oldCount: oldCount,
          newStart: newStart,
          newCount: newCount,
          lines: currentHunkLines,
        );
      } else if (currentHunk != null) {
        if (line.startsWith('+')) {
          currentHunkLines.add(
            GitDiffLine(
              type: DiffLineType.addition,
              text: line.substring(1),
              newLineNumber: newLine++,
            ),
          );
        } else if (line.startsWith('-')) {
          currentHunkLines.add(
            GitDiffLine(
              type: DiffLineType.deletion,
              text: line.substring(1),
              oldLineNumber: oldLine++,
            ),
          );
        } else if (line.startsWith(' ')) {
          currentHunkLines.add(
            GitDiffLine(
              type: DiffLineType.context,
              text: line.substring(1),
              oldLineNumber: oldLine++,
              newLineNumber: newLine++,
            ),
          );
        }
      }
    }

    if (currentHunk != null && currentHunkLines.isNotEmpty) {
      hunks.add(
        GitDiffHunk(
          header: currentHeader,
          oldStart: oldStart,
          oldCount: oldCount,
          newStart: newStart,
          newCount: newCount,
          lines: currentHunkLines,
        ),
      );
    }

    return GitDiffModel(filePath: filePath, hunks: hunks, rawDiff: raw);
  }

  @override
  Future<void> stageFile(String repoPath, String filePath) async {
    await _run(['add', '--', filePath], workingDirectory: repoPath);
  }

  @override
  Future<void> unstageFile(String repoPath, String filePath) async {
    final res = await _run(
      ['restore', '--staged', '--', filePath],
      workingDirectory: repoPath,
      throwOnError: false,
    );
    if (res.exitCode != 0) {
      await _run(
        ['rm', '--cached', '-r', '--', filePath],
        workingDirectory: repoPath,
        throwOnError: false,
      );
    }
  }

  @override
  Future<void> stageAll(String repoPath) async {
    await _run(['add', '-A'], workingDirectory: repoPath);
  }

  @override
  Future<void> unstageAll(String repoPath) async {
    final res = await _run(
      ['restore', '--staged', '.'],
      workingDirectory: repoPath,
      throwOnError: false,
    );
    if (res.exitCode != 0) {
      await _run(
        ['rm', '--cached', '-r', '.'],
        workingDirectory: repoPath,
        throwOnError: false,
      );
    }
  }

  @override
  Future<void> discardFileChanges(String repoPath, String filePath) async {
    // Check if untracked
    final status = await getStatus(repoPath);
    final isUntracked = status.untracked.any((f) => f.path == filePath);

    if (isUntracked) {
      await _run(['clean', '-f', '--', filePath], workingDirectory: repoPath);
    } else {
      await _run(['restore', '--', filePath], workingDirectory: repoPath);
    }
  }

  @override
  Future<void> discardAllChanges(String repoPath) async {
    await _run(['restore', '.'], workingDirectory: repoPath);
    await _run(['clean', '-fd'], workingDirectory: repoPath);
  }

  @override
  Future<void> stageHunk(String repoPath, String patchContent) async {
    final process = await Process.start(_customGitPath, [
      '-c',
      'core.quotepath=false',
      'apply',
      '--cached',
      '--recount',
      '-',
    ], workingDirectory: repoPath);

    process.stdin.write(patchContent);
    await process.stdin.flush();
    await process.stdin.close();

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      final err = await process.stderr.transform(utf8.decoder).join();
      throw Exception('Failed to stage hunk: $err');
    }
  }

  @override
  Future<void> commit(
    String repoPath, {
    required String message,
    bool amend = false,
  }) async {
    final args = ['commit', '-m', message];
    if (amend) {
      args.add('--amend');
    }
    await _run(args, workingDirectory: repoPath);
  }

  @override
  Future<List<GitBranch>> getBranches(String repoPath) async {
    final res = await _run(
      ['branch', '-a', '-v', '--no-abbrev'],
      workingDirectory: repoPath,
      throwOnError: false,
    );

    if (res.exitCode != 0) return [];

    final lines = res.stdout.toString().split('\n');
    final branches = <GitBranch>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final isCurrent = line.startsWith('*');
      final cleanLine = line.replaceFirst('*', '').trim();
      final parts = cleanLine.split(RegExp(r'\s+'));

      if (parts.length >= 2) {
        String name = parts[0];
        if (name.contains('->')) {
          continue; // Skip symref like HEAD -> origin/main
        }

        final isRemote =
            name.startsWith('remotes/') || name.startsWith('origin/');
        if (name.startsWith('remotes/')) {
          name = name.substring('remotes/'.length);
        }

        final targetHash = parts[1];

        branches.add(
          GitBranch(
            name: name,
            isCurrent: isCurrent,
            isRemote: isRemote,
            targetHash: targetHash,
          ),
        );
      }
    }

    return branches;
  }

  @override
  Future<void> createBranch(
    String repoPath, {
    required String name,
    String? startPoint,
  }) async {
    final args = ['branch', name];
    if (startPoint != null && startPoint.isNotEmpty) {
      args.add(startPoint);
    }
    await _run(args, workingDirectory: repoPath);
  }

  @override
  Future<void> checkout(String repoPath, String ref) async {
    await _run(['checkout', ref], workingDirectory: repoPath);
  }

  @override
  Future<void> renameBranch(
    String repoPath, {
    required String oldName,
    required String newName,
  }) async {
    await _run(['branch', '-m', oldName, newName], workingDirectory: repoPath);
  }

  @override
  Future<void> deleteBranch(
    String repoPath,
    String name, {
    bool force = false,
  }) async {
    final flag = force ? '-D' : '-d';
    await _run(['branch', flag, name], workingDirectory: repoPath);
  }

  @override
  Future<void> merge(String repoPath, String sourceBranch) async {
    await _run(['merge', sourceBranch], workingDirectory: repoPath);
  }

  @override
  Future<void> rebase(String repoPath, String ontoBranch) async {
    await _run(['rebase', ontoBranch], workingDirectory: repoPath);
  }

  @override
  Future<void> cherryPick(String repoPath, String commitHash) async {
    await _run(['cherry-pick', commitHash], workingDirectory: repoPath);
  }

  @override
  Future<void> revert(String repoPath, String commitHash) async {
    await _run(['revert', '--no-edit', commitHash], workingDirectory: repoPath);
  }

  @override
  Future<void> setUpstream(
    String repoPath, {
    required String branch,
    required String upstream,
  }) async {
    await _run([
      'branch',
      '--set-upstream-to',
      upstream,
      branch,
    ], workingDirectory: repoPath);
  }

  @override
  Future<List<GitRemote>> getRemotes(String repoPath) async {
    final res = await _run(
      ['remote', '-v'],
      workingDirectory: repoPath,
      throwOnError: false,
    );
    if (res.exitCode != 0) return [];

    final lines = res.stdout.toString().split('\n');
    final map = <String, Map<String, String>>{};

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length >= 3) {
        final name = parts[0];
        final url = parts[1];
        final type = parts[2]; // (fetch) or (push)

        map.putIfAbsent(name, () => {});
        if (type.contains('fetch')) {
          map[name]!['fetch'] = url;
        } else if (type.contains('push')) {
          map[name]!['push'] = url;
        }
      }
    }

    return map.entries.map((e) {
      final fetch = e.value['fetch'] ?? '';
      final push = e.value['push'] ?? fetch;
      return GitRemote(name: e.key, fetchUrl: fetch, pushUrl: push);
    }).toList();
  }

  @override
  Future<void> addRemote(
    String repoPath, {
    required String name,
    required String url,
  }) async {
    await _run(['remote', 'add', name, url], workingDirectory: repoPath);
  }

  @override
  Future<void> removeRemote(String repoPath, String name) async {
    await _run(['remote', 'remove', name], workingDirectory: repoPath);
  }

  @override
  Future<void> fetch(String repoPath, {String? remote}) async {
    final args = ['fetch', '--all', '--prune'];
    if (remote != null) {
      args.replaceRange(1, 2, [remote]);
    }
    await _run(args, workingDirectory: repoPath);
  }

  @override
  Future<void> pull(String repoPath, {String? remote, String? branch}) async {
    final args = ['pull'];
    if (remote != null) {
      args.add(remote);
      if (branch != null) {
        args.add(branch);
      }
    }
    await _run(args, workingDirectory: repoPath);
  }

  @override
  Future<void> push(
    String repoPath, {
    String? remote,
    String? branch,
    bool force = false,
  }) async {
    final args = ['push'];
    if (force) {
      args.add('--force-with-lease');
    }
    if (remote != null) {
      args.add(remote);
      if (branch != null) {
        args.add(branch);
      }
    }
    await _run(args, workingDirectory: repoPath);
  }

  @override
  Future<List<GitStash>> getStashes(String repoPath) async {
    final res = await _run(
      ['stash', 'list'],
      workingDirectory: repoPath,
      throwOnError: false,
    );
    if (res.exitCode != 0) return [];

    final lines = res.stdout.toString().split('\n');
    final stashes = <GitStash>[];

    final regex = RegExp(
      r'^stash@\{(\d+)\}:\s*(?:(?:WIP on|On)\s+([^:]+):\s*)?(.*)$',
    );

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final match = regex.firstMatch(trimmed);
      if (match != null) {
        final index = int.tryParse(match.group(1) ?? '0') ?? 0;
        final branch = match.group(2)?.trim();
        final message = match.group(3)?.trim() ?? trimmed;

        stashes.add(
          GitStash(index: index, branchName: branch, message: message),
        );
      }
    }

    return stashes;
  }

  @override
  Future<void> createStash(
    String repoPath, {
    String? message,
    bool includeUntracked = false,
  }) async {
    final args = ['stash', 'push'];
    if (includeUntracked) {
      args.add('-u');
    }
    if (message != null && message.trim().isNotEmpty) {
      args.addAll(['-m', message.trim()]);
    }
    await _run(args, workingDirectory: repoPath);
  }

  @override
  Future<void> applyStash(String repoPath, int index) async {
    await _run([
      'stash',
      'apply',
      'stash@{$index}',
    ], workingDirectory: repoPath);
  }

  @override
  Future<void> popStash(String repoPath, int index) async {
    await _run(['stash', 'pop', 'stash@{$index}'], workingDirectory: repoPath);
  }

  @override
  Future<void> dropStash(String repoPath, int index) async {
    await _run(['stash', 'drop', 'stash@{$index}'], workingDirectory: repoPath);
  }
}
