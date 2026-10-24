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
          path == other.path;

  @override
  int get hashCode => path.hashCode;
}
