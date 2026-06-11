import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/token_storage.dart';
import '../models/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

class AuthRepository {
  AuthRepository(this._apiClient, this._tokenStorage);

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<AppUser?> restoreSession() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final response = await _apiClient.get('/api/auth/me', authorized: true);
      return AppUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      await _tokenStorage.clear();
      return null;
    }
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/api/auth/login',
      data: {'email': email, 'password': password},
    );
    return await _persistAuthResponse(response.data as Map<String, dynamic>);
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/api/auth/register',
      data: {'name': name, 'email': email, 'password': password},
    );
    return await _persistAuthResponse(response.data as Map<String, dynamic>);
  }

  Future<AppUser> updateProfile({
    required String name,
    String? phone,
    String? address,
    String? avatarUrl,
  }) async {
    final response = await _apiClient.put(
      '/api/profile',
      authorized: true,
      data: {
        'name': name,
        'phone': phone,
        'address': address,
        'avatarUrl': avatarUrl,
      },
    );
    return AppUser.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout() => _tokenStorage.clear();

  Future<AppUser> _persistAuthResponse(Map<String, dynamic> json) async {
    final token = json['token'] as String;
    final user = AppUser.fromJson(json['user'] as Map<String, dynamic>);
    await _tokenStorage.saveToken(token);
    return user;
  }
}
