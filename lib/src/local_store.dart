import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

abstract class LocalStore {
  Future<Set<String>> loadFavorites();
  Future<List<Instrument>> loadInstruments();
  Future<List<Holding>> loadHoldings();
  Future<List<AnalysisResult>> loadHistory();
  Future<void> saveFavorites(Set<String> ids);
  Future<void> saveInstruments(List<Instrument> instruments);
  Future<void> saveHoldings(List<Holding> holdings);
  Future<void> saveHistory(List<AnalysisResult> history);
}

class SharedPreferencesLocalStore implements LocalStore {
  static const _favoritesKey = 'favorites.v1';
  static const _instrumentsKey = 'instruments.v2';
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
  Future<List<Instrument>> loadInstruments() async {
    final preferences = await _preferences;
    final raw = preferences.getString(_instrumentsKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final decoded = jsonDecode(raw) as List<Object?>;
    return decoded
        .map(
          (item) => Instrument.fromJson(
            Map<String, Object?>.from(item! as Map<Object?, Object?>),
          ),
        )
        .toList();
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
  Future<void> saveInstruments(List<Instrument> instruments) async {
    final preferences = await _preferences;
    await preferences.setString(
      _instrumentsKey,
      jsonEncode(instruments.map((instrument) => instrument.toJson()).toList()),
    );
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

/// Dauerhafte, atomar geschriebene JSON-Ablage fuer Depot und Analysen.
///
/// SharedPreferences wird nur noch einmalig als Migrationsquelle verwendet.
/// Vor jedem Austausch der Hauptdatei bleibt eine lesbare Sicherung bestehen.
class DurableLocalStore implements LocalStore {
  DurableLocalStore._({
    required Directory directory,
    required SharedPreferencesLocalStore legacy,
  }) : _directory = directory,
       _legacy = legacy;

  static const schemaVersion = 3;
  static const fileName = 'elliott_vision_data_v3.json';

  final Directory _directory;
  final SharedPreferencesLocalStore _legacy;
  late final File _file = File('${_directory.path}/$fileName');
  late final File _backup = File('${_directory.path}/$fileName.bak');
  Map<String, Object?> _data = <String, Object?>{};
  Future<void> _writeQueue = Future<void>.value();

  static Future<DurableLocalStore> open({
    Directory? directory,
    SharedPreferencesLocalStore? legacy,
  }) async {
    final resolvedDirectory =
        directory ?? await getApplicationSupportDirectory();
    final store = DurableLocalStore._(
      directory: resolvedDirectory,
      legacy: legacy ?? SharedPreferencesLocalStore(),
    );
    await store._initialize();
    return store;
  }

  Future<void> _initialize() async {
    await _directory.create(recursive: true);
    final primary = await _readFile(_file);
    if (primary != null) {
      _data = primary;
      return;
    }
    final backup = await _readFile(_backup);
    if (backup != null) {
      _data = backup;
      if (await _file.exists()) {
        await _file.delete();
      }
      await _scheduleWrite();
      return;
    }
    _data = <String, Object?>{
      'schemaVersion': schemaVersion,
      'favorites': (await _legacy.loadFavorites()).toList()..sort(),
      'instruments': (await _legacy.loadInstruments())
          .map((value) => value.toJson())
          .toList(),
      'holdings': (await _legacy.loadHoldings())
          .map((value) => value.toJson())
          .toList(),
      'history': (await _legacy.loadHistory())
          .map((value) => value.toJson())
          .toList(),
    };
    await _scheduleWrite();
  }

  Future<Map<String, Object?>?> _readFile(File source) async {
    if (!await source.exists()) {
      return null;
    }
    try {
      final decoded = jsonDecode(await source.readAsString());
      if (decoded is! Map<Object?, Object?>) {
        return null;
      }
      return Map<String, Object?>.from(decoded);
    } on Object {
      return null;
    }
  }

  Future<void> _scheduleWrite() {
    final payload = jsonEncode(<String, Object?>{
      ..._data,
      'schemaVersion': schemaVersion,
    });
    _writeQueue = _writeQueue
        .catchError((Object _) {})
        .then((_) => _writeAtomically(payload));
    return _writeQueue;
  }

  Future<void> _writeAtomically(String payload) async {
    final temporary = File('${_file.path}.tmp');
    await temporary.writeAsString(payload, flush: true);
    if (await _file.exists()) {
      if (await _backup.exists()) {
        await _backup.delete();
      }
      await _file.copy(_backup.path);
    }
    try {
      await temporary.rename(_file.path);
    } on FileSystemException {
      if (await _file.exists()) {
        await _file.delete();
      }
      try {
        await temporary.rename(_file.path);
      } on Object {
        if (await _backup.exists() && !(await _file.exists())) {
          await _backup.copy(_file.path);
        }
        rethrow;
      }
    }
  }

  List<Object?> _list(String key) {
    final value = _data[key];
    return value is List<Object?> ? value : const <Object?>[];
  }

  @override
  Future<Set<String>> loadFavorites() async =>
      _list('favorites').whereType<String>().toSet();

  @override
  Future<List<Instrument>> loadInstruments() async => _list('instruments')
      .whereType<Map<Object?, Object?>>()
      .map(
        (item) => Instrument.fromJson(Map<String, Object?>.from(item)),
      )
      .toList();

  @override
  Future<List<Holding>> loadHoldings() async => _list('holdings')
      .whereType<Map<Object?, Object?>>()
      .map((item) => Holding.fromJson(Map<String, Object?>.from(item)))
      .toList();

  @override
  Future<List<AnalysisResult>> loadHistory() async => _list('history')
      .whereType<Map<Object?, Object?>>()
      .map(
        (item) => AnalysisResult.fromJson(Map<String, Object?>.from(item)),
      )
      .toList();

  @override
  Future<void> saveFavorites(Set<String> ids) {
    _data['favorites'] = ids.toList()..sort();
    return _scheduleWrite();
  }

  @override
  Future<void> saveInstruments(List<Instrument> instruments) {
    _data['instruments'] = instruments
        .map((instrument) => instrument.toJson())
        .toList();
    return _scheduleWrite();
  }

  @override
  Future<void> saveHoldings(List<Holding> holdings) {
    _data['holdings'] = holdings
        .map((holding) => holding.toJson())
        .toList();
    return _scheduleWrite();
  }

  @override
  Future<void> saveHistory(List<AnalysisResult> history) {
    _data['history'] = history
        .map((snapshot) => snapshot.toJson())
        .toList();
    return _scheduleWrite();
  }
}
