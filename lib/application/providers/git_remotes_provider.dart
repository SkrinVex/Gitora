import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitora/application/providers/current_repo_provider.dart';
import 'package:gitora/application/providers/git_service_provider.dart';
import 'package:gitora/application/providers/repository_state_provider.dart';
import 'package:gitora/domain/models/git_remote.dart';

final gitRemotesProvider = FutureProvider<List<GitRemote>>((ref) async {
  final repoPath = ref.watch(currentRepoProvider);
  ref.watch(
    repositoryStateProvider.select((s) => '${s.branchName}@${s.upstream}'),
  );

  if (repoPath == null || repoPath.isEmpty) return [];

  final gitService = ref.watch(gitServiceProvider);
  final isRepo = await gitService.isGitRepository(repoPath);
  if (!isRepo) return [];

  return await gitService.getRemotes(repoPath);
});
