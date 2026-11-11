import 'package:dt13_pos/features/onboarding/data/onboarding_repository.dart';
import 'package:dt13_pos/features/onboarding/domain/business_profile.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_providers.g.dart';

@riverpod
OnboardingRepository onboardingRepository(Ref ref) {
  return OnboardingRepository();
}

@Riverpod(keepAlive: true)
class BusinessProfileNotifier extends _$BusinessProfileNotifier {
  @override
  Future<BusinessProfile?> build() {
    return ref.watch(onboardingRepositoryProvider).getBusinessProfile();
  }

  Future<void> saveBusinessProfile(BusinessProfile profile) async {
    try {
      await ref.read(onboardingRepositoryProvider).saveBusinessProfile(profile);
      state = AsyncData(profile);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final businessProfileNotifierProvider = businessProfileProvider;

@riverpod
Future<bool> isOnboardingCompleted(Ref ref) {
  return ref.watch(onboardingRepositoryProvider).isOnboardingCompleted();
}
