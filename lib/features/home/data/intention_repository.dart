import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import 'intention_response.dart';

class IntentionRepository {
  final Dio _dio;

  IntentionRepository(this._dio);

  /// Returns today's intention, or null if none has been generated yet (204).
  Future<IntentionResponse?> getTodayIntention() async {
    try {
      final response = await _dio.get(ApiConstants.intentionToday);
      if (response.statusCode == 204 || response.data == null) return null;
      return IntentionResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 204) return null;
      rethrow;
    }
  }

  /// Mark the intention as viewed — called once when the text becomes visible.
  Future<void> markViewed(String id) async {
    try {
      await _dio.post(ApiConstants.intentionMarkViewed(id));
    } catch (_) {
      // Best-effort — don't surface errors to the user
    }
  }
}
