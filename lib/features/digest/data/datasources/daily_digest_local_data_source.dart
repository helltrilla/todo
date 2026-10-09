import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/features/digest/domain/entities/daily_digest.dart';

abstract interface class IDailyDigestLocalDataSource {
  Future<DailyDigest?> getCachedDigest(String dateKey);
  Future<void> saveCachedDigest(String dateKey, DailyDigest digest);
  Future<bool> isDismissed(String dateKey);
  Future<void> setDismissed(String dateKey, bool dismissed);
}

class DailyDigestLocalDataSource implements IDailyDigestLocalDataSource {
  final SharedPreferences _prefs;

  const DailyDigestLocalDataSource(this._prefs);

  static String _digestKey(String dateKey) => 'cached_daily_digest_$dateKey';
  static String _dismissKey(String dateKey) => 'dismissed_daily_digest_$dateKey';

  @override
  Future<DailyDigest?> getCachedDigest(String dateKey) async {
    final raw = _prefs.getString(_digestKey(dateKey));
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return DailyDigest.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveCachedDigest(String dateKey, DailyDigest digest) async {
    final raw = jsonEncode(digest.toMap());
    await _prefs.setString(_digestKey(dateKey), raw);
  }

  @override
  Future<bool> isDismissed(String dateKey) async {
    return _prefs.getBool(_dismissKey(dateKey)) ?? false;
  }

  @override
  Future<void> setDismissed(String dateKey, bool dismissed) async {
    await _prefs.setBool(_dismissKey(dateKey), dismissed);
  }
}
