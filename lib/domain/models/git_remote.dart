class GitRemote {
  final String name;
  final String fetchUrl;
  final String pushUrl;

  const GitRemote({
    required this.name,
    required this.fetchUrl,
    required this.pushUrl,
  });

  bool get isSSH =>
      fetchUrl.startsWith('git@') || fetchUrl.startsWith('ssh://');
  bool get isHTTPS =>
      fetchUrl.startsWith('http://') || fetchUrl.startsWith('https://');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GitRemote &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}
