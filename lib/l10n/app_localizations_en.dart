// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Gitora';

  @override
  String get appTagline => 'Powerful Git. Beautifully Simple.';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navChanges => 'Changes';

  @override
  String get navHistory => 'History';

  @override
  String get navBranches => 'Branches';

  @override
  String get navRemotes => 'Remotes';

  @override
  String get navStashes => 'Stashes';

  @override
  String get navSettings => 'Settings';

  @override
  String get openRepository => 'Open Repository';

  @override
  String get cloneRepository => 'Clone Repository';

  @override
  String get newRepository => 'New Repository';

  @override
  String get recentRepositories => 'Recent Repositories';

  @override
  String get favorites => 'Favorites';

  @override
  String get noRecentRepositories =>
      'No recent repositories yet. Open or clone a project to get started.';

  @override
  String get searchRepositories => 'Search repositories...';

  @override
  String get removeRecent => 'Remove from recent';

  @override
  String get markFavorite => 'Add to favorites';

  @override
  String get unmarkFavorite => 'Remove from favorites';

  @override
  String get openInExplorer => 'Open in File Explorer';

  @override
  String get openInTerminal => 'Open in Terminal';

  @override
  String get openInEditor => 'Open in Code Editor';

  @override
  String get workingTree => 'Working Tree';

  @override
  String get stagedChanges => 'Staged Changes';

  @override
  String get unstagedChanges => 'Unstaged Changes';

  @override
  String get stageAll => 'Stage All';

  @override
  String get unstageAll => 'Unstage All';

  @override
  String get discardAll => 'Discard All Changes';

  @override
  String get commit => 'Commit';

  @override
  String commitToBranch(String branch) {
    return 'Commit to $branch';
  }

  @override
  String get commitSummary => 'Commit summary';

  @override
  String get commitDescription => 'Extended description (optional)';

  @override
  String get amendLastCommit => 'Amend last commit';

  @override
  String get stageFile => 'Stage file';

  @override
  String get unstageFile => 'Unstage file';

  @override
  String get discardFile => 'Discard changes';

  @override
  String discardConfirmTitle(String file) {
    return 'Discard changes in $file?';
  }

  @override
  String get discardConfirmMessage =>
      'This action cannot be undone. All uncommitted modifications will be lost permanently.';

  @override
  String get discardAllConfirmTitle => 'Discard all unstaged changes?';

  @override
  String get discardAllConfirmMessage =>
      'Are you sure you want to discard all unstaged changes in the repository? This action is permanent and cannot be undone.';

  @override
  String get noChangesSelected => 'Select a file to inspect its diff';

  @override
  String get noChangesTitle => 'Working tree clean';

  @override
  String get noChangesSubtitle =>
      'There are no uncommitted changes in the repository.';

  @override
  String get binaryFileNotice =>
      'Binary file differs. Diff preview is not supported for binary assets.';

  @override
  String get unifiedDiff => 'Unified';

  @override
  String get sideBySideDiff => 'Side-by-Side';

  @override
  String get stageHunk => 'Stage Hunk';

  @override
  String get unstageHunk => 'Unstage Hunk';

  @override
  String get copyLine => 'Copy line';

  @override
  String get commitGraph => 'Commit Graph';

  @override
  String get searchCommits => 'Search commits by message, author or SHA...';

  @override
  String get noCommitsFound => 'No commits found matching query';

  @override
  String get commitDetails => 'Commit Details';

  @override
  String get author => 'Author';

  @override
  String get date => 'Date';

  @override
  String get sha => 'SHA';

  @override
  String get parents => 'Parents';

  @override
  String get changedFiles => 'Changed Files';

  @override
  String get copySha => 'Copy full SHA';

  @override
  String get checkoutCommit => 'Checkout this commit';

  @override
  String get cherryPickCommit => 'Cherry-pick commit';

  @override
  String get revertCommit => 'Revert commit';

  @override
  String get localBranches => 'Local Branches';

  @override
  String get remoteBranches => 'Remote Branches';

  @override
  String get tags => 'Tags';

  @override
  String get currentBranch => 'Current';

  @override
  String get createBranch => 'Create Branch';

  @override
  String get branchName => 'Branch name';

  @override
  String get checkout => 'Checkout';

  @override
  String get renameBranch => 'Rename Branch';

  @override
  String get deleteBranch => 'Delete Branch';

  @override
  String deleteBranchConfirm(String branch) {
    return 'Are you sure you want to delete branch \'$branch\'?';
  }

  @override
  String get cannotDeleteActiveBranch =>
      'You cannot delete the currently active branch. Switch to another branch first.';

  @override
  String mergeInto(String source, String target) {
    return 'Merge \'$source\' into \'$target\'';
  }

  @override
  String rebaseOnto(String current, String onto) {
    return 'Rebase \'$current\' onto \'$onto\'';
  }

  @override
  String get setUpstream => 'Set Upstream';

  @override
  String get remotes => 'Remotes';

  @override
  String get addRemote => 'Add Remote';

  @override
  String get remoteName => 'Remote name (e.g., origin)';

  @override
  String get remoteUrl => 'Remote URL';

  @override
  String get fetch => 'Fetch';

  @override
  String get pull => 'Pull';

  @override
  String get push => 'Push';

  @override
  String get forcePush => 'Force Push';

  @override
  String get forcePushWarning =>
      'Force push can overwrite remote history and impact collaborators. Are you sure you want to force push?';

  @override
  String get syncStatus => 'Sync Status';

  @override
  String get upToDate => 'Up to date with remote';

  @override
  String aheadBy(int count) {
    return 'Ahead by $count commit(s)';
  }

  @override
  String behindBy(int count) {
    return 'Behind by $count commit(s)';
  }

  @override
  String get stashes => 'Stashes';

  @override
  String get createStash => 'Create Stash';

  @override
  String get stashMessage => 'Stash message (optional)';

  @override
  String get includeUntracked => 'Include untracked files';

  @override
  String get applyStash => 'Apply Stash';

  @override
  String get popStash => 'Pop Stash';

  @override
  String get dropStash => 'Drop Stash';

  @override
  String get dropStashConfirm =>
      'Are you sure you want to permanently delete this stash?';

  @override
  String get noStashes => 'No stashes saved yet.';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get systemTheme => 'System Default';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get accentColor => 'Accent Color';

  @override
  String get interfaceDensity => 'Interface Density';

  @override
  String get comfortable => 'Comfortable';

  @override
  String get compact => 'Compact';

  @override
  String get reduceMotion => 'Reduce Animations';

  @override
  String get gitConfiguration => 'Git Configuration';

  @override
  String get gitStatus => 'Git Status';

  @override
  String get gitInstalled => 'System Git Detected';

  @override
  String get gitNotInstalled => 'System Git Not Found';

  @override
  String gitVersion(String version) {
    return 'Git Version: $version';
  }

  @override
  String get gitPath => 'Git Executable Path';

  @override
  String get chooseCustomGitPath => 'Choose Custom Git Executable';

  @override
  String get gitUserName => 'Git User Name';

  @override
  String get gitUserEmail => 'Git User Email';

  @override
  String get saveConfig => 'Save Git Configuration';

  @override
  String get gitBackend => 'Git Backend Engine';

  @override
  String get backendAuto => 'Hybrid (LibGit2 + Git CLI)';

  @override
  String get backendLibGit2 => 'LibGit2 Only';

  @override
  String get backendCli => 'Git CLI Only';

  @override
  String get language => 'Language';

  @override
  String get about => 'About Gitora';

  @override
  String get version => 'Version';

  @override
  String get productIdentifier => 'Product Identifier: dev.skrinvex.gitora';

  @override
  String get commandPalette => 'Command Palette';

  @override
  String get commandPalettePlaceholder =>
      'Type a command or search action (Esc to close)...';

  @override
  String get noCommandsFound => 'No matching commands found';

  @override
  String get onboardingWelcome => 'Welcome to Gitora';

  @override
  String get onboardingStep1 => '1. Git Verification';

  @override
  String get onboardingStep2 => '2. User Identity';

  @override
  String get onboardingStep3 => '3. Appearance & Style';

  @override
  String get onboardingStep4 => '4. First Repository';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingFinish => 'Launch Gitora';

  @override
  String get onboardingGitReady =>
      'Git engine is ready to power your workflow.';

  @override
  String get onboardingGitInstallNote =>
      'Git was not found in standard system PATH. You can specify the git.exe path or download Git from git-scm.com.';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get discard => 'Discard';

  @override
  String get apply => 'Apply';

  @override
  String get close => 'Close';

  @override
  String get refresh => 'Refresh';

  @override
  String get success => 'Success';

  @override
  String get error => 'Error';

  @override
  String get loading => 'Loading...';
}
