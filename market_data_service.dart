import 'dart:math';

import '../models/security.dart';

abstract class MarketDataService {
  Future<List<Security>> searchByIsin(String query);
  Future<SecuritySnapshot> loadSnapshot(Security security);
}

class DemoMarketDataService implements MarketDataService {
  static const _securities = <Security>[
    Security(isin: 'US9168961038', name: 'Uranium Energy Corp.', symbol: 'UEC', currency: 'USD'),
    Security(isin: 'US08975B1098', name: 'BigBear.ai Holdings', symbol: 'BBAI', currency: 'USD'),
    Security(isin: 'US1725731079', name: 'Cipher Mining', symbol: 'CIFR', currency: 'USD'),
    Security(isin: 'US9043111072', name: 'Under Armour Class A', symbol: 'UAA', currency: 'USD'),
    Security(isin: 'AU000000DRO2', name: 'DroneShield', symbol: 'DRO', currency: 'AUD'),
    Security(isin: 'CA05156X8504', name: 'Aurora Cannabis', symbol: 'ACB', currency: 'CAD'),
    Security(isin: 'US5533681012', name: 'MP Materials', symbol: 'MP', currency: 'USD'),
  ];

  @override
  Future<List<Security>> searchByIsin(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final normalized = query.trim().toUpperCase();
    if (normalized.isEmpty) return _securities;
    return _securities
        .where((security) =>
            security.isin.contains(normalized) ||
            security.name.toUpperCase().contains(normalized) ||
            security.symbol.contains(normalized))
        .toList();
  }

  @override
  Future<SecuritySnapshot> loadSnapshot(Security security) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    final seed = security.isin.codeUnits.fold<int>(0, (sum, value) => sum + value);
    final random = Random(seed);
    final start = 7.0 + random.nextDouble() * 28;
    var price = start;
    final history = <PricePoint>[];
    for (var i = 0; i < 160; i++) {
      final cycle = sin(i / 8.0) * 0.025 + sin(i / 21.0) * 0.018;
      final drift = 0.0015 + (seed % 7 - 3) * 0.00025;
      final noise = (random.nextDouble() - 0.5) * 0.035;
      price = max(0.5, price * (1 + drift + cycle + noise));
      history.add(PricePoint(
        DateTime.now().subtract(Duration(days: 159 - i)),
        price,
      ));
    }
    final values = history.map((point) => point.priceEur);
    return SecuritySnapshot(
      security: security,
      currentPriceEur: history.last.priceEur,
      allTimeHighEur: values.reduce(max),
      allTimeLowEur: values.reduce(min),
      history: history,
    );
  }
}
