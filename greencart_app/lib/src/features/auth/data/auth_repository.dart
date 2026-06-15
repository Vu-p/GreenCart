import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/firebase_bootstrap.dart';
import '../../../core/services/token_storage.dart';
import '../models/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
    ref.watch(firebaseBootstrapProvider),
  );
});

class AuthRepository {
  AuthRepository(this._apiClient, this._tokenStorage, this._firebaseBootstrap);

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  final FirebaseBootstrap _firebaseBootstrap;

  Future<AppUser?> restoreSession() async {
    if (await _firebaseBootstrap.ensureInitialized()) {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        try {
          return await _loginBackendWithFirebaseUser(firebaseUser);
        } on DioException {
          await FirebaseAuth.instance.signOut();
          await _tokenStorage.clear();
          return null;
        }
      }
    }

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
    await _requireFirebase();
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _loginBackendWithFirebaseUser(credential.user);
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _requireFirebase();
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
    await credential.user?.updateDisplayName(name.trim());
    return _loginBackendWithFirebaseUser(credential.user, fallbackName: name);
  }

  Future<AppUser> loginWithGoogle() async {
    await _requireFirebase();

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw StateError('Google Sign-In is not supported on this platform.');
    }

    final firebaseCredential = await _signInWithGoogleCredential();
    return _loginBackendWithFirebaseUser(firebaseCredential.user);
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

  Future<void> logout() async {
    await _tokenStorage.clear();
    if (await _firebaseBootstrap.ensureInitialized()) {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn.instance.signOut();
    }
  }

  Future<void> _requireFirebase() async {
    if (!await _firebaseBootstrap.ensureInitialized()) {
      final details = _firebaseBootstrap.initializationError;
      throw StateError(
        details == null
            ? 'Firebase is not configured. Add google-services.json/GoogleService-Info.plist and FlutterFire options.'
            : 'Firebase is not configured: $details',
      );
    }
  }

  bool _isNoCredentialAvailable(GoogleSignInException error) {
    return error.code == GoogleSignInExceptionCode.unknownError &&
        (error.description ?? '').toLowerCase().contains(
          'no credential available',
        );
  }

  Future<UserCredential> _signInWithGoogleCredential() async {
    try {
      final googleAccount = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      final googleIdToken = googleAccount.authentication.idToken;
      if (googleIdToken == null || googleIdToken.isEmpty) {
        throw StateError('Google Sign-In did not return an id token.');
      }

      final credential = GoogleAuthProvider.credential(idToken: googleIdToken);
      return FirebaseAuth.instance.signInWithCredential(credential);
    } on GoogleSignInException catch (error) {
      if (!_isNoCredentialAvailable(error)) {
        rethrow;
      }

      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');
      return FirebaseAuth.instance.signInWithProvider(provider);
    }
  }

  Future<AppUser> _loginBackendWithFirebaseUser(
    User? firebaseUser, {
    String? fallbackName,
  }) async {
    if (firebaseUser == null) {
      throw StateError('Firebase did not return a user.');
    }

    if (fallbackName != null && (firebaseUser.displayName ?? '').isEmpty) {
      await firebaseUser.updateDisplayName(fallbackName.trim());
      await firebaseUser.reload();
    }

    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Firebase did not return an id token.');
    }

    final response = await _apiClient.post(
      '/api/auth/firebase-login',
      data: {'idToken': idToken},
    );
    return await _persistAuthResponse(response.data as Map<String, dynamic>);
  }

  Future<AppUser> _persistAuthResponse(Map<String, dynamic> json) async {
    final token = json['token'] as String;
    final user = AppUser.fromJson(json['user'] as Map<String, dynamic>);
    await _tokenStorage.saveToken(token);
    return user;
  }
}
