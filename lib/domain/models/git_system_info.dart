class GitSystemInfo {
  final bool isCliInstalled;
  final String cliVersion;
  final String cliPath;
  final bool isLibGit2Available;
  final String libGit2Version;

  const GitSystemInfo({
    required this.isCliInstalled,
    required this.cliVersion,
    required this.cliPath,
    required this.isLibGit2Available,
    required this.libGit2Version,
  });

  bool get isReady => isCliInstalled || isLibGit2Available;

  static const GitSystemInfo empty = GitSystemInfo(
    isCliInstalled: false,
    cliVersion: '',
    cliPath: '',
    isLibGit2Available: false,
    libGit2Version: '',
  );
}
