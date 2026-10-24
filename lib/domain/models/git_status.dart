import 'package:gitora/domain/models/git_file_change.dart';

class GitStatusResult {
  final String branchName;
  final String? upstream;
  final int ahead;
  final int behind;
  final List<GitFileChange> staged;
  final List<GitFileChange> unstaged;
  final List<GitFileChange> untracked;

  const GitStatusResult({
    required this.branchName,
    this.upstream,
    this.ahead = 0,
    this.behind = 0,
    required this.staged,
    required this.unstaged,
    required this.untracked,
  });

  bool get isClean => staged.isEmpty && unstaged.isEmpty && untracked.isEmpty;
  int get totalChanges => staged.length + unstaged.length + untracked.length;
  bool get hasStaged => staged.isNotEmpty;
  bool get hasUnstaged => unstaged.isNotEmpty || untracked.isNotEmpty;

  static const GitStatusResult empty = GitStatusResult(
    branchName: 'HEAD (detached)',
    staged: [],
    unstaged: [],
    untracked: [],
  );
}
