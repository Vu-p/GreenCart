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
    try {
      await Firebase.initializeApp();
      return true;
    } catch (error) {
      _initializationError = error;
      return false;
    }
  }
}
