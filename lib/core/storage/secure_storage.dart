import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _deviceIdKey = 'device_id';
  static const _biometricEnabledKey = 'biometric_enabled';
  static const _onboardingCompleteKey = 'onboarding_complete';
  static const _languageKey = 'preferred_language';
  static const _voiceKey = 'voice_preference';
  static const _pinHashKey = 'pin_hash';

  // Tokens
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  static Future<String?> getAccessToken() =>
      _storage.read(key: _accessTokenKey);

  static Future<String?> getRefreshToken() =>
      _storage.read(key: _refreshTokenKey);

  // User
  static Future<void> saveUserId(String userId) =>
      _storage.write(key: _userIdKey, value: userId);

  static Future<String?> getUserId() => _storage.read(key: _userIdKey);

  // Device ID
  static Future<void> saveDeviceId(String deviceId) =>
      _storage.write(key: _deviceIdKey, value: deviceId);

  static Future<String?> getDeviceId() => _storage.read(key: _deviceIdKey);

  // Biometric
  static Future<void> setBiometricEnabled(bool enabled) =>
      _storage.write(key: _biometricEnabledKey, value: enabled.toString());

  static Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _biometricEnabledKey);
    return val == 'true';
  }

  // Onboarding
  static Future<void> setOnboardingComplete() =>
      _storage.write(key: _onboardingCompleteKey, value: 'true');

  static Future<bool> isOnboardingComplete() async {
    final val = await _storage.read(key: _onboardingCompleteKey);
    return val == 'true';
  }

  // Preferences
  static Future<void> saveLanguage(String lang) =>
      _storage.write(key: _languageKey, value: lang);

  static Future<String?> getLanguage() => _storage.read(key: _languageKey);

  static Future<void> saveVoicePreference(String voice) =>
      _storage.write(key: _voiceKey, value: voice);

  static Future<String?> getVoicePreference() =>
      _storage.read(key: _voiceKey);

  // PIN hash (offline fallback)
  static Future<void> savePinHash(String hash) =>
      _storage.write(key: _pinHashKey, value: hash);

  static Future<String?> getPinHash() => _storage.read(key: _pinHashKey);

  static Future<bool> hasPinSet() async {
    final val = await _storage.read(key: _pinHashKey);
    return val != null && val.isNotEmpty;
  }

  // Wipe
  static Future<void> clearAll() => _storage.deleteAll();
}
