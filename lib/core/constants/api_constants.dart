class ApiConstants {
  ApiConstants._();

  // Change this to your backend URL
  static const baseUrl = 'http://10.0.2.2:8080/api/v1';

  // Auth
  static const authAnonymous = '/auth/anonymous';
  static const authRefresh = '/auth/refresh';

  // Sessions
  static const sessions = '/sessions';
  static String sessionMessages(String sessionId) =>
      '/sessions/$sessionId/messages/text';
  static String sessionVoice(String sessionId) =>
      '/sessions/$sessionId/messages/voice';
  static String sessionEnd(String sessionId) =>
      '/sessions/$sessionId/end';

  // Vault
  static const vaultSettings = '/vault/settings';
  static const vaultSessions = '/vault/sessions';
  static String vaultSessionDetail(String sessionId) =>
      '/vault/sessions/$sessionId';
}
