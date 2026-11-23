import 'dart:convert';

import 'package:dt13_pos/features/onboarding/domain/business_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingRepository {
  static const String _businessProfileKey = 'onboarding.business_profile';
  static const String _onboardingCompletedKey = 'onboarding.completed';

  Future<void> saveBusinessProfile(BusinessProfile profile) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _businessProfileKey,
      jsonEncode(profile.toJson()),
    );
    if (!saved) {
      throw Exception('Không thể lưu thông tin hộ kinh doanh.');
    }
  }

  Future<BusinessProfile?> getBusinessProfile() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_businessProfileKey);
    if (encoded == null) return null;

    final Object? decoded = jsonDecode(encoded);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Thông tin hộ kinh doanh không hợp lệ.');
    }
    return BusinessProfile.fromJson(decoded);
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setBool(_onboardingCompletedKey, completed);
    if (!saved) {
      throw Exception('Không thể lưu trạng thái hoàn tất khai báo.');
    }
  }

  Future<bool> isOnboardingCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_onboardingCompletedKey) ?? false;
  }
}
