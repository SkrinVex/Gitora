import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitora/application/providers/current_repo_provider.dart';
import 'package:gitora/application/providers/git_service_provider.dart';
import 'package:gitora/domain/models/git_branch.dart';

final gitBranchesProvider = FutureProvider<List<GitBranch>>((ref) async {
  final repoPath = ref.watch(currentRepoProvider);
  ref.watch(repoStatusRefreshTriggerProvider);

  if (repoPath == null || repoPath.isEmpty) return [];

  final gitService = ref.watch(gitServiceProvider);
  final isRepo = await gitService.isGitRepository(repoPath);
  if (!isRepo) return [];

  return await gitService.getBranches(repoPath);
});
