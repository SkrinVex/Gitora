enum DiffLineType { context, addition, deletion, header }

class GitDiffLine {
  final DiffLineType type;
  final String text;
  final int? oldLineNumber;
  final int? newLineNumber;

  const GitDiffLine({
    required this.type,
    required this.text,
    this.oldLineNumber,
    this.newLineNumber,
  });

  bool get isAddition => type == DiffLineType.addition;
  bool get isDeletion => type == DiffLineType.deletion;
  bool get isContext => type == DiffLineType.context;
  bool get isHeader => type == DiffLineType.header;
}

class GitDiffHunk {
  final String header;
  final int oldStart;
  final int oldCount;
  final int newStart;
  final int newCount;
  final List<GitDiffLine> lines;

  const GitDiffHunk({
    required this.header,
    required this.oldStart,
    required this.oldCount,
    required this.newStart,
    required this.newCount,
    required this.lines,
  });

  /// Formats the hunk into a standard Git patch string for git apply / staging
  String toPatchString(String filePath) {
    final buffer = StringBuffer();
    final normalizedPath = filePath.replaceAll('\\', '/');

    buffer.write('diff --git a/$normalizedPath b/$normalizedPath\n');
    if (oldStart == 0 && oldCount == 0) {
      buffer.write('new file mode 100644\n');
      buffer.write('--- /dev/null\n');
      buffer.write('+++ b/$normalizedPath\n');
    } else {
      buffer.write('--- a/$normalizedPath\n');
      buffer.write('+++ b/$normalizedPath\n');
    }

    final cleanHeader = header.trimRight();
    buffer.write('$cleanHeader\n');

    for (final line in lines) {
      final cleanText = line.text.replaceAll('\r', '');
      if (line.type == DiffLineType.addition) {
        buffer.write('+$cleanText\n');
      } else if (line.type == DiffLineType.deletion) {
        buffer.write('-$cleanText\n');
      } else if (line.type == DiffLineType.context) {
        buffer.write(' $cleanText\n');
      }
    }
    return buffer.toString();
  }
}

class GitDiffModel {
  final String filePath;
  final String? oldFilePath;
  final bool isBinary;
  final List<GitDiffHunk> hunks;
  final String rawDiff;

  const GitDiffModel({
    required this.filePath,
    this.oldFilePath,
    this.isBinary = false,
    required this.hunks,
    required this.rawDiff,
  });

  int get additions {
    int count = 0;
    for (final hunk in hunks) {
      for (final line in hunk.lines) {
        if (line.isAddition) count++;
      }
    }
    return count;
  }

  int get deletions {
    int count = 0;
    for (final hunk in hunks) {
      for (final line in hunk.lines) {
        if (line.isDeletion) count++;
      }
    }
    return count;
  }

  bool get isEmpty => hunks.isEmpty && !isBinary;

  static GitDiffModel empty(String filePath) {
    return GitDiffModel(
      filePath: filePath,
      isBinary: false,
      hunks: const [],
      rawDiff: '',
    );
  }

  static GitDiffModel binary(String filePath) {
    return GitDiffModel(
      filePath: filePath,
      isBinary: true,
      hunks: const [],
      rawDiff: 'Binary file differences',
    );
  }
}
