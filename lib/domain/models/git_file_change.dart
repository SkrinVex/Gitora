enum GitFileStatus {
  untracked,
  added,
  modified,
  deleted,
  renamed,
  copied,
  typeChange,
  conflicted,
  unknown,
}

class GitFileChange {
  final String path;
  final String? oldPath;
  final GitFileStatus status;
  final bool isStaged;

  const GitFileChange({
    required this.path,
    this.oldPath,
    required this.status,
    required this.isStaged,
  });

  String get fileName {
    final normalized = path.replaceAll('\\', '/');
    final segments = normalized.split('/');
    return segments.isNotEmpty ? segments.last : path;
  }

  String get directory {
    final normalized = path.replaceAll('\\', '/');
    final lastSlash = normalized.lastIndexOf('/');
    if (lastSlash > 0) {
      return normalized.substring(0, lastSlash);
    }
    return '';
  }

  String get statusLetter {
    switch (status) {
      case GitFileStatus.added:
        return 'A';
      case GitFileStatus.modified:
        return 'M';
      case GitFileStatus.deleted:
        return 'D';
      case GitFileStatus.renamed:
        return 'R';
      case GitFileStatus.untracked:
        return 'U';
      case GitFileStatus.conflicted:
        return 'C';
      case GitFileStatus.copied:
        return 'C';
      case GitFileStatus.typeChange:
        return 'T';
      case GitFileStatus.unknown:
        return '?';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GitFileChange &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          isStaged == other.isStaged &&
          status == other.status;

  @override
  int get hashCode => Object.hash(path, isStaged, status);
}
