import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

abstract class LocalStore {
  Future<Set<String>> loadFavorites();
  Future<List<Holding>> loadHoldings();
  Future<List<AnalysisResult>> loadHistory();
  Future<void> saveFavorites(Set<String> ids);
  Future<void> saveHoldings(List<Holding> holdings);
  Future<void> saveHistory(List<AnalysisResult> history);
}

class SharedPreferencesLocalStore implements LocalStore {
  static const _favoritesKey = 'favorites.v1';
  static const _holdingsKey = 'holdings.v1';
  static const _historyKey = 'history.v1';

  Future<SharedPreferences> get _preferences => SharedPreferences.getInstance();

  @override
  Future<Set<String>> loadFavorites() async {
    final preferences = await _preferences;
    return (preferences.getStringList(_favoritesKey) ?? const <String>[])
        .toSet();
  }

  @override
  Future<List<Holding>> loadHoldings() async {
    final preferences = await _preferences;
    final raw = preferences.getString(_holdingsKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final decoded = jsonDecode(raw) as List<Object?>;
    return decoded
        .map(
          (item) => Holding.fromJson(
            Map<String, Object?>.from(item! as Map<Object?, Object?>),
          ),
        )
        .toList();
  }

  @override
  Future<List<AnalysisResult>> loadHistory() async {
    final preferences = await _preferences;
    final raw = preferences.getString(_historyKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final decoded = jsonDecode(raw) as List<Object?>;
    return decoded
        .map(
          (item) => AnalysisResult.fromJson(
            Map<String, Object?>.from(item! as Map<Object?, Object?>),
          ),
        )
        .toList();
  }

  @override
  Future<void> saveFavorites(Set<String> ids) async {
    final preferences = await _preferences;
    await preferences.setStringList(_favoritesKey, ids.toList()..sort());
  }

  @override
  Future<void> saveHoldings(List<Holding> holdings) async {
    final preferences = await _preferences;
    await preferences.setString(
      _holdingsKey,
      jsonEncode(holdings.map((holding) => holding.toJson()).toList()),
    );
  }

  @override
  Future<void> saveHistory(List<AnalysisResult> history) async {
    final preferences = await _preferences;
    await preferences.setString(
      _historyKey,
      jsonEncode(history.map((snapshot) => snapshot.toJson()).toList()),
    );
  }
}
