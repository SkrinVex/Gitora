import 'package:gitora/domain/models/git_branch.dart';
import 'package:gitora/domain/models/git_commit.dart';
import 'package:gitora/domain/models/git_diff.dart';
import 'package:gitora/domain/models/git_file_change.dart';
import 'package:gitora/domain/models/git_remote.dart';
import 'package:gitora/domain/models/git_stash.dart';
import 'package:gitora/domain/models/git_status.dart';
import 'package:gitora/domain/models/git_system_info.dart';
import 'package:gitora/domain/models/git_user_config.dart';

abstract class GitService {
  Future<GitSystemInfo> checkSystemInfo();
  Future<GitUserConfig> getUserConfig();
  Future<void> setUserConfig({required String name, required String email});

  Future<bool> isGitRepository(String path);
  Future<void> initRepository(String path);
  Future<void> cloneRepository({
    required String url,
    required String targetPath,
    void Function(String message)? onProgress,
  });

  Future<GitStatusResult> getStatus(String repoPath);
  Future<List<GitCommit>> getHistory(
    String repoPath, {
    int limit = 100,
    int skip = 0,
    String? search,
  });
  Future<List<GitFileChange>> getCommitFiles(String repoPath, String hash);
  Future<GitDiffModel> getDiff(
    String repoPath, {
    required String filePath,
    bool isStaged = false,
    String? commitHash,
  });

  Future<void> stageFile(String repoPath, String filePath);
  Future<void> unstageFile(String repoPath, String filePath);
  Future<void> stageAll(String repoPath);
  Future<void> unstageAll(String repoPath);
  Future<void> discardFileChanges(String repoPath, String filePath);
  Future<void> discardAllChanges(String repoPath);
  Future<void> stageHunk(String repoPath, String patchContent);

  Future<void> commit(
    String repoPath, {
    required String message,
    bool amend = false,
  });

  Future<List<GitBranch>> getBranches(String repoPath);
  Future<void> createBranch(
    String repoPath, {
    required String name,
    String? startPoint,
  });
  Future<void> checkout(String repoPath, String ref);
  Future<void> renameBranch(
    String repoPath, {
    required String oldName,
    required String newName,
  });
  Future<void> deleteBranch(String repoPath, String name, {bool force = false});
  Future<void> merge(String repoPath, String sourceBranch);
  Future<void> rebase(String repoPath, String ontoBranch);
  Future<void> cherryPick(String repoPath, String commitHash);
  Future<void> revert(String repoPath, String commitHash);
  Future<void> setUpstream(
    String repoPath, {
    required String branch,
    required String upstream,
  });

  Future<List<GitRemote>> getRemotes(String repoPath);
  Future<void> addRemote(
    String repoPath, {
    required String name,
    required String url,
  });
  Future<void> removeRemote(String repoPath, String name);
  Future<void> fetch(String repoPath, {String? remote});
  Future<void> pull(String repoPath, {String? remote, String? branch});
  Future<void> push(
    String repoPath, {
    String? remote,
    String? branch,
    bool force = false,
  });

  Future<List<GitStash>> getStashes(String repoPath);
  Future<void> createStash(
    String repoPath, {
    String? message,
    bool includeUntracked = false,
  });
  Future<void> applyStash(String repoPath, int index);
  Future<void> popStash(String repoPath, int index);
  Future<void> dropStash(String repoPath, int index);
}
