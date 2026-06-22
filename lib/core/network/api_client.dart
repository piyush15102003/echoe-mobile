import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

/// Signals the router to force re-onboarding when auth is completely broken
/// (e.g. refresh token invalidated server-side after reuse detection).
class AuthStateNotifier {
  static final needsReAuth = ValueNotifier<bool>(false);
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 120),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(_AuthInterceptor(dio));
  return dio;
});

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;
  // Pending requests that arrived while a refresh was already in flight.
  // They all wait on the same Completer so only one refresh call is made.
  Completer<String>? _refreshCompleter;

  _AuthInterceptor(this._dio);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip auth for public endpoints
    final path = options.path;
    if (path.contains('/auth/anonymous') || path.contains('/auth/refresh')) {
      return handler.next(options);
    }

    final token = await SecureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    if (statusCode != 401 && statusCode != 403) {
      return handler.next(err);
    }

    // PIN-specific errors must not trigger a token refresh.
    final data = err.response?.data;
    if (data is Map) {
      final detail = data['detail']?.toString() ?? '';
      if (detail.contains('Invalid PIN') || detail.contains('No PIN set')) {
        return handler.next(err);
      }
    }

    // ── Concurrent-safe refresh ───────────────────────────────────────────
    // If a refresh is already in flight, queue behind it instead of firing
    // a second refresh call. All concurrent 401s share a single Completer.
    if (_isRefreshing) {
      try {
        final newAccess = await _refreshCompleter!.future;
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newAccess';
        return handler.resolve(await _dio.fetch(opts));
      } catch (_) {
        return handler.next(err);
      }
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<String>();

    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken == null) {
        _isRefreshing = false;
        _refreshCompleter!.completeError('no_refresh_token');
        _refreshCompleter = null;
        return handler.next(err);
      }

      final response = await _dio.post(
        ApiConstants.authRefresh,
        data: {'refresh_token': refreshToken},
      );

      final newAccess = response.data['access_token'] as String;
      final newRefresh = response.data['refresh_token'] as String;
      await SecureStorage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );

      _refreshCompleter!.complete(newAccess);
      _isRefreshing = false;
      _refreshCompleter = null;

      // Retry original request
      final opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer $newAccess';
      return handler.resolve(await _dio.fetch(opts));
    } catch (e) {
      _refreshCompleter?.completeError(e);
      _isRefreshing = false;
      _refreshCompleter = null;
      // Refresh failed (token reuse, expired, or server error).
      // Wipe all stored credentials and force the user through onboarding again.
      await SecureStorage.clearAll();
      AuthStateNotifier.needsReAuth.value = true;
      handler.next(err);
    }
  }
}
