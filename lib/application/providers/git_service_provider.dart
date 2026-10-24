import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitora/application/providers/settings_provider.dart';
import 'package:gitora/domain/services/git_service.dart';
import 'package:gitora/infrastructure/git/hybrid_git_service.dart';

final gitServiceProvider = Provider<GitService>((ref) {
  final settings = ref.watch(settingsProvider);
  final hybridService = HybridGitService();

  hybridService.setMode(settings.backendMode);
  if (settings.customGitPath.isNotEmpty) {
    hybridService.setCustomGitPath(settings.customGitPath);
  }

  return hybridService;
});
