class GitStash {
  final int index;
  final String message;
  final String? branchName;
  final DateTime? date;
  final String? hash;

  const GitStash({
    required this.index,
    required this.message,
    this.branchName,
    this.date,
    this.hash,
  });

  String get refName => 'stash@{$index}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GitStash &&
          runtimeType == other.runtimeType &&
          index == other.index;

  @override
  int get hashCode => index.hashCode;
}
