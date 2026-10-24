import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitora/application/providers/git_service_provider.dart';
import 'package:gitora/application/providers/onboarding_provider.dart';
import 'package:gitora/application/providers/settings_provider.dart';
import 'package:gitora/core/constants/app_constants.dart';
import 'package:gitora/core/theme/app_colors.dart';
import 'package:gitora/core/theme/app_theme.dart';
import 'package:gitora/domain/models/git_system_info.dart';
import 'package:gitora/infrastructure/git/hybrid_git_service.dart';
import 'package:gitora/l10n/app_localizations.dart';
import 'package:gitora/presentation/widgets/gitora_logo.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _userEmailController = TextEditingController();
  final TextEditingController _gitPathController = TextEditingController();
  GitSystemInfo _systemInfo = GitSystemInfo.empty;

  @override
  void initState() {
    super.initState();
    _loadGitInfo();
  }

  Future<void> _loadGitInfo() async {
    final git = ref.read(gitServiceProvider);
    final info = await git.checkSystemInfo();
    final config = await git.getUserConfig();

    _userNameController.text = config.name;
    _userEmailController.text = config.email;
    _gitPathController.text = ref.read(settingsProvider).customGitPath;

    setState(() {
      _systemInfo = info;
    });
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _userEmailController.dispose();
    _gitPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        children: [
          // Section 1: Appearance
          _buildSectionHeader(l10n.appearance, Icons.palette_outlined, theme),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Theme Mode
                  Text(
                    l10n.themeMode,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
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

                  const SizedBox(height: 20),

                  // Accent Seed Color
                  Text(
                    l10n.accentColor,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: [
                      for (final color in AppColors.seedPalette)
                        InkWell(
                          onTap: () => settingsNotifier.setSeedColor(color),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    settings.seedColor.toARGB32() ==
                                        color.toARGB32()
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: [
                                if (settings.seedColor.toARGB32() ==
                                    color.toARGB32())
                                  BoxShadow(
                                    color: color.withAlpha(120),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                              ],
                            ),
                            child:
                                settings.seedColor.toARGB32() ==
                                    color.toARGB32()
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Interface Density
                  Text(
                    l10n.interfaceDensity,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<InterfaceDensity>(
                    segments: [
                      ButtonSegment(
                        value: InterfaceDensity.comfortable,
                        label: Text(l10n.comfortable),
                        icon: const Icon(Icons.density_medium, size: 16),
                      ),
                      ButtonSegment(
                        value: InterfaceDensity.compact,
                        label: Text(l10n.compact),
                        icon: const Icon(Icons.density_small, size: 16),
                      ),
                    ],
                    selected: {settings.density},
                    onSelectionChanged: (set) =>
                        settingsNotifier.setDensity(set.first),
                  ),

                  const SizedBox(height: 16),

                  // Reduce motion
                  SwitchListTile(
                    title: Text(l10n.reduceMotion),
                    subtitle: const Text(
                      'Minimize UI animations for performance and accessibility',
                    ),
                    contentPadding: EdgeInsets.zero,
                    value: settings.reduceAnimations,
                    onChanged: (val) =>
                        settingsNotifier.setReduceAnimations(val),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Section 2: Git Configuration
          _buildSectionHeader(l10n.gitConfiguration, Icons.terminal, theme),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Git Status Banner
                  Row(
                    children: [
                      Icon(
                        _systemInfo.isCliInstalled
                            ? Icons.check_circle
                            : Icons.warning_amber_rounded,
                        color: _systemInfo.isCliInstalled
                            ? AppColors.gitAdded
                            : Colors.amber.shade800,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _systemInfo.isCliInstalled
                            ? l10n.gitInstalled
                            : l10n.gitNotInstalled,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (_systemInfo.cliVersion.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _systemInfo.cliVersion,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (_systemInfo.isLibGit2Available) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Embedded LibGit2 Engine: ${_systemInfo.libGit2Version} (Active)',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Custom Git Path
                  Text(
                    l10n.gitPath,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _gitPathController,
                          decoration: const InputDecoration(
                            hintText: 'Default (system PATH)',
                            isDense: true,
                          ),
                          onSubmitted: (val) =>
                              settingsNotifier.setCustomGitPath(val.trim()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.folder_open, size: 16),
                        label: const Text('Browse...'),
                        onPressed: _browseGitPath,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // User name & Email
                  Text(
                    'Git Identity',
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _userNameController,
                          decoration: InputDecoration(
                            labelText: l10n.gitUserName,
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _userEmailController,
                          decoration: InputDecoration(
                            labelText: l10n.gitUserEmail,
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _saveGitIdentity,
                        child: Text(l10n.save),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Backend Selection
                  Text(
                    l10n.gitBackend,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<GitBackendMode>(
                    segments: [
                      ButtonSegment(
                        value: GitBackendMode.auto,
                        label: Text(l10n.backendAuto),
                      ),
                      ButtonSegment(
                        value: GitBackendMode.libgit2Only,
                        label: Text(l10n.backendLibGit2),
                      ),
                      ButtonSegment(
                        value: GitBackendMode.cliOnly,
                        label: Text(l10n.backendCli),
                      ),
                    ],
                    selected: {settings.backendMode},
                    onSelectionChanged: (set) =>
                        settingsNotifier.setBackendMode(set.first),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Section 3: Language
          _buildSectionHeader(l10n.language, Icons.language, theme),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'en', label: Text('English')),
                        ButtonSegment(value: 'ru', label: Text('Русский')),
                      ],
                      selected: {settings.locale?.languageCode ?? 'en'},
                      onSelectionChanged: (set) =>
                          settingsNotifier.setLanguage(set.first),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Section 4: About Gitora
          _buildSectionHeader(l10n.about, Icons.info_outline, theme),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  const GitoraLogo(size: 48),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConstants.appName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          AppConstants.appTagline,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.version} ${AppConstants.appVersion} • ${AppConstants.productIdentifier}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        Text(
                          AppConstants.copyright,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.replay, size: 16),
                    label: const Text('Reset Onboarding'),
                    onPressed: () {
                      ref.read(onboardingProvider.notifier).resetOnboarding();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Onboarding reset. Re-open app to see welcome flow.',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _browseGitPath() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['exe', 'cmd', 'bat'],
    );

    if (result.isNotEmpty && result.first.path != null) {
      final path = result.first.path!;
      _gitPathController.text = path;
      await ref.read(settingsProvider.notifier).setCustomGitPath(path);
      await _loadGitInfo();
    }
  }

  Future<void> _saveGitIdentity() async {
    final name = _userNameController.text.trim();
    final email = _userEmailController.text.trim();

    final git = ref.read(gitServiceProvider);
    await git.setUserConfig(name: name, email: email);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Git configuration saved successfully')),
      );
    }
  }
}
