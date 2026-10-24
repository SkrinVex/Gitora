class GitBranch {
  final String name;
  final bool isCurrent;
  final bool isRemote;
  final String? upstream;
  final String targetHash;

  const GitBranch({
    required this.name,
    required this.isCurrent,
    required this.isRemote,
    this.upstream,
    required this.targetHash,
  });

  String get displayName {
    if (isRemote && name.startsWith('origin/')) {
      return name.substring('origin/'.length);
    }
    return name;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GitBranch &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          isRemote == other.isRemote;

  @override
  int get hashCode => Object.hash(name, isRemote);
}
