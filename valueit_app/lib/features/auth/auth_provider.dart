import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../shared/api_service.dart';
import '../../shared/models.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  AuthNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  final Ref _ref;

  Future<void> _init() async {
    try {
      final token = await _ref.read(secureStorageProvider).read(key: 'access_token');
      if (token == null) {
        state = const AsyncValue.data(null);
        return;
      }
      final user = await _ref.read(apiServiceProvider).me();
      state = AsyncValue.data(user);
    } catch (_) {
      await clearToken(_ref);
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final data = await _ref.read(apiServiceProvider).login(email, password);
      await saveToken(_ref, data['access_token'] as String);
      state = AsyncValue.data(UserModel.fromJson(data['user'] as Map<String, dynamic>));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    await _ref.read(apiServiceProvider).register(
          fullName: fullName,
          email: email,
          password: password,
          role: role,
          phoneNumber: phone,
        );
  }

  Future<void> logout() async {
    await clearToken(_ref);
    state = const AsyncValue.data(null);
  }

  Future<void> refresh() async {
    try {
      final user = await _ref.read(apiServiceProvider).me();
      state = AsyncValue.data(user);
    } on DioException {
      await logout();
    }
  }
}

String homeRouteFor(UserModel? user) {
  if (user == null) return '/login';
  if (user.isPending) return '/pending';
  switch (user.role) {
    case 'Manager':
      return '/manager';
    case 'Valuer':
      return '/valuer';
    case 'SiteInspector':
      return '/inspector';
    default:
      return '/login';
  }
}
