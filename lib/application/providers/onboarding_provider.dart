import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitora/application/providers/settings_provider.dart';
import 'package:gitora/core/constants/app_constants.dart';

class OnboardingState {
  final bool isCompleted;
  final int currentStep;

  const OnboardingState({this.isCompleted = false, this.currentStep = 0});

  OnboardingState copyWith({bool? isCompleted, int? currentStep}) {
    return OnboardingState(
      isCompleted: isCompleted ?? this.isCompleted,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final completed =
        prefs?.getBool(AppConstants.prefOnboardingCompleted) ?? false;
    return OnboardingState(isCompleted: completed, currentStep: 0);
  }

  void nextStep() {
    state = state.copyWith(currentStep: state.currentStep + 1);
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void setStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(isCompleted: true);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs?.setBool(AppConstants.prefOnboardingCompleted, true);
  }

  Future<void> resetOnboarding() async {
    state = const OnboardingState(isCompleted: false, currentStep: 0);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs?.setBool(AppConstants.prefOnboardingCompleted, false);
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
      OnboardingNotifier.new,
    );
