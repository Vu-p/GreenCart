import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import 'auth_repository.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  final AppUser? user;
  final bool isLoading;
  final String? errorMessage;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AppUser? user,
    bool clearUser = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  Future<bool> restoreSession() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final user = await _repository.restoreSession();
    state = AuthState(user: user);
    return user != null;
  }

  Future<bool> login(String email, String password) async {
    return _runAuthAction(() => _repository.login(
          email: email.trim(),
          password: password,
        ));
  }

  Future<bool> register(String name, String email, String password) async {
    return _runAuthAction(() => _repository.register(
          name: name.trim(),
          email: email.trim(),
          password: password,
        ));
  }

  Future<bool> updateProfile({
    required String name,
    String? phone,
    String? address,
  }) async {
    return _runAuthAction(() => _repository.updateProfile(
          name: name.trim(),
          phone: phone?.trim(),
          address: address?.trim(),
        ));
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState();
  }

  Future<bool> _runAuthAction(Future<AppUser> Function() action) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = await action();
      state = AuthState(user: user);
      return true;
    } catch (error) {
      state = AuthState(
        user: state.user,
        errorMessage: _messageFor(error),
      );
      return false;
    }
  }

  String _messageFor(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic> && data['message'] is String) {
        return data['message'] as String;
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Cannot connect to GreenCart API. Check API_BASE_URL.';
      }
    }

    return 'Something went wrong. Please try again.';
  }
}
