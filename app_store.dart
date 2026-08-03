import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/portfolio_position.dart';
import '../models/security.dart';

class AppStore extends ChangeNotifier {
  static const _favoritesKey = 'favorites';
  static const _positionsKey = 'positions';

  final List<Security> _favorites = [];
  final List<PortfolioPosition> _positions = [];

  List<Security> get favorites => List.unmodifiable(_favorites);
  List<PortfolioPosition> get positions => List.unmodifiable(_positions);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getStringList(_favoritesKey) ?? const [];
    final positionsJson = prefs.getStringList(_positionsKey) ?? const [];
    _favorites
      ..clear()
      ..addAll(favoritesJson.map((item) =>
          Security.fromJson(jsonDecode(item) as Map<String, dynamic>)));
    _positions
      ..clear()
      ..addAll(positionsJson.map((item) => PortfolioPosition.fromJson(
          jsonDecode(item) as Map<String, dynamic>)));
  }

  bool isFavorite(String isin) => _favorites.any((item) => item.isin == isin);

  Future<void> toggleFavorite(Security security) async {
    if (isFavorite(security.isin)) {
      _favorites.removeWhere((item) => item.isin == security.isin);
    } else {
      _favorites.add(security);
    }
    await _save();
    notifyListeners();
  }

  Future<void> addPosition(PortfolioPosition position) async {
    _positions.add(position);
    await _save();
    notifyListeners();
  }

  Future<void> removePosition(PortfolioPosition position) async {
    _positions.remove(position);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _favoritesKey,
      _favorites.map((item) => jsonEncode(item.toJson())).toList(),
    );
    await prefs.setStringList(
      _positionsKey,
      _positions.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }
}
