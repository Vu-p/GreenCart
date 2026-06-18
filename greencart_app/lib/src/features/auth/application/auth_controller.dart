import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../models/app_user.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref.watch(authRepositoryProvider));
  },
);

class AuthState {
  const AuthState({this.user, this.isLoading = false, this.errorMessage});

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
    try {
      final user = await _repository.restoreSession().timeout(
        const Duration(seconds: 8),
      );
      state = AuthState(user: user);
      return user != null;
    } catch (error) {
      state = AuthState(errorMessage: _messageFor(error));
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    return _runAuthAction(
      () => _repository.login(email: email.trim(), password: password),
    );
  }

  Future<bool> register(String name, String email, String password) async {
    return _runAuthAction(
      () => _repository.register(
        name: name.trim(),
        email: email.trim(),
        password: password,
      ),
    );
  }

  Future<bool> loginWithGoogle() async {
    return _runAuthAction(
      () => _repository.loginWithGoogle().timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          throw TimeoutException(
            'Google sign-in took too long. Close the Google window and try again.',
          );
        },
      ),
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<bool> updateProfile({
    required String name,
    String? phone,
    String? address,
  }) async {
    return _runAuthAction(
      () => _repository.updateProfile(
        name: name.trim(),
        phone: phone?.trim(),
        address: address?.trim(),
      ),
    );
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
      state = AuthState(user: state.user, errorMessage: _messageFor(error));
      return false;
    }
  }

  String _messageFor(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'account-exists-with-different-credential' =>
          'This email is already linked to another sign-in method.',
        'credential-already-in-use' =>
          'This Google account is already linked to another GreenCart account.',
        'invalid-credential' =>
          'Google credential is invalid. Check Firebase OAuth setup and SHA fingerprints.',
        'network-request-failed' =>
          'Network error while signing in with Firebase.',
        'operation-not-allowed' =>
          'Google Sign-In is disabled in Firebase Authentication.',
        'user-disabled' => 'This account has been disabled.',
        _ =>
          error.message ?? 'Firebase sign-in failed with code ${error.code}.',
      };
    }

    if (error is PlatformException) {
      return error.message ??
          'Platform sign-in failed with code ${error.code}.';
    }

    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic> && data['message'] is String) {
        return data['message'] as String;
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Cannot connect to GreenCart API. Check API_BASE_URL.';
      }
    }

    if (error is StateError) {
      return error.message;
    }

    if (error is TimeoutException) {
      return error.message ??
          'Session restore timed out. Please continue to login.';
    }

    return 'Something went wrong. Please try again.';
  }
}
