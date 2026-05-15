class ApiConstants {
  ApiConstants._();

  // Set via --dart-define=BASE_URL=http://10.0.2.2:8080/api/v1 for emulator
  // Defaults to LAN IP for real phone
  static const baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://192.168.1.7:8080/api/v1',
  );

  // Auth
  static const authAnonymous = '/auth/anonymous';
  static const authRefresh = '/auth/refresh';
  static const authSetPin = '/auth/set-pin';
  static const authVerifyPin = '/auth/verify-pin';
  static const authWipe = '/auth/wipe';

  // Sessions
  static const sessions = '/sessions';
  static String sessionMessages(String sessionId) =>
      '/sessions/$sessionId/messages/text';
  static String sessionVoice(String sessionId) =>
      '/sessions/$sessionId/messages/voice';
  static String sessionEnd(String sessionId) =>
      '/sessions/$sessionId/end';
  static String sessionPause(String sessionId) =>
      '/sessions/$sessionId/pause';
  static String sessionResume(String sessionId) =>
      '/sessions/$sessionId/resume';
  static const activeSession = '/sessions/active';

  // Vault
  static const vaultSettings = '/vault/settings';
  static const vaultSessions = '/vault/sessions';
  static String vaultSessionDetail(String sessionId) =>
      '/vault/sessions/$sessionId';
  static String vaultSessionDelete(String sessionId) =>
      '/vault/sessions/$sessionId';
}
