import 'dart:io';

class RepositoryItem {
  final String path;
  final String name;
  final DateTime lastOpened;
  final bool isFavorite;

  const RepositoryItem({
    required this.path,
    required this.name,
    required this.lastOpened,
    this.isFavorite = false,
  });

  /// Check if the directory actually exists on disk.
  bool get exists => Directory(path).existsSync();

  /// Canonicalizes path to ensure stable identifier across Windows and Linux.
  static String normalizePath(String rawPath) {
    var p = rawPath.trim().replaceAll('\\', '/');
    while (p.endsWith('/') && p.length > 3) {
      p = p.substring(0, p.length - 1);
    }
    if (Platform.isWindows && p.length >= 2 && p[1] == ':') {
      p = p[0].toUpperCase() + p.substring(1);
    }
    return p;
  }

  RepositoryItem copyWith({
    String? path,
    String? name,
    DateTime? lastOpened,
    bool? isFavorite,
  }) {
    return RepositoryItem(
      path: path ?? this.path,
      name: name ?? this.name,
      lastOpened: lastOpened ?? this.lastOpened,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'name': name,
      'lastOpened': lastOpened.millisecondsSinceEpoch,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  factory RepositoryItem.fromMap(Map<String, dynamic> map) {
    return RepositoryItem(
      path: map['path'] as String,
      name: map['name'] as String,
      lastOpened: DateTime.fromMillisecondsSinceEpoch(map['lastOpened'] as int),
      isFavorite: (map['isFavorite'] as int? ?? 0) == 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepositoryItem &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          isFavorite == other.isFavorite &&
          lastOpened == other.lastOpened;

  @override
  int get hashCode => Object.hash(path, isFavorite, lastOpened);
}
