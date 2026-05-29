import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config.dart';

const _tokenKey = 'access_token';

final secureStorageProvider = Provider((_) => const FlutterSecureStorage());

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiV1,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final storage = ref.read(secureStorageProvider);
      final token = await storage.read(key: _tokenKey);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
  ));

  return dio;
});

Future<void> saveToken(Ref ref, String token) async {
  await ref.read(secureStorageProvider).write(key: _tokenKey, value: token);
}

Future<void> clearToken(Ref ref) async {
  await ref.read(secureStorageProvider).delete(key: _tokenKey);
}

String apiErrorMessage(DioException e) {
  final data = e.response?.data;
  if (data is Map && data['detail'] != null) {
    final d = data['detail'];
    if (d is String) return d;
    if (d is List && d.isNotEmpty) return d.first.toString();
  }
  return e.message ?? 'Request failed';
}
