import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseBootstrapProvider = Provider<FirebaseBootstrap>((ref) {
  return FirebaseBootstrap.instance;
});

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static final instance = FirebaseBootstrap._();

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
      return true;
    } catch (error) {
      _initializationError = error;
      return false;
    }
  }
}
