import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Gitora'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Powerful Git. Beautifully Simple.'**
  String get appTagline;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navChanges.
  ///
  /// In en, this message translates to:
  /// **'Changes'**
  String get navChanges;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navBranches.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get navBranches;

  /// No description provided for @navRemotes.
  ///
  /// In en, this message translates to:
  /// **'Remotes'**
  String get navRemotes;

  /// No description provided for @navStashes.
  ///
  /// In en, this message translates to:
  /// **'Stashes'**
  String get navStashes;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @openRepository.
  ///
  /// In en, this message translates to:
  /// **'Open Repository'**
  String get openRepository;

  /// No description provided for @cloneRepository.
  ///
  /// In en, this message translates to:
  /// **'Clone Repository'**
  String get cloneRepository;

  /// No description provided for @newRepository.
  ///
  /// In en, this message translates to:
  /// **'New Repository'**
  String get newRepository;

  /// No description provided for @recentRepositories.
  ///
  /// In en, this message translates to:
  /// **'Recent Repositories'**
  String get recentRepositories;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @noRecentRepositories.
  ///
  /// In en, this message translates to:
  /// **'No recent repositories yet. Open or clone a project to get started.'**
  String get noRecentRepositories;

  /// No description provided for @searchRepositories.
  ///
  /// In en, this message translates to:
  /// **'Search repositories...'**
  String get searchRepositories;

  /// No description provided for @removeRecent.
  ///
  /// In en, this message translates to:
  /// **'Remove from recent'**
  String get removeRecent;

  /// No description provided for @markFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get markFavorite;

  /// No description provided for @unmarkFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get unmarkFavorite;

  /// No description provided for @openInExplorer.
  ///
  /// In en, this message translates to:
  /// **'Open in File Explorer'**
  String get openInExplorer;

  /// No description provided for @openInTerminal.
  ///
  /// In en, this message translates to:
  /// **'Open in Terminal'**
  String get openInTerminal;

  /// No description provided for @openInEditor.
  ///
  /// In en, this message translates to:
  /// **'Open in Code Editor'**
  String get openInEditor;

  /// No description provided for @workingTree.
  ///
  /// In en, this message translates to:
  /// **'Working Tree'**
  String get workingTree;

  /// No description provided for @stagedChanges.
  ///
  /// In en, this message translates to:
  /// **'Staged Changes'**
  String get stagedChanges;

  /// No description provided for @unstagedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unstaged Changes'**
  String get unstagedChanges;

  /// No description provided for @stageAll.
  ///
  /// In en, this message translates to:
  /// **'Stage All'**
  String get stageAll;

  /// No description provided for @unstageAll.
  ///
  /// In en, this message translates to:
  /// **'Unstage All'**
  String get unstageAll;

  /// No description provided for @discardAll.
  ///
  /// In en, this message translates to:
  /// **'Discard All Changes'**
  String get discardAll;

  /// No description provided for @commit.
  ///
  /// In en, this message translates to:
  /// **'Commit'**
  String get commit;

  /// No description provided for @commitToBranch.
  ///
  /// In en, this message translates to:
  /// **'Commit to {branch}'**
  String commitToBranch(String branch);

  /// No description provided for @commitSummary.
  ///
  /// In en, this message translates to:
  /// **'Commit summary'**
  String get commitSummary;

  /// No description provided for @commitDescription.
  ///
  /// In en, this message translates to:
  /// **'Extended description (optional)'**
  String get commitDescription;

  /// No description provided for @amendLastCommit.
  ///
  /// In en, this message translates to:
  /// **'Amend last commit'**
  String get amendLastCommit;

  /// No description provided for @stageFile.
  ///
  /// In en, this message translates to:
  /// **'Stage file'**
  String get stageFile;

  /// No description provided for @unstageFile.
  ///
  /// In en, this message translates to:
  /// **'Unstage file'**
  String get unstageFile;

  /// No description provided for @discardFile.
  ///
  /// In en, this message translates to:
  /// **'Discard changes'**
  String get discardFile;

  /// No description provided for @discardConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes in {file}?'**
  String discardConfirmTitle(String file);

  /// No description provided for @discardConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All uncommitted modifications will be lost permanently.'**
  String get discardConfirmMessage;

  /// No description provided for @discardAllConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard all unstaged changes?'**
  String get discardAllConfirmTitle;

  /// No description provided for @discardAllConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to discard all unstaged changes in the repository? This action is permanent and cannot be undone.'**
  String get discardAllConfirmMessage;

  /// No description provided for @noChangesSelected.
  ///
  /// In en, this message translates to:
  /// **'Select a file to inspect its diff'**
  String get noChangesSelected;

  /// No description provided for @noChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Working tree clean'**
  String get noChangesTitle;

  /// No description provided for @noChangesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'There are no uncommitted changes in the repository.'**
  String get noChangesSubtitle;

  /// No description provided for @binaryFileNotice.
  ///
  /// In en, this message translates to:
  /// **'Binary file differs. Diff preview is not supported for binary assets.'**
  String get binaryFileNotice;

  /// No description provided for @unifiedDiff.
  ///
  /// In en, this message translates to:
  /// **'Unified'**
  String get unifiedDiff;

  /// No description provided for @sideBySideDiff.
  ///
  /// In en, this message translates to:
  /// **'Side-by-Side'**
  String get sideBySideDiff;

  /// No description provided for @stageHunk.
  ///
  /// In en, this message translates to:
  /// **'Stage Hunk'**
  String get stageHunk;

  /// No description provided for @unstageHunk.
  ///
  /// In en, this message translates to:
  /// **'Unstage Hunk'**
  String get unstageHunk;

  /// No description provided for @copyLine.
  ///
  /// In en, this message translates to:
  /// **'Copy line'**
  String get copyLine;

  /// No description provided for @commitGraph.
  ///
  /// In en, this message translates to:
  /// **'Commit Graph'**
  String get commitGraph;

  /// No description provided for @searchCommits.
  ///
  /// In en, this message translates to:
  /// **'Search commits by message, author or SHA...'**
  String get searchCommits;

  /// No description provided for @noCommitsFound.
  ///
  /// In en, this message translates to:
  /// **'No commits found matching query'**
  String get noCommitsFound;

  /// No description provided for @commitDetails.
  ///
  /// In en, this message translates to:
  /// **'Commit Details'**
  String get commitDetails;

  /// No description provided for @author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get author;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @sha.
  ///
  /// In en, this message translates to:
  /// **'SHA'**
  String get sha;

  /// No description provided for @parents.
  ///
  /// In en, this message translates to:
  /// **'Parents'**
  String get parents;

  /// No description provided for @changedFiles.
  ///
  /// In en, this message translates to:
  /// **'Changed Files'**
  String get changedFiles;

  /// No description provided for @copySha.
  ///
  /// In en, this message translates to:
  /// **'Copy full SHA'**
  String get copySha;

  /// No description provided for @checkoutCommit.
  ///
  /// In en, this message translates to:
  /// **'Checkout this commit'**
  String get checkoutCommit;

  /// No description provided for @cherryPickCommit.
  ///
  /// In en, this message translates to:
  /// **'Cherry-pick commit'**
  String get cherryPickCommit;

  /// No description provided for @revertCommit.
  ///
  /// In en, this message translates to:
  /// **'Revert commit'**
  String get revertCommit;

  /// No description provided for @localBranches.
  ///
  /// In en, this message translates to:
  /// **'Local Branches'**
  String get localBranches;

  /// No description provided for @remoteBranches.
  ///
  /// In en, this message translates to:
  /// **'Remote Branches'**
  String get remoteBranches;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @currentBranch.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentBranch;

  /// No description provided for @createBranch.
  ///
  /// In en, this message translates to:
  /// **'Create Branch'**
  String get createBranch;

  /// No description provided for @branchName.
  ///
  /// In en, this message translates to:
  /// **'Branch name'**
  String get branchName;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @renameBranch.
  ///
  /// In en, this message translates to:
  /// **'Rename Branch'**
  String get renameBranch;

  /// No description provided for @deleteBranch.
  ///
  /// In en, this message translates to:
  /// **'Delete Branch'**
  String get deleteBranch;

  /// No description provided for @deleteBranchConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete branch \'{branch}\'?'**
  String deleteBranchConfirm(String branch);

  /// No description provided for @cannotDeleteActiveBranch.
  ///
  /// In en, this message translates to:
  /// **'You cannot delete the currently active branch. Switch to another branch first.'**
  String get cannotDeleteActiveBranch;

  /// No description provided for @mergeInto.
  ///
  /// In en, this message translates to:
  /// **'Merge \'{source}\' into \'{target}\''**
  String mergeInto(String source, String target);

  /// No description provided for @rebaseOnto.
  ///
  /// In en, this message translates to:
  /// **'Rebase \'{current}\' onto \'{onto}\''**
  String rebaseOnto(String current, String onto);

  /// No description provided for @setUpstream.
  ///
  /// In en, this message translates to:
  /// **'Set Upstream'**
  String get setUpstream;

  /// No description provided for @remotes.
  ///
  /// In en, this message translates to:
  /// **'Remotes'**
  String get remotes;

  /// No description provided for @addRemote.
  ///
  /// In en, this message translates to:
  /// **'Add Remote'**
  String get addRemote;

  /// No description provided for @remoteName.
  ///
  /// In en, this message translates to:
  /// **'Remote name (e.g., origin)'**
  String get remoteName;

  /// No description provided for @remoteUrl.
  ///
  /// In en, this message translates to:
  /// **'Remote URL'**
  String get remoteUrl;

  /// No description provided for @fetch.
  ///
  /// In en, this message translates to:
  /// **'Fetch'**
  String get fetch;

  /// No description provided for @pull.
  ///
  /// In en, this message translates to:
  /// **'Pull'**
  String get pull;

  /// No description provided for @push.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get push;

  /// No description provided for @forcePush.
  ///
  /// In en, this message translates to:
  /// **'Force Push'**
  String get forcePush;

  /// No description provided for @forcePushWarning.
  ///
  /// In en, this message translates to:
  /// **'Force push can overwrite remote history and impact collaborators. Are you sure you want to force push?'**
  String get forcePushWarning;

  /// No description provided for @syncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync Status'**
  String get syncStatus;

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date with remote'**
  String get upToDate;

  /// No description provided for @aheadBy.
  ///
  /// In en, this message translates to:
  /// **'Ahead by {count} commit(s)'**
  String aheadBy(int count);

  /// No description provided for @behindBy.
  ///
  /// In en, this message translates to:
  /// **'Behind by {count} commit(s)'**
  String behindBy(int count);

  /// No description provided for @stashes.
  ///
  /// In en, this message translates to:
  /// **'Stashes'**
  String get stashes;

  /// No description provided for @createStash.
  ///
  /// In en, this message translates to:
  /// **'Create Stash'**
  String get createStash;

  /// No description provided for @stashMessage.
  ///
  /// In en, this message translates to:
  /// **'Stash message (optional)'**
  String get stashMessage;

  /// No description provided for @includeUntracked.
  ///
  /// In en, this message translates to:
  /// **'Include untracked files'**
  String get includeUntracked;

  /// No description provided for @applyStash.
  ///
  /// In en, this message translates to:
  /// **'Apply Stash'**
  String get applyStash;

  /// No description provided for @popStash.
  ///
  /// In en, this message translates to:
  /// **'Pop Stash'**
  String get popStash;

  /// No description provided for @dropStash.
  ///
  /// In en, this message translates to:
  /// **'Drop Stash'**
  String get dropStash;

  /// No description provided for @dropStashConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this stash?'**
  String get dropStashConfirm;

  /// No description provided for @noStashes.
  ///
  /// In en, this message translates to:
  /// **'No stashes saved yet.'**
  String get noStashes;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get accentColor;

  /// No description provided for @interfaceDensity.
  ///
  /// In en, this message translates to:
  /// **'Interface Density'**
  String get interfaceDensity;

  /// No description provided for @comfortable.
  ///
  /// In en, this message translates to:
  /// **'Comfortable'**
  String get comfortable;

  /// No description provided for @compact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get compact;

  /// No description provided for @reduceMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce Animations'**
  String get reduceMotion;

  /// No description provided for @gitConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Git Configuration'**
  String get gitConfiguration;

  /// No description provided for @gitStatus.
  ///
  /// In en, this message translates to:
  /// **'Git Status'**
  String get gitStatus;

  /// No description provided for @gitInstalled.
  ///
  /// In en, this message translates to:
  /// **'System Git Detected'**
  String get gitInstalled;

  /// No description provided for @gitNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'System Git Not Found'**
  String get gitNotInstalled;

  /// No description provided for @gitVersion.
  ///
  /// In en, this message translates to:
  /// **'Git Version: {version}'**
  String gitVersion(String version);

  /// No description provided for @gitPath.
  ///
  /// In en, this message translates to:
  /// **'Git Executable Path'**
  String get gitPath;

  /// No description provided for @chooseCustomGitPath.
  ///
  /// In en, this message translates to:
  /// **'Choose Custom Git Executable'**
  String get chooseCustomGitPath;

  /// No description provided for @gitUserName.
  ///
  /// In en, this message translates to:
  /// **'Git User Name'**
  String get gitUserName;

  /// No description provided for @gitUserEmail.
  ///
  /// In en, this message translates to:
  /// **'Git User Email'**
  String get gitUserEmail;

  /// No description provided for @saveConfig.
  ///
  /// In en, this message translates to:
  /// **'Save Git Configuration'**
  String get saveConfig;

  /// No description provided for @gitBackend.
  ///
  /// In en, this message translates to:
  /// **'Git Backend Engine'**
  String get gitBackend;

  /// No description provided for @backendAuto.
  ///
  /// In en, this message translates to:
  /// **'Hybrid (LibGit2 + Git CLI)'**
  String get backendAuto;

  /// No description provided for @backendLibGit2.
  ///
  /// In en, this message translates to:
  /// **'LibGit2 Only'**
  String get backendLibGit2;

  /// No description provided for @backendCli.
  ///
  /// In en, this message translates to:
  /// **'Git CLI Only'**
  String get backendCli;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About Gitora'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @productIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Product Identifier: dev.skrinvex.gitora'**
  String get productIdentifier;

  /// No description provided for @commandPalette.
  ///
  /// In en, this message translates to:
  /// **'Command Palette'**
  String get commandPalette;

  /// No description provided for @commandPalettePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type a command or search action (Esc to close)...'**
  String get commandPalettePlaceholder;

  /// No description provided for @noCommandsFound.
  ///
  /// In en, this message translates to:
  /// **'No matching commands found'**
  String get noCommandsFound;

  /// No description provided for @onboardingWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Gitora'**
  String get onboardingWelcome;

  /// No description provided for @onboardingStep1.
  ///
  /// In en, this message translates to:
  /// **'1. Git Verification'**
  String get onboardingStep1;

  /// No description provided for @onboardingStep2.
  ///
  /// In en, this message translates to:
  /// **'2. User Identity'**
  String get onboardingStep2;

  /// No description provided for @onboardingStep3.
  ///
  /// In en, this message translates to:
  /// **'3. Appearance & Style'**
  String get onboardingStep3;

  /// No description provided for @onboardingStep4.
  ///
  /// In en, this message translates to:
  /// **'4. First Repository'**
  String get onboardingStep4;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingFinish.
  ///
  /// In en, this message translates to:
  /// **'Launch Gitora'**
  String get onboardingFinish;

  /// No description provided for @onboardingGitReady.
  ///
  /// In en, this message translates to:
  /// **'Git engine is ready to power your workflow.'**
  String get onboardingGitReady;

  /// No description provided for @onboardingGitInstallNote.
  ///
  /// In en, this message translates to:
  /// **'Git was not found in standard system PATH. You can specify the git.exe path or download Git from git-scm.com.'**
  String get onboardingGitInstallNote;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
