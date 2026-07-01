import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/auth_preference_store.dart';
import '../../../core/services/firebase_bootstrap.dart';
import '../../../core/services/token_storage.dart';
import '../models/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
    ref.watch(firebaseBootstrapProvider),
    ref.watch(authPreferenceStoreProvider),
  );
});

class AuthRepository {
  AuthRepository(
    this._apiClient,
    this._tokenStorage,
    this._firebaseBootstrap,
    this._authPreferenceStore,
  );

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  final FirebaseBootstrap _firebaseBootstrap;
  final AuthPreferenceStore _authPreferenceStore;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
  );

  Future<AppUser?> restoreSession() async {
    if (!await _authPreferenceStore.hasLoggedInBefore()) {
      return null;
    }

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
    final user = await _loginBackendWithFirebaseUser(credential.user);
    await _authPreferenceStore.markLogin('password');
    return user;
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
    final user = await _loginBackendWithFirebaseUser(
      credential.user,
      fallbackName: name,
    );
    await _authPreferenceStore.markLogin('password');
    return user;
  }

  Future<AppUser> loginWithGoogle() async {
    await _requireFirebase();

    final googleAccount = await _googleSignIn.signIn();
    if (googleAccount == null) {
      throw StateError('Google sign-in was canceled.');
    }
    final firebaseCredential = await _firebaseSignIn(googleAccount);
    final user = await _loginBackendWithFirebaseUser(firebaseCredential.user);
    await _authPreferenceStore.markLogin('google');
    return user;
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
    await _authPreferenceStore.clearLoginHint();
    if (await _firebaseBootstrap.ensureInitialized()) {
      await FirebaseAuth.instance.signOut();
      await _googleSignIn.signOut();
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

  Future<UserCredential> _firebaseSignIn(
    GoogleSignInAccount googleAccount,
  ) async {
    final authentication = await googleAccount.authentication;
    final googleIdToken = authentication.idToken;
    if (googleIdToken == null || googleIdToken.isEmpty) {
      throw StateError('Google Sign-In did not return an id token.');
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: authentication.accessToken,
      idToken: googleIdToken,
    );
    return FirebaseAuth.instance.signInWithCredential(credential);
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
