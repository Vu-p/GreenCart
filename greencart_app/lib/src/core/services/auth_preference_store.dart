import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authPreferenceStoreProvider = Provider<AuthPreferenceStore>((ref) {
  return const AuthPreferenceStore();
});

class AuthPreferenceStore {
  const AuthPreferenceStore();

  static const _hasLoggedInBeforeKey = 'auth.hasLoggedInBefore';
  static const _lastLoginProviderKey = 'auth.lastLoginProvider';

  Future<bool> hasLoggedInBefore() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_hasLoggedInBeforeKey) ?? false;
  }

  Future<String?> lastLoginProvider() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_lastLoginProviderKey);
  }

  Future<void> markLogin(String provider) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_hasLoggedInBeforeKey, true);
    await preferences.setString(_lastLoginProviderKey, provider);
  }

  Future<void> clearLoginHint() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_lastLoginProviderKey);
  }
}
