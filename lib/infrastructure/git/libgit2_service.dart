import 'package:git2dart/git2dart.dart' as g2d;
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

class LibGit2Service implements GitService {
  @override
  Future<GitSystemInfo> checkSystemInfo() async {
    try {
      final version = g2d.Libgit2.version;
      return GitSystemInfo(
        isCliInstalled: false,
        cliVersion: '',
        cliPath: '',
        isLibGit2Available: true,
        libGit2Version: version,
      );
    } catch (_) {
      return GitSystemInfo.empty;
    }
  }

  @override
  Future<GitUserConfig> getUserConfig() async {
    try {
      final config = g2d.Config.global();
      final name = config['user.name'].value.toString();
      final email = config['user.email'].value.toString();
      return GitUserConfig(name: name, email: email);
    } catch (_) {
      return GitUserConfig.empty;
    }
  }

  @override
  Future<void> setUserConfig({
    required String name,
    required String email,
  }) async {
    final config = g2d.Config.global();
    config['user.name'] = name;
    config['user.email'] = email;
  }

  @override
  Future<bool> isGitRepository(String path) async {
    try {
      final repo = g2d.Repository.open(path);
      return repo.path.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> initRepository(String path) async {
    g2d.Repository.init(path: path);
  }

  @override
  Future<void> cloneRepository({
    required String url,
    required String targetPath,
    void Function(String message)? onProgress,
  }) async {
    g2d.Repository.clone(url: url, localPath: targetPath);
  }

  @override
  Future<GitStatusResult> getStatus(String repoPath) async {
    final repo = g2d.Repository.open(repoPath);
    String branchName = 'HEAD';
    try {
      branchName = repo.head.shorthand;
    } catch (_) {}

    final staged = <GitFileChange>[];
    final unstaged = <GitFileChange>[];
    final untracked = <GitFileChange>[];

    final statusEntries = repo.status;
    for (final entry in statusEntries.entries) {
      final path = entry.key;
      final flags = entry.value;

      if (flags.contains(g2d.GitStatus.indexNew)) {
        staged.add(
          GitFileChange(
            path: path,
            status: GitFileStatus.added,
            isStaged: true,
          ),
        );
      } else if (flags.contains(g2d.GitStatus.indexModified)) {
        staged.add(
          GitFileChange(
            path: path,
            status: GitFileStatus.modified,
            isStaged: true,
          ),
        );
      } else if (flags.contains(g2d.GitStatus.indexDeleted)) {
        staged.add(
          GitFileChange(
            path: path,
            status: GitFileStatus.deleted,
            isStaged: true,
          ),
        );
      } else if (flags.contains(g2d.GitStatus.indexRenamed)) {
        staged.add(
          GitFileChange(
            path: path,
            status: GitFileStatus.renamed,
            isStaged: true,
          ),
        );
      }

      if (flags.contains(g2d.GitStatus.wtModified)) {
        unstaged.add(
          GitFileChange(
            path: path,
            status: GitFileStatus.modified,
            isStaged: false,
          ),
        );
      } else if (flags.contains(g2d.GitStatus.wtDeleted)) {
        unstaged.add(
          GitFileChange(
            path: path,
            status: GitFileStatus.deleted,
            isStaged: false,
          ),
        );
      } else if (flags.contains(g2d.GitStatus.wtRenamed)) {
        unstaged.add(
          GitFileChange(
            path: path,
            status: GitFileStatus.renamed,
            isStaged: false,
          ),
        );
      } else if (flags.contains(g2d.GitStatus.wtNew)) {
        untracked.add(
          GitFileChange(
            path: path,
            status: GitFileStatus.untracked,
            isStaged: false,
          ),
        );
      }
    }

    return GitStatusResult(
      branchName: branchName,
      staged: staged,
      unstaged: unstaged,
      untracked: untracked,
    );
  }

  @override
  Future<List<GitCommit>> getHistory(
    String repoPath, {
    int limit = 100,
    int skip = 0,
    String? search,
  }) async {
    final repo = g2d.Repository.open(repoPath);
    final commits = <GitCommit>[];
    final walker = g2d.RevWalk(repo);
    try {
      walker.sorting({g2d.GitSort.time, g2d.GitSort.topological});
      walker.pushHead();

      int skipped = 0;
      final walkerList = walker.walk(limit: limit + skip);
      for (final commit in walkerList) {
        final message = commit.message;

        if (search != null && search.isNotEmpty) {
          final lower = search.toLowerCase();
          final matches =
              message.toLowerCase().contains(lower) ||
              commit.author.name.toLowerCase().contains(lower) ||
              commit.oid.sha.toLowerCase().startsWith(lower);
          if (!matches) {
            continue;
          }
        }

        if (skipped < skip) {
          skipped++;
          continue;
        }

        commits.add(
          GitCommit(
            hash: commit.oid.sha,
            authorName: commit.author.name,
            authorEmail: commit.author.email,
            date: DateTime.fromMillisecondsSinceEpoch(commit.time * 1000),
            message: message,
            parentHashes: commit.parents.map((p) => p.sha).toList(),
          ),
        );

        if (commits.length >= limit) break;
      }
    } catch (_) {
      // Empty repo or no commits
    }
    return commits;
  }

  @override
  Future<List<GitFileChange>> getCommitFiles(
    String repoPath,
    String hash,
  ) async {
    final repo = g2d.Repository.open(repoPath);
    final commit = g2d.Commit.lookup(
      repo: repo,
      oid: g2d.Oid.fromSHA(repo, hash),
    );
    final changes = <GitFileChange>[];
    try {
      final tree = commit.tree;
      g2d.Tree? parentTree;
      if (commit.parents.isNotEmpty) {
        final parentCommit = g2d.Commit.lookup(
          repo: repo,
          oid: commit.parents.first,
        );
        parentTree = parentCommit.tree;
      }

      final diff = g2d.Diff.treeToTree(
        repo: repo,
        oldTree: parentTree,
        newTree: tree,
      );
      for (final delta in diff.deltas) {
        changes.add(
          GitFileChange(
            path: delta.newFile.path,
            oldPath: delta.oldFile.path,
            status: _fromDeltaStatus(delta.status),
            isStaged: false,
          ),
        );
      }
    } catch (_) {}
    return changes;
  }

  GitFileStatus _fromDeltaStatus(g2d.GitDelta status) {
    switch (status) {
      case g2d.GitDelta.added:
        return GitFileStatus.added;
      case g2d.GitDelta.deleted:
        return GitFileStatus.deleted;
      case g2d.GitDelta.modified:
        return GitFileStatus.modified;
      case g2d.GitDelta.renamed:
        return GitFileStatus.renamed;
      case g2d.GitDelta.copied:
        return GitFileStatus.copied;
      case g2d.GitDelta.untracked:
        return GitFileStatus.untracked;
      case g2d.GitDelta.typechange:
        return GitFileStatus.typeChange;
      case g2d.GitDelta.conflicted:
        return GitFileStatus.conflicted;
      default:
        return GitFileStatus.unknown;
    }
  }

  @override
  Future<GitDiffModel> getDiff(
    String repoPath, {
    required String filePath,
    bool isStaged = false,
    String? commitHash,
  }) async {
    final repo = g2d.Repository.open(repoPath);
    try {
      g2d.Diff diff;
      if (commitHash != null) {
        final commit = g2d.Commit.lookup(
          repo: repo,
          oid: g2d.Oid.fromSHA(repo, commitHash),
        );
        final tree = commit.tree;
        g2d.Tree? parentTree;
        if (commit.parents.isNotEmpty) {
          final parentCommit = g2d.Commit.lookup(
            repo: repo,
            oid: commit.parents.first,
          );
          parentTree = parentCommit.tree;
        }
        diff = g2d.Diff.treeToTree(
          repo: repo,
          oldTree: parentTree,
          newTree: tree,
        );
      } else if (isStaged) {
        try {
          final headCommit = repo.head.target as g2d.Commit;
          diff = g2d.Diff.treeToIndex(
            repo: repo,
            tree: headCommit.tree,
            index: repo.index,
          );
        } catch (_) {
          diff = g2d.Diff.indexToWorkdir(repo: repo, index: repo.index);
        }
      } else {
        diff = g2d.Diff.indexToWorkdir(repo: repo, index: repo.index);
      }

      final raw = diff.patch;
      return _parseRawDiff(filePath, raw);
    } catch (_) {
      return GitDiffModel.empty(filePath);
    }
  }

  GitDiffModel _parseRawDiff(String filePath, String raw) {
    final lines = raw.split('\n');
    final hunks = <GitDiffHunk>[];
    GitDiffHunk? currentHunk;
    List<GitDiffLine> currentLines = [];
    int oldLine = 1;
    int newLine = 1;

    for (final line in lines) {
      if (line.startsWith('@@')) {
        if (currentHunk != null) {
          hunks.add(
            GitDiffHunk(
              header: currentHunk.header,
              oldStart: currentHunk.oldStart,
              oldCount: currentHunk.oldCount,
              newStart: currentHunk.newStart,
              newCount: currentHunk.newCount,
              lines: currentLines,
            ),
          );
        }
        currentLines = [];
        currentHunk = GitDiffHunk(
          header: line,
          oldStart: oldLine,
          oldCount: 0,
          newStart: newLine,
          newCount: 0,
          lines: currentLines,
        );
      } else if (currentHunk != null) {
        if (line.startsWith('+')) {
          currentLines.add(
            GitDiffLine(
              type: DiffLineType.addition,
              text: line.substring(1),
              newLineNumber: newLine++,
            ),
          );
        } else if (line.startsWith('-')) {
          currentLines.add(
            GitDiffLine(
              type: DiffLineType.deletion,
              text: line.substring(1),
              oldLineNumber: oldLine++,
            ),
          );
        } else if (line.startsWith(' ')) {
          currentLines.add(
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

    if (currentHunk != null && currentLines.isNotEmpty) {
      hunks.add(
        GitDiffHunk(
          header: currentHunk.header,
          oldStart: currentHunk.oldStart,
          oldCount: currentHunk.oldCount,
          newStart: currentHunk.newStart,
          newCount: currentHunk.newCount,
          lines: currentLines,
        ),
      );
    }

    return GitDiffModel(filePath: filePath, hunks: hunks, rawDiff: raw);
  }

  @override
  Future<void> stageFile(String repoPath, String filePath) async {
    final repo = g2d.Repository.open(repoPath);
    final index = repo.index;
    index.add(filePath);
    index.write();
  }

  @override
  Future<void> unstageFile(String repoPath, String filePath) async {
    final repo = g2d.Repository.open(repoPath);
    try {
      final headCommit = repo.head.target as g2d.Commit;
      repo.resetDefault(oid: headCommit.oid, pathspec: [filePath]);
    } catch (_) {
      final index = repo.index;
      index.remove(filePath);
      index.write();
    }
  }

  @override
  Future<void> stageAll(String repoPath) async {
    final repo = g2d.Repository.open(repoPath);
    final index = repo.index;
    index.addAll(['*']);
    index.write();
  }

  @override
  Future<void> unstageAll(String repoPath) async {
    final repo = g2d.Repository.open(repoPath);
    try {
      final headCommit = repo.head.target as g2d.Commit;
      repo.resetDefault(oid: headCommit.oid, pathspec: ['*']);
    } catch (_) {
      final index = repo.index;
      index.clear();
      index.write();
    }
  }

  @override
  Future<void> discardFileChanges(String repoPath, String filePath) async {
    final repo = g2d.Repository.open(repoPath);
    g2d.Checkout.head(
      repo: repo,
      paths: [filePath],
      strategy: {g2d.GitCheckout.force},
    );
  }

  @override
  Future<void> discardAllChanges(String repoPath) async {
    final repo = g2d.Repository.open(repoPath);
    g2d.Checkout.head(repo: repo, strategy: {g2d.GitCheckout.force});
  }

  @override
  Future<void> stageHunk(String repoPath, String patchContent) async {
    throw UnsupportedError('Interactive hunk staging requires Git CLI engine');
  }

  @override
  Future<void> commit(
    String repoPath, {
    required String message,
    bool amend = false,
  }) async {
    final repo = g2d.Repository.open(repoPath);
    String name = 'Gitora User';
    String email = 'user@gitora.dev';
    try {
      final config = g2d.Config.global();
      name = config['user.name'].value.toString();
      email = config['user.email'].value.toString();
    } catch (_) {}

    final signature = g2d.Signature.create(
      name: name,
      email: email,
      time: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      offset: DateTime.now().timeZoneOffset.inMinutes,
    );

    final index = repo.index;
    final treeOid = index.writeTree();
    final tree = g2d.Tree.lookup(repo: repo, oid: treeOid);

    List<g2d.Commit> parents = [];
    try {
      final headOid = repo.head.target;
      final headCommit = g2d.Commit.lookup(repo: repo, oid: headOid);
      if (amend) {
        parents = headCommit.parents
            .map((p) => g2d.Commit.lookup(repo: repo, oid: p))
            .toList();
      } else {
        parents = [headCommit];
      }
    } catch (_) {}

    if (amend) {
      final headOid = repo.head.target;
      final headCommit = g2d.Commit.lookup(repo: repo, oid: headOid);
      g2d.Commit.amend(
        repo: repo,
        commit: headCommit,
        updateRef: 'HEAD',
        author: signature,
        committer: signature,
        message: message,
        tree: tree,
      );
    } else {
      g2d.Commit.create(
        repo: repo,
        updateRef: 'HEAD',
        author: signature,
        committer: signature,
        message: message,
        tree: tree,
        parents: parents,
      );
    }
  }

  @override
  Future<List<GitBranch>> getBranches(String repoPath) async {
    final repo = g2d.Repository.open(repoPath);
    final branches = <GitBranch>[];
    final branchList = g2d.Branch.list(repo: repo, type: g2d.GitBranch.all);
    for (final branch in branchList) {
      final isRemote =
          branch.name.startsWith('origin/') ||
          branch.name.startsWith('remotes/');
      branches.add(
        GitBranch(
          name: branch.name,
          isCurrent: branch.isHead,
          isRemote: isRemote,
          targetHash: branch.target.sha,
        ),
      );
    }
    return branches;
  }

  @override
  Future<void> createBranch(
    String repoPath, {
    required String name,
    String? startPoint,
  }) async {
    final repo = g2d.Repository.open(repoPath);
    g2d.Commit targetCommit;
    if (startPoint != null && startPoint.isNotEmpty) {
      targetCommit = g2d.Commit.lookup(
        repo: repo,
        oid: g2d.Oid.fromSHA(repo, startPoint),
      );
    } else {
      targetCommit = g2d.Commit.lookup(repo: repo, oid: repo.head.target);
    }
    g2d.Branch.create(repo: repo, name: name, target: targetCommit);
  }

  @override
  Future<void> checkout(String repoPath, String ref) async {
    final repo = g2d.Repository.open(repoPath);
    try {
      g2d.Checkout.reference(repo: repo, name: 'refs/heads/$ref');
    } catch (_) {
      g2d.Checkout.head(repo: repo);
    }
  }

  @override
  Future<void> renameBranch(
    String repoPath, {
    required String oldName,
    required String newName,
  }) async {
    final repo = g2d.Repository.open(repoPath);
    g2d.Branch.rename(repo: repo, oldName: oldName, newName: newName);
  }

  @override
  Future<void> deleteBranch(
    String repoPath,
    String name, {
    bool force = false,
  }) async {
    final repo = g2d.Repository.open(repoPath);
    g2d.Branch.delete(repo: repo, name: name);
  }

  @override
  Future<void> merge(String repoPath, String sourceBranch) async {
    throw UnsupportedError('Full merge logic delegated to GitCliService');
  }

  @override
  Future<void> rebase(String repoPath, String ontoBranch) async {
    throw UnsupportedError('Interactive rebase delegated to GitCliService');
  }

  @override
  Future<void> cherryPick(String repoPath, String commitHash) async {
    throw UnsupportedError('Cherry-pick delegated to GitCliService');
  }

  @override
  Future<void> revert(String repoPath, String commitHash) async {
    throw UnsupportedError('Revert delegated to GitCliService');
  }

  @override
  Future<void> setUpstream(
    String repoPath, {
    required String branch,
    required String upstream,
  }) async {
    throw UnsupportedError('SetUpstream delegated to GitCliService');
  }

  @override
  Future<List<GitRemote>> getRemotes(String repoPath) async {
    final repo = g2d.Repository.open(repoPath);
    final remotes = <GitRemote>[];
    for (final remoteName in repo.remotes) {
      try {
        final r = g2d.Remote.lookup(repo: repo, name: remoteName);
        remotes.add(GitRemote(name: r.name, fetchUrl: r.url, pushUrl: r.url));
      } catch (_) {}
    }
    return remotes;
  }

  @override
  Future<void> addRemote(
    String repoPath, {
    required String name,
    required String url,
  }) async {
    final repo = g2d.Repository.open(repoPath);
    g2d.Remote.create(repo: repo, name: name, url: url);
  }

  @override
  Future<void> removeRemote(String repoPath, String name) async {
    final repo = g2d.Repository.open(repoPath);
    g2d.Remote.delete(repo: repo, name: name);
  }

  @override
  Future<void> fetch(String repoPath, {String? remote}) async {
    throw UnsupportedError(
      'Network fetch with authentication delegated to GitCliService',
    );
  }

  @override
  Future<void> pull(String repoPath, {String? remote, String? branch}) async {
    throw UnsupportedError(
      'Network pull with authentication delegated to GitCliService',
    );
  }

  @override
  Future<void> push(
    String repoPath, {
    String? remote,
    String? branch,
    bool force = false,
  }) async {
    throw UnsupportedError(
      'Network push with authentication delegated to GitCliService',
    );
  }

  @override
  Future<List<GitStash>> getStashes(String repoPath) async {
    final repo = g2d.Repository.open(repoPath);
    final list = g2d.Stash.list(repo);
    return list
        .map((s) => GitStash(index: s.index, message: s.message))
        .toList();
  }

  @override
  Future<void> createStash(
    String repoPath, {
    String? message,
    bool includeUntracked = false,
  }) async {
    final repo = g2d.Repository.open(repoPath);
    String name = 'Gitora User';
    String email = 'user@gitora.dev';
    try {
      final config = g2d.Config.global();
      name = config['user.name'].value.toString();
      email = config['user.email'].value.toString();
    } catch (_) {}

    final sig = g2d.Signature.create(
      name: name,
      email: email,
      time: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      offset: DateTime.now().timeZoneOffset.inMinutes,
    );

    g2d.Stash.create(
      repo: repo,
      stasher: sig,
      message: message,
      flags: includeUntracked
          ? {g2d.GitStash.includeUntracked}
          : {g2d.GitStash.defaults},
    );
  }

  @override
  Future<void> applyStash(String repoPath, int index) async {
    final repo = g2d.Repository.open(repoPath);
    g2d.Stash.apply(repo: repo, index: index);
  }

  @override
  Future<void> popStash(String repoPath, int index) async {
    final repo = g2d.Repository.open(repoPath);
    g2d.Stash.pop(repo: repo, index: index);
  }

  @override
  Future<void> dropStash(String repoPath, int index) async {
    final repo = g2d.Repository.open(repoPath);
    g2d.Stash.drop(repo: repo, index: index);
  }
}
