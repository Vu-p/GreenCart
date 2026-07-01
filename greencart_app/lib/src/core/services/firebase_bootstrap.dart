import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final firebaseBootstrapProvider = Provider<FirebaseBootstrap>((ref) {
  return FirebaseBootstrap.instance;
});

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static final instance = FirebaseBootstrap._();
  static const _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  Future<bool>? _initialization;
  Object? _initializationError;

  Object? get initializationError => _initializationError;

  Future<bool> ensureInitialized() {
    return _initialization ??= _initialize();
  }

  Future<bool> _initialize() async {
    // Bypass Firebase initialization for local testing to avoid hangs
    return false;
    
    try {
      await Firebase.initializeApp().timeout(const Duration(seconds: 5));
      await GoogleSignIn.instance.initialize(
        serverClientId: _googleServerClientId.isEmpty
            ? null
            : _googleServerClientId,
      ).timeout(const Duration(seconds: 5));
      return true;
    } catch (error) {
      _initializationError = error;
      return false;
    }
  }
}
