import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Very small TTL cache backed by SharedPreferences.
///
/// - **Memory**: fast for the current app session
/// - **Disk**: survives navigation and reduces cold-start flicker after login
/// - **TTL**: prevents showing data that's too old
class AppCache {
  AppCache._();
  static final AppCache instance = AppCache._();

  static const String _prefix = 'app_cache:';

  final Map<String, _CacheEntry> _mem = <String, _CacheEntry>{};

  /// Reads cached JSON for [key]. Returns null if missing/expired/corrupt.
  Future<Map<String, dynamic>?> getJson(
    String key, {
    required Duration ttl,
    bool acceptExpired = false,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final mem = _mem[key];
    if (mem != null) {
      final ageMs = nowMs - mem.savedAtMs;
      final expired = ageMs > ttl.inMilliseconds;
      if (!expired || acceptExpired) return mem.json;
      _mem.remove(key);
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$key');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final m = Map<String, dynamic>.from(decoded as Map);
      final savedAtMs = (m['savedAtMs'] is num) ? (m['savedAtMs'] as num).toInt() : 0;
      final payload = m['payload'];
      if (savedAtMs <= 0 || payload is! Map) return null;
      final payloadMap = Map<String, dynamic>.from(payload as Map);
      final ageMs = nowMs - savedAtMs;
      final expired = ageMs > ttl.inMilliseconds;
      if (expired && !acceptExpired) return null;
      final entry = _CacheEntry(savedAtMs: savedAtMs, json: payloadMap);
      _mem[key] = entry;
      return payloadMap;
    } catch (_) {
      return null;
    }
  }

  /// Writes JSON for [key].
  Future<void> setJson(String key, Map<String, dynamic> payload) async {
    final savedAtMs = DateTime.now().millisecondsSinceEpoch;
    _mem[key] = _CacheEntry(savedAtMs: savedAtMs, json: payload);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefix$key',
      jsonEncode(<String, dynamic>{'savedAtMs': savedAtMs, 'payload': payload}),
    );
  }

  /// Removes a cached entry.
  Future<void> remove(String key) async {
    _mem.remove(key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$key');
  }

  /// Clears all cached entries written by this class.
  Future<void> clearAll() async {
    _mem.clear();
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}

class _CacheEntry {
  final int savedAtMs;
  final Map<String, dynamic> json;

  const _CacheEntry({required this.savedAtMs, required this.json});
}

