import 'package:gitora/domain/models/git_file_change.dart';

class GitStatusResult {
  final String branchName;
  final String? upstream;
  final int ahead;
  final int behind;
  final List<GitFileChange> staged;
  final List<GitFileChange> unstaged;
  final List<GitFileChange> untracked;
  final List<GitFileChange> conflicted;
  final bool isMerging;
  final bool isRebasing;
  final String? headCommit;

  const GitStatusResult({
    required this.branchName,
    this.upstream,
    this.ahead = 0,
    this.behind = 0,
    required this.staged,
    required this.unstaged,
    required this.untracked,
    this.conflicted = const [],
    this.isMerging = false,
    this.isRebasing = false,
    this.headCommit,
  });

  bool get isClean =>
      staged.isEmpty &&
      unstaged.isEmpty &&
      untracked.isEmpty &&
      conflicted.isEmpty;

  /// Total count of unique modified file paths across staged, unstaged, untracked, and conflicted files.
  /// Prevents double-counting files that have changes both in index and worktree.
  int get totalChanges {
    final paths = <String>{
      for (final f in staged) f.path,
      for (final f in unstaged) f.path,
      for (final f in untracked) f.path,
      for (final f in conflicted) f.path,
    };
    return paths.length;
  }

  bool get hasStaged => staged.isNotEmpty;
  bool get hasUnstaged =>
      unstaged.isNotEmpty || untracked.isNotEmpty || conflicted.isNotEmpty;

  static const GitStatusResult empty = GitStatusResult(
    branchName: 'HEAD (detached)',
    staged: [],
    unstaged: [],
    untracked: [],
    conflicted: [],
    isMerging: false,
    isRebasing: false,
  );
}
