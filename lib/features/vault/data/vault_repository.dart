import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';

class VaultRepository {
  final Dio _dio;

  VaultRepository(this._dio);

  Future<Map<String, dynamic>> getSettings() async {
    final response = await _dio.get(ApiConstants.vaultSettings);
    return response.data;
  }

  Future<Map<String, dynamic>> updateSettings({required bool enable}) async {
    final response = await _dio.post(
      ApiConstants.vaultSettings,
      data: {'vault_mode_enabled': enable},
    );
    return response.data;
  }

  Future<List<Map<String, dynamic>>> listSessions() async {
    final response = await _dio.get(ApiConstants.vaultSessions);
    if (response.data is List) {
      return (response.data as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>> getSessionDetail(String sessionId) async {
    final response = await _dio.get(
      ApiConstants.vaultSessionDetail(sessionId),
    );
    return response.data;
  }

  Future<void> deleteSession(String sessionId) async {
    await _dio.delete(
      ApiConstants.vaultSessionDelete(sessionId),
    );
  }
}
