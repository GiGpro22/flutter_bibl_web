import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_exceptions.dart';
import '../core/token_holder.dart';
import '../models/app_user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthNotifier extends ChangeNotifier {
  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kSessionStart = 'auth_session_start';

  final SharedPreferences _prefs;
  final Dio _dio;

  AppUser? _user;
  AuthStatus _status = AuthStatus.unknown;

  AuthNotifier(this._prefs, this._dio) {
    restoreSession();
  }

  AppUser? get user => _user;
  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isKnown => _status != AuthStatus.unknown;

  Future<void> restoreSession() async {
    final access = _prefs.getString(_kAccess);
    final refresh = _prefs.getString(_kRefresh);
    final sessionStart = _prefs.getInt(_kSessionStart) ?? 0;

    // Ограничение общей длительности сессии (например, 2 часа = 7200 сек)
    if (sessionStart > 0 && DateTime.now().millisecondsSinceEpoch - sessionStart > 7200 * 1000) {
      await logout();
      return;
    }

    if (access == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    globalTokens.accessToken = access;
    globalTokens.refreshToken = refresh;

    try {
      final res = await _dio.get('/auth/me');
      _user = AppUser.fromJson(res.data as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
    } on UnauthorizedException {
      if (refresh != null) {
        try {
          final refRes = await _dio.post('/auth/refresh', data: {'refreshToken': refresh});
          final newAccess = refRes.data['accessToken'] as String;
          globalTokens.accessToken = newAccess;
          await _prefs.setString(_kAccess, newAccess);

          final meRes = await _dio.get('/auth/me');
          _user = AppUser.fromJson(meRes.data as Map<String, dynamic>);
          _status = AuthStatus.authenticated;
        } catch (_) {
          await logout();
        }
      } else {
        await logout();
      }
    } catch (_) {
      // Ошибка сети: не сбрасываем токен, помечаем как авторизованный
      _status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    try {
      final res = await _dio.post('/auth/login', data: {
        'email': email.trim(),
        'password': password,
      });

      final data = res.data as Map<String, dynamic>;
      final access = data['accessToken'] as String;
      final refresh = data['refreshToken'] as String;

      globalTokens.accessToken = access;
      globalTokens.refreshToken = refresh;

      await _prefs.setString(_kAccess, access);
      await _prefs.setString(_kRefresh, refresh);
      await _prefs.setInt(_kSessionStart, DateTime.now().millisecondsSinceEpoch);

      _user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
      notifyListeners();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> register(String email, String password, String name) async {
    try {
      final res = await _dio.post('/auth/register', data: {
        'email': email.trim(),
        'password': password,
        'name': name.trim(),
      });

      final data = res.data as Map<String, dynamic>;
      final access = data['accessToken'] as String;
      final refresh = data['refreshToken'] as String;

      globalTokens.accessToken = access;
      globalTokens.refreshToken = refresh;

      await _prefs.setString(_kAccess, access);
      await _prefs.setString(_kRefresh, refresh);
      await _prefs.setInt(_kSessionStart, DateTime.now().millisecondsSinceEpoch);

      _user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
      notifyListeners();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> logout() async {
    _user = null;
    _status = AuthStatus.unauthenticated;
    globalTokens.clear();
    await _prefs.remove(_kAccess);
    await _prefs.remove(_kRefresh);
    await _prefs.remove(_kSessionStart);
    notifyListeners();
  }

  // Метод для Эксперимента №17: подмена роли на клиенте
  void tamperRoleForExperiment(Role fakeRole) {
    if (_user != null) {
      _user = AppUser(id: _user!.id, email: _user!.email, name: _user!.name, role: fakeRole);
      notifyListeners();
    }
  }
}