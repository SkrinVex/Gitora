class GitUserConfig {
  final String name;
  final String email;

  const GitUserConfig({required this.name, required this.email});

  bool get isConfigured => name.isNotEmpty && email.isNotEmpty;

  static const GitUserConfig empty = GitUserConfig(name: '', email: '');
}
