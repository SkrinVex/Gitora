import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitora/application/providers/current_repo_provider.dart';
import 'package:gitora/application/providers/git_service_provider.dart';
import 'package:gitora/domain/models/git_diff.dart';

class SelectedDiffTarget {
  final String filePath;
  final bool isStaged;
  final String? commitHash;

  const SelectedDiffTarget({
    required this.filePath,
    this.isStaged = false,
    this.commitHash,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectedDiffTarget &&
          runtimeType == other.runtimeType &&
          filePath == other.filePath &&
          isStaged == other.isStaged &&
          commitHash == other.commitHash;

  @override
  int get hashCode => Object.hash(filePath, isStaged, commitHash);
}

class SelectedDiffTargetNotifier extends Notifier<SelectedDiffTarget?> {
  @override
  SelectedDiffTarget? build() => null;

  @override
  set state(SelectedDiffTarget? value) => super.state = value;
  void select(SelectedDiffTarget? target) => state = target;
}

final selectedDiffTargetProvider =
    NotifierProvider<SelectedDiffTargetNotifier, SelectedDiffTarget?>(
      SelectedDiffTargetNotifier.new,
    );

final gitDiffProvider = FutureProvider<GitDiffModel?>((ref) async {
  final repoPath = ref.watch(currentRepoProvider);
  final target = ref.watch(selectedDiffTargetProvider);
  ref.watch(repoStatusRefreshTriggerProvider);

  if (repoPath == null || target == null) return null;

  final gitService = ref.watch(gitServiceProvider);
  return await gitService.getDiff(
    repoPath,
    filePath: target.filePath,
    isStaged: target.isStaged,
    commitHash: target.commitHash,
  );
});
