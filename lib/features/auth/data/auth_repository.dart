import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/storage/secure_storage.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<Map<String, dynamic>> createAnonymousUser({
    required String deviceId,
    required String language,
    required String voicePreference,
  }) async {
    final response = await _dio.post(
      ApiConstants.authAnonymous,
      data: {
        'device_id': deviceId,
        'preferred_language': language,
        'voice_preference': voicePreference,
      },
    );

    final data = response.data as Map<String, dynamic>;

    await SecureStorage.saveTokens(
      accessToken: data['access_token'],
      refreshToken: data['refresh_token'],
    );
    await SecureStorage.saveUserId(data['user_id']);

    return data;
  }

  /// Register or update the user's PIN on the backend.
  Future<void> setPin(String pin) async {
    await _dio.post(
      ApiConstants.authSetPin,
      data: {'pin': pin},
    );
  }

  /// Verify PIN against the backend.
  /// Returns `{success: bool, attempts_left: int?, locked_until: String?}`.
  Future<Map<String, dynamic>> verifyPin(String pin) async {
    final response = await _dio.post(
      ApiConstants.authVerifyPin,
      data: {'pin': pin},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Wipe the user's account after PIN verification.
  Future<void> wipeAccount(String pin) async {
    await _dio.delete(
      ApiConstants.authWipe,
      data: {'pin': pin},
    );
  }

  /// Force-wipe the account without PIN (used when user forgot PIN and has no biometric).
  /// Requires a valid JWT — the token interceptor handles refresh automatically.
  Future<void> wipeForce() async {
    await _dio.delete(ApiConstants.authWipeForce);
  }

  /// Save or update the user's emergency contact.
  Future<void> saveEmergencyContact({
    required String name,
    required String phone,
  }) async {
    await _dio.put(
      ApiConstants.authEmergencyContact,
      data: {'name': name, 'phone': phone},
    );
  }

  /// Remove the emergency contact.
  Future<void> deleteEmergencyContact() async {
    await _dio.delete(ApiConstants.authEmergencyContact);
  }
}
