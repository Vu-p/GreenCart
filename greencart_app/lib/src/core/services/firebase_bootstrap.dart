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
    try {
      await Firebase.initializeApp();
      await GoogleSignIn.instance.initialize(
        serverClientId: _googleServerClientId.isEmpty
            ? null
            : _googleServerClientId,
      );
      return true;
    } catch (error) {
      _initializationError = error;
      return false;
    }
  }
}
