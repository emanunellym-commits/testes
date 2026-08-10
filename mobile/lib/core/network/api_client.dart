import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class ApiClient {
  ApiClient._() {
    dio = Dio(BaseOptions(baseUrl: baseUrl));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final value = await token();
          if (value != null && value.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $value';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              error.requestOptions.path != '/auth/refresh') {
            if (await refreshSession()) {
              final request = error.requestOptions;
              request.headers['Authorization'] =
                  'Bearer ${await token()}';

              try {
                return handler.resolve(await dio.fetch(request));
              } catch (_) {}
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  static const baseUrl = AppConfig.apiUrl;
  static final instance = ApiClient._();
  static const _storage = FlutterSecureStorage();

  late final Dio dio;

  Future<String?> token() => _storage.read(key: 'access_token');
  Future<String?> refreshToken() => _storage.read(key: 'refresh_token');
  Future<String?> deviceId() => _storage.read(key: 'device_id');

  Future<void> ensureDeviceId() async {
    if (await deviceId() != null) return;
    await _storage.write(
      key: 'device_id',
      value: 'device-${DateTime.now().microsecondsSinceEpoch}',
    );
  }

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<void> saveToken(String value) =>
      _storage.write(key: 'access_token', value: value);

  Future<bool> refreshSession() async {
    final refresh = await refreshToken();
    if (refresh == null || refresh.isEmpty) return false;

    try {
      final response = await Dio(
        BaseOptions(baseUrl: baseUrl),
      ).post('/auth/refresh', data: {
        'refreshToken': refresh,
      });

      await saveSession(
        accessToken: response.data['accessToken'],
        refreshToken: response.data['refreshToken'],
      );
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  static String absoluteMediaUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '$baseUrl$url';
  }
}
