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
import 'package:gitora/infrastructure/git/git_cli_service.dart';
import 'package:gitora/infrastructure/git/libgit2_service.dart';

enum GitBackendMode { auto, libgit2Only, cliOnly }

class HybridGitService implements GitService {
  final GitCliService _cliService;
  final LibGit2Service _libGit2Service;
  GitBackendMode _mode = GitBackendMode.auto;

  HybridGitService({GitCliService? cliService, LibGit2Service? libGit2Service})
    : _cliService = cliService ?? GitCliService(),
      _libGit2Service = libGit2Service ?? LibGit2Service();

  void setMode(GitBackendMode mode) {
    _mode = mode;
  }

  void setCustomGitPath(String path) {
    _cliService.setCustomGitPath(path);
  }

  GitBackendMode get mode => _mode;
  GitCliService get cliService => _cliService;
  LibGit2Service get libGit2Service => _libGit2Service;

  @override
  Future<GitSystemInfo> checkSystemInfo() async {
    final cliInfo = await _cliService.checkSystemInfo();
    final libInfo = await _libGit2Service.checkSystemInfo();

    return GitSystemInfo(
      isCliInstalled: cliInfo.isCliInstalled,
      cliVersion: cliInfo.cliVersion,
      cliPath: cliInfo.cliPath,
      isLibGit2Available: libInfo.isLibGit2Available,
      libGit2Version: libInfo.libGit2Version,
    );
  }

  @override
  Future<GitUserConfig> getUserConfig() async {
    if (_mode == GitBackendMode.libgit2Only) {
      return await _libGit2Service.getUserConfig();
    }
    try {
      final config = await _cliService.getUserConfig();
      if (config.isConfigured) return config;
    } catch (_) {}
    return await _libGit2Service.getUserConfig();
  }

  @override
  Future<void> setUserConfig({
    required String name,
    required String email,
  }) async {
    if (_mode == GitBackendMode.libgit2Only) {
      await _libGit2Service.setUserConfig(name: name, email: email);
      return;
    }
    await _cliService.setUserConfig(name: name, email: email);
  }

  @override
  Future<bool> isGitRepository(String path) async {
    try {
      if (_mode == GitBackendMode.libgit2Only) {
        return await _libGit2Service.isGitRepository(path);
      }
      return await _cliService.isGitRepository(path);
    } catch (_) {
      return await _libGit2Service.isGitRepository(path);
    }
  }

  @override
  Future<void> initRepository(String path) async {
    if (_mode == GitBackendMode.libgit2Only) {
      await _libGit2Service.initRepository(path);
      return;
    }
    try {
      await _cliService.initRepository(path);
    } catch (_) {
      await _libGit2Service.initRepository(path);
    }
  }

  @override
  Future<void> cloneRepository({
    required String url,
    required String targetPath,
    void Function(String message)? onProgress,
  }) async {
    if (_mode == GitBackendMode.libgit2Only) {
      await _libGit2Service.cloneRepository(
        url: url,
        targetPath: targetPath,
        onProgress: onProgress,
      );
      return;
    }
    try {
      await _cliService.cloneRepository(
        url: url,
        targetPath: targetPath,
        onProgress: onProgress,
      );
    } catch (_) {
      await _libGit2Service.cloneRepository(
        url: url,
        targetPath: targetPath,
        onProgress: onProgress,
      );
    }
  }

  @override
  Future<GitStatusResult> getStatus(String repoPath) async {
    if (_mode == GitBackendMode.libgit2Only) {
      return await _libGit2Service.getStatus(repoPath);
    }
    try {
      return await _cliService.getStatus(repoPath);
    } catch (_) {
      return await _libGit2Service.getStatus(repoPath);
    }
  }

  @override
  Future<List<GitCommit>> getHistory(
    String repoPath, {
    int limit = 100,
    int skip = 0,
    String? search,
  }) async {
    if (_mode == GitBackendMode.libgit2Only) {
      return await _libGit2Service.getHistory(
        repoPath,
        limit: limit,
        skip: skip,
        search: search,
      );
    }
    try {
      return await _cliService.getHistory(
        repoPath,
        limit: limit,
        skip: skip,
        search: search,
      );
    } catch (_) {
      return await _libGit2Service.getHistory(
        repoPath,
        limit: limit,
        skip: skip,
        search: search,
      );
    }
  }

  @override
  Future<List<GitFileChange>> getCommitFiles(
    String repoPath,
    String hash,
  ) async {
    if (_mode == GitBackendMode.libgit2Only) {
      return await _libGit2Service.getCommitFiles(repoPath, hash);
    }
    try {
      return await _cliService.getCommitFiles(repoPath, hash);
    } catch (_) {
      return await _libGit2Service.getCommitFiles(repoPath, hash);
    }
  }

  @override
  Future<GitDiffModel> getDiff(
    String repoPath, {
    required String filePath,
    bool isStaged = false,
    String? commitHash,
  }) async {
    if (_mode == GitBackendMode.libgit2Only) {
      return await _libGit2Service.getDiff(
        repoPath,
        filePath: filePath,
        isStaged: isStaged,
        commitHash: commitHash,
      );
    }
    try {
      return await _cliService.getDiff(
        repoPath,
        filePath: filePath,
        isStaged: isStaged,
        commitHash: commitHash,
      );
    } catch (_) {
      return await _libGit2Service.getDiff(
        repoPath,
        filePath: filePath,
        isStaged: isStaged,
        commitHash: commitHash,
      );
    }
  }

  @override
  Future<void> stageFile(String repoPath, String filePath) async {
    if (_mode == GitBackendMode.libgit2Only) {
      await _libGit2Service.stageFile(repoPath, filePath);
      return;
    }
    try {
      await _cliService.stageFile(repoPath, filePath);
    } catch (_) {
      await _libGit2Service.stageFile(repoPath, filePath);
    }
  }

  @override
  Future<void> unstageFile(String repoPath, String filePath) async {
    if (_mode == GitBackendMode.libgit2Only) {
      await _libGit2Service.unstageFile(repoPath, filePath);
      return;
    }
    try {
      await _cliService.unstageFile(repoPath, filePath);
    } catch (_) {
      await _libGit2Service.unstageFile(repoPath, filePath);
    }
  }

  @override
  Future<void> stageAll(String repoPath) async {
    if (_mode == GitBackendMode.libgit2Only) {
      await _libGit2Service.stageAll(repoPath);
      return;
    }
    try {
      await _cliService.stageAll(repoPath);
    } catch (_) {
      await _libGit2Service.stageAll(repoPath);
    }
  }

  @override
  Future<void> unstageAll(String repoPath) async {
    if (_mode == GitBackendMode.libgit2Only) {
      await _libGit2Service.unstageAll(repoPath);
      return;
    }
    try {
      await _cliService.unstageAll(repoPath);
    } catch (_) {
      await _libGit2Service.unstageAll(repoPath);
    }
  }

  @override
  Future<void> discardFileChanges(String repoPath, String filePath) async {
    if (_mode == GitBackendMode.libgit2Only) {
      await _libGit2Service.discardFileChanges(repoPath, filePath);
      return;
    }
    try {
      await _cliService.discardFileChanges(repoPath, filePath);
    } catch (_) {
      await _libGit2Service.discardFileChanges(repoPath, filePath);
    }
  }

  @override
  Future<void> discardAllChanges(String repoPath) async {
    if (_mode == GitBackendMode.libgit2Only) {
      await _libGit2Service.discardAllChanges(repoPath);
      return;
    }
    try {
      await _cliService.discardAllChanges(repoPath);
    } catch (_) {
      await _libGit2Service.discardAllChanges(repoPath);
    }
  }

  @override
  Future<void> stageHunk(String repoPath, String patchContent) async {
    await _cliService.stageHunk(repoPath, patchContent);
  }

  @override
  Future<void> unstageHunk(String repoPath, String patchContent) async {
    await _cliService.unstageHunk(repoPath, patchContent);
  }

  @override
  Future<void> commit(
    String repoPath, {
    required String message,
    bool amend = false,
  }) async {
    if (_mode == GitBackendMode.libgit2Only) {
      await _libGit2Service.commit(repoPath, message: message, amend: amend);
      return;
    }
    try {
      await _cliService.commit(repoPath, message: message, amend: amend);
    } catch (_) {
      await _libGit2Service.commit(repoPath, message: message, amend: amend);
    }
  }

  @override
  Future<List<GitBranch>> getBranches(String repoPath) async {
    if (_mode == GitBackendMode.libgit2Only) {
      return await _libGit2Service.getBranches(repoPath);
    }
    try {
      return await _cliService.getBranches(repoPath);
    } catch (_) {
      return await _libGit2Service.getBranches(repoPath);
    }
  }

  @override
  Future<void> createBranch(
    String repoPath, {
    required String name,
    String? startPoint,
  }) async {
    if (_mode == GitBackendMode.libgit2Only) {
      await _libGit2Service.createBranch(
        repoPath,
        name: name,
        startPoint: startPoint,
      );
      return;
    }
    try {
      await _cliService.createBranch(
        repoPath,
        name: name,
        startPoint: startPoint,
      );
    } catch (_) {
      await _libGit2Service.createBranch(
        repoPath,
        name: name,
        startPoint: startPoint,
      );
    }
  }

  @override
  Future<void> checkout(String repoPath, String ref) async {
    if (_mode == GitBackendMode.libgit2Only) {
      await _libGit2Service.checkout(repoPath, ref);
      return;
    }
    try {
      await _cliService.checkout(repoPath, ref);
    } catch (_) {
      await _libGit2Service.checkout(repoPath, ref);
    }
  }

  @override
  Future<void> renameBranch(
    String repoPath, {
    required String oldName,
    required String newName,
  }) async {
    if (_mode == GitBackendMode.libgit2Only) {
      await _libGit2Service.renameBranch(
        repoPath,
        oldName: oldName,
        newName: newName,
      );
      return;
    }
    try {
      await _cliService.renameBranch(
        repoPath,
        oldName: oldName,
        newName: newName,
      );
    } catch (_) {
      await _libGit2Service.renameBranch(
        repoPath,
        oldName: oldName,
        newName: newName,
      );
    }
  }

  @override
  Future<void> deleteBranch(
    String repoPath,
    String name, {
    bool force = false,
  }) async {
    if (_mode == GitBackendMode.libgit2Only) {
      await _libGit2Service.deleteBranch(repoPath, name, force: force);
      return;
    }
    try {
      await _cliService.deleteBranch(repoPath, name, force: force);
    } catch (_) {
      await _libGit2Service.deleteBranch(repoPath, name, force: force);
    }
  }

  @override
  Future<void> merge(String repoPath, String sourceBranch) async {
    await _cliService.merge(repoPath, sourceBranch);
  }

  @override
  Future<void> rebase(String repoPath, String ontoBranch) async {
    await _cliService.rebase(repoPath, ontoBranch);
  }

  @override
  Future<void> cherryPick(String repoPath, String commitHash) async {
    await _cliService.cherryPick(repoPath, commitHash);
  }

  @override
  Future<void> revert(String repoPath, String commitHash) async {
    await _cliService.revert(repoPath, commitHash);
  }

  @override
  Future<void> setUpstream(
    String repoPath, {
    required String branch,
    required String upstream,
  }) async {
    if (_mode == GitBackendMode.libgit2Only) {
      await _libGit2Service.setUpstream(
        repoPath,
        branch: branch,
        upstream: upstream,
      );
      return;
    }
    try {
      await _cliService.setUpstream(
        repoPath,
        branch: branch,
        upstream: upstream,
      );
    } catch (_) {
      await _libGit2Service.setUpstream(
        repoPath,
        branch: branch,
        upstream: upstream,
      );
    }
  }

  @override
  Future<List<GitRemote>> getRemotes(String repoPath) async {
    if (_mode == GitBackendMode.libgit2Only) {
      return await _libGit2Service.getRemotes(repoPath);
    }
    try {
      return await _cliService.getRemotes(repoPath);
    } catch (_) {
      return await _libGit2Service.getRemotes(repoPath);
    }
  }

  @override
  Future<void> addRemote(
    String repoPath, {
    required String name,
    required String url,
  }) async {
    if (_mode == GitBackendMode.libgit2Only) {
      await _libGit2Service.addRemote(repoPath, name: name, url: url);
      return;
    }
    try {
      await _cliService.addRemote(repoPath, name: name, url: url);
    } catch (_) {
      await _libGit2Service.addRemote(repoPath, name: name, url: url);
    }
  }

  @override
  Future<void> removeRemote(String repoPath, String name) async {
    if (_mode == GitBackendMode.libgit2Only) {
      await _libGit2Service.removeRemote(repoPath, name);
      return;
    }
    try {
      await _cliService.removeRemote(repoPath, name);
    } catch (_) {
      await _libGit2Service.removeRemote(repoPath, name);
    }
  }

  @override
  Future<void> fetch(
    String repoPath, {
    String? remote,
    void Function(String message, [double? percent])? onProgress,
  }) async {
    await _cliService.fetch(repoPath, remote: remote, onProgress: onProgress);
  }

  @override
  Future<void> pull(
    String repoPath, {
    String? remote,
    String? branch,
    void Function(String message, [double? percent])? onProgress,
  }) async {
    await _cliService.pull(
      repoPath,
      remote: remote,
      branch: branch,
      onProgress: onProgress,
    );
  }

  @override
  Future<void> push(
    String repoPath, {
    String? remote,
    String? branch,
    bool force = false,
    bool setUpstream = false,
    void Function(String message, [double? percent])? onProgress,
  }) async {
    await _cliService.push(
      repoPath,
      remote: remote,
      branch: branch,
      force: force,
      setUpstream: setUpstream,
      onProgress: onProgress,
    );
  }

  @override
  Future<List<GitStash>> getStashes(String repoPath) async {
    if (_mode == GitBackendMode.libgit2Only) {
      return await _libGit2Service.getStashes(repoPath);
    }
    try {
      return await _cliService.getStashes(repoPath);
    } catch (_) {
      return await _libGit2Service.getStashes(repoPath);
    }
  }

  @override
  Future<void> createStash(
    String repoPath, {
    String? message,
    bool includeUntracked = false,
  }) async {
    if (_mode == GitBackendMode.libgit2Only) {
      await _libGit2Service.createStash(
        repoPath,
        message: message,
        includeUntracked: includeUntracked,
      );
      return;
    }
    try {
      await _cliService.createStash(
        repoPath,
        message: message,
        includeUntracked: includeUntracked,
      );
    } catch (_) {
      await _libGit2Service.createStash(
        repoPath,
        message: message,
        includeUntracked: includeUntracked,
      );
    }
  }

  @override
  Future<void> applyStash(String repoPath, int index) async {
    if (_mode == GitBackendMode.libgit2Only) {
      await _libGit2Service.applyStash(repoPath, index);
      return;
    }
    try {
      await _cliService.applyStash(repoPath, index);
    } catch (_) {
      await _libGit2Service.applyStash(repoPath, index);
    }
  }

  @override
  Future<void> popStash(String repoPath, int index) async {
    if (_mode == GitBackendMode.libgit2Only) {
      await _libGit2Service.popStash(repoPath, index);
      return;
    }
    try {
      await _cliService.popStash(repoPath, index);
    } catch (_) {
      await _libGit2Service.popStash(repoPath, index);
    }
  }

  @override
  Future<void> dropStash(String repoPath, int index) async {
    if (_mode == GitBackendMode.libgit2Only) {
      await _libGit2Service.dropStash(repoPath, index);
      return;
    }
    try {
      await _cliService.dropStash(repoPath, index);
    } catch (_) {
      await _libGit2Service.dropStash(repoPath, index);
    }
  }
}
