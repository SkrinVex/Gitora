import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gitora/application/providers/current_repo_provider.dart';
import 'package:gitora/application/providers/git_service_provider.dart';
import 'package:gitora/application/providers/onboarding_provider.dart';
import 'package:gitora/application/providers/settings_provider.dart';
import 'package:gitora/core/constants/app_constants.dart';
import 'package:gitora/core/theme/app_colors.dart';
import 'package:gitora/domain/models/git_system_info.dart';
import 'package:gitora/l10n/app_localizations.dart';
import 'package:gitora/presentation/widgets/gitora_logo.dart';

class OnboardingWizard extends ConsumerStatefulWidget {
  const OnboardingWizard({super.key});

  @override
  ConsumerState<OnboardingWizard> createState() => _OnboardingWizardState();
}

class _OnboardingWizardState extends ConsumerState<OnboardingWizard> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _gitPathController = TextEditingController();
  GitSystemInfo _systemInfo = GitSystemInfo.empty;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSystem();
  }

  Future<void> _checkSystem() async {
    setState(() => _isLoading = true);
    final git = ref.read(gitServiceProvider);
    final info = await git.checkSystemInfo();
    final config = await git.getUserConfig();

    _nameController.text = config.name;
    _emailController.text = config.email;

    setState(() {
      _systemInfo = info;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _gitPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final onboardingState = ref.watch(onboardingProvider);
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Container(
          width: 680,
          margin: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withAlpha(80),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primaryContainer.withAlpha(120),
                      theme.colorScheme.surfaceContainerHigh,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    const GitoraLogo(size: 48),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.onboardingWelcome,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            AppConstants.appTagline,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Progress bar
              LinearProgressIndicator(
                value: (onboardingState.currentStep + 1) / 5,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),

              // Step Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: _buildCurrentStep(
                    onboardingState.currentStep,
                    theme,
                    l10n,
                    settings,
                    settingsNotifier,
                  ),
                ),
              ),

              // Bottom Navigation
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outlineVariant.withAlpha(80),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    if (onboardingState.currentStep > 0)
                      OutlinedButton(
                        onPressed: () => ref
                            .read(onboardingProvider.notifier)
                            .previousStep(),
                        child: const Text('Back'),
                      ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => _handleNext(onboardingState.currentStep),
                      child: Text(
                        onboardingState.currentStep == 4
                            ? l10n.onboardingFinish
                            : l10n.onboardingContinue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(
    int step,
    ThemeData theme,
    AppLocalizations l10n,
    AppSettings settings,
    SettingsNotifier settingsNotifier,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (step) {
      case 0:
        // Step 1: Git Verification
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.onboardingStep1, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              _systemInfo.isCliInstalled
                  ? l10n.onboardingGitReady
                  : l10n.onboardingGitInstallNote,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _systemInfo.isCliInstalled
                              ? Icons.check_circle
                              : Icons.warning_amber_rounded,
                          color: _systemInfo.isCliInstalled
                              ? AppColors.gitAdded
                              : Colors.amber.shade800,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _systemInfo.isCliInstalled
                                    ? _systemInfo.cliVersion
                                    : 'Git CLI not found in system PATH',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _systemInfo.isLibGit2Available
                                    ? 'LibGit2 fallback available (v${_systemInfo.libGit2Version})'
                                    : 'No fallback available',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!_systemInfo.isCliInstalled) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.download, size: 16),
                            label: const Text('Download Git for Windows'),
                            onPressed: () => launchUrl(
                              Uri.parse('https://git-scm.com/download/win'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.folder_open, size: 16),
                            label: const Text('Select git.exe'),
                            onPressed: _browseGit,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );

      case 1:
        // Step 2: Developer Identity
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.onboardingStep2, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Configure the author name and email that will be stamped on your Git commits.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.gitUserName,
                hintText: 'John Doe',
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: l10n.gitUserEmail,
                hintText: 'john@example.com',
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
          ],
        );

      case 2:
        // Step 3: Appearance & Style
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.onboardingStep3, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Choose your preferred theme mode and primary accent color palette.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(l10n.systemTheme),
                  icon: const Icon(Icons.brightness_auto, size: 16),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(l10n.lightTheme),
                  icon: const Icon(Icons.light_mode, size: 16),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(l10n.darkTheme),
                  icon: const Icon(Icons.dark_mode, size: 16),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (set) =>
                  settingsNotifier.setThemeMode(set.first),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.accentColor,
              style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                for (final color in AppColors.seedPalette)
                  InkWell(
                    onTap: () => settingsNotifier.setSeedColor(color),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              settings.seedColor.toARGB32() == color.toARGB32()
                              ? Colors.white
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: settings.seedColor.toARGB32() == color.toARGB32()
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 22,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ],
        );

      case 3:
        // Step 4: Language
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.language, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Select your preferred application language.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'en',
                  label: Text('English', style: TextStyle(fontSize: 14)),
                ),
                ButtonSegment(
                  value: 'ru',
                  label: Text('Русский', style: TextStyle(fontSize: 14)),
                ),
              ],
              selected: {settings.locale?.languageCode ?? 'en'},
              onSelectionChanged: (set) =>
                  settingsNotifier.setLanguage(set.first),
            ),
          ],
        );

      case 4:
        // Step 5: Ready to Go / First Repository
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.onboardingStep4, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'You are all set! You can open an existing repository now or jump straight to the Dashboard.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _pickFirstRepo,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 36,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.openRepository,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Browse folders on your PC',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _handleNext(int currentStep) async {
    if (currentStep == 1) {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      if (name.isNotEmpty && email.isNotEmpty) {
        final git = ref.read(gitServiceProvider);
        await git.setUserConfig(name: name, email: email);
      }
    }

    if (currentStep < 4) {
      ref.read(onboardingProvider.notifier).nextStep();
    } else {
      await ref.read(onboardingProvider.notifier).completeOnboarding();
    }
  }

  Future<void> _browseGit() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['exe', 'cmd', 'bat'],
    );
    if (result.isNotEmpty && result.first.path != null) {
      final path = result.first.path!;
      await ref.read(settingsProvider.notifier).setCustomGitPath(path);
      await _checkSystem();
    }
  }

  Future<void> _pickFirstRepo() async {
    final path = await FilePicker.getDirectoryPath();
    if (path != null) {
      ref.read(currentRepoProvider.notifier).setRepo(path);
      await ref.read(onboardingProvider.notifier).completeOnboarding();
    }
  }
}
