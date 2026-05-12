import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(dioProvider));
});

enum OnboardingStep { language, voice, biometric, pin, done }

final onboardingStepProvider =
    StateProvider<OnboardingStep>((ref) => OnboardingStep.language);

final selectedLanguageProvider = StateProvider<String>((ref) => 'en');
final selectedVoiceProvider = StateProvider<String>((ref) => 'female');
