import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final firebaseBootstrapProvider = Provider<FirebaseBootstrap>((ref) {
  return FirebaseBootstrap.instance;
});

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static final instance = FirebaseBootstrap._();

  Future<bool>? _initialization;

  Future<bool> ensureInitialized() {
    return _initialization ??= _initialize();
  }

  Future<bool> _initialize() async {
    try {
      await Firebase.initializeApp();
      await GoogleSignIn.instance.initialize();
      return true;
    } catch (_) {
      return false;
    }
  }
}
