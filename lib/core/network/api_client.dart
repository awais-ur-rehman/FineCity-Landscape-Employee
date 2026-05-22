import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_endpoints.dart';

const _kAccessToken = 'fc_access_token';
const _kRefreshToken = 'fc_refresh_token';

/// Configured Dio client with JWT auto-refresh interceptor.
class ApiClient {
  late final Dio dio;
  final SharedPreferences _prefs;

  ApiClient(this._prefs) {
    dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(_AuthInterceptor(_prefs, dio));
  }

  // Token helpers
  String? get accessToken => _prefs.getString(_kAccessToken);
  String? get refreshToken => _prefs.getString(_kRefreshToken);

  Future<void> saveTokens(String access, String refresh) async {
    await _prefs.setString(_kAccessToken, access);
    await _prefs.setString(_kRefreshToken, refresh);
  }

  Future<void> clearTokens() async {
    await _prefs.remove(_kAccessToken);
    await _prefs.remove(_kRefreshToken);
    await _prefs.remove('fc_user');
  }

  bool get isAuthenticated => _prefs.getString(_kAccessToken) != null;
}

/// Interceptor that attaches JWT and auto-refreshes on 401.
class _AuthInterceptor extends Interceptor {
  final SharedPreferences _prefs;
  final Dio _dio;
  bool _isRefreshing = false;
  final List<({ErrorInterceptorHandler handler, RequestOptions options})> _queue = [];

  _AuthInterceptor(this._prefs, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _prefs.getString(_kAccessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final path = err.requestOptions.path;
    if (path.contains('/auth/refresh-token') || path.contains('/auth/verify-otp')) {
      return handler.next(err);
    }

    if (_isRefreshing) {
      _queue.add((handler: handler, options: err.requestOptions));
      return;
    }

    _isRefreshing = true;
    final refresh = _prefs.getString(_kRefreshToken);

    if (refresh == null) {
      _isRefreshing = false;
      await _prefs.remove(_kAccessToken);
      await _prefs.remove(_kRefreshToken);
      return handler.next(err);
    }

    try {
      final res = await Dio().post(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.refreshToken}',
        data: {'refreshToken': refresh},
      );

      final newAccess = res.data['data']['accessToken'] as String;
      final newRefresh = res.data['data']['refreshToken'] as String;
      await _prefs.setString(_kAccessToken, newAccess);
      await _prefs.setString(_kRefreshToken, newRefresh);

      // Retry original request
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
      final retryRes = await _dio.fetch(err.requestOptions);
      handler.resolve(retryRes);

      // Process queued requests
      for (final queued in _queue) {
        queued.options.headers['Authorization'] = 'Bearer $newAccess';
        final r = await _dio.fetch(queued.options);
        queued.handler.resolve(r);
      }
    } catch (_) {
      await _prefs.remove(_kAccessToken);
      await _prefs.remove(_kRefreshToken);
      handler.next(err);
      for (final queued in _queue) {
        queued.handler.next(err);
      }
    } finally {
      _isRefreshing = false;
      _queue.clear();
    }
  }
}
