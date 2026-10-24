class GitCommit {
  final String hash;
  final String authorName;
  final String authorEmail;
  final DateTime date;
  final String message;
  final List<String> parentHashes;
  int lane; // For visual Git Graph rendering

  GitCommit({
    required this.hash,
    required this.authorName,
    required this.authorEmail,
    required this.date,
    required this.message,
    required this.parentHashes,
    this.lane = 0,
  });

  String get shortHash => hash.length > 7 ? hash.substring(0, 7) : hash;

  String get summary {
    final lines = message.trim().split('\n');
    return lines.isNotEmpty ? lines.first : '';
  }

  String get description {
    final lines = message.trim().split('\n');
    if (lines.length > 1) {
      return lines.sublist(1).join('\n').trim();
    }
    return '';
  }

  bool get isMerge => parentHashes.length > 1;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GitCommit &&
          runtimeType == other.runtimeType &&
          hash == other.hash;

  @override
  int get hashCode => hash.hashCode;
}
