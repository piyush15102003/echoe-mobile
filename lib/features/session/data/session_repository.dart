import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';

class SessionRepository {
  final Dio _dio;

  SessionRepository(this._dio);

  Future<Map<String, dynamic>> createSession({
    required String inputMode,
    required String language,
  }) async {
    final response = await _dio.post(
      ApiConstants.sessions,
      data: {'input_mode': inputMode, 'language': language},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> sendTextMessage({
    required String sessionId,
    required String content,
  }) async {
    final response = await _dio.post(
      ApiConstants.sessionMessages(sessionId),
      data: {'content': content},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> sendVoiceMessage({
    required String sessionId,
    required List<int> audioBytes,
    required String language,
  }) async {
    final formData = FormData.fromMap({
      'audio': MultipartFile.fromBytes(audioBytes, filename: 'audio.wav'),
      'language': language,
    });
    final response = await _dio.post(
      ApiConstants.sessionVoice(sessionId),
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> endSession(String sessionId) async {
    final response = await _dio.post(ApiConstants.sessionEnd(sessionId));
    return response.data;
  }

  Future<void> pauseSession(String sessionId) async {
    await _dio.post(ApiConstants.sessionPause(sessionId));
  }

  Future<Map<String, dynamic>> resumeSession(String sessionId) async {
    final response = await _dio.post(ApiConstants.sessionResume(sessionId));
    return response.data;
  }

  /// Returns active/paused session info, or null if none.
  Future<Map<String, dynamic>?> getActiveSession() async {
    final response = await _dio.get(ApiConstants.activeSession);
    if (response.statusCode == 204 || response.data == null) return null;
    return response.data;
  }
}
