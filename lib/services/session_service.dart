import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

class SessionService {
  SessionService({this._prefs});

  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyCurrentUser = 'current_user';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> saveSession(UserModel user) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyCurrentUser, jsonEncode(user.toMap()));
  }

  Future<UserModel?> getLoggedInUser() async {
    final prefs = await _getPrefs();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    if (!isLoggedIn) return null;

    final raw = prefs.getString(_keyCurrentUser);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return UserModel.fromMap(decoded);
      }
      if (decoded is Map) {
        return UserModel.fromMap(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> clearSession() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyCurrentUser);
  }

  Future<List<dynamic>> loadFavorites(String username) async => [];
  Future<void> saveFavorites(String username, dynamic items) async {}
}
