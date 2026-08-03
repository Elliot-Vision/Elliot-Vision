class Security {
  const Security({
    required this.isin,
    required this.name,
    required this.symbol,
    required this.currency,
  });

  final String isin;
  final String name;
  final String symbol;
  final String currency;

  Map<String, dynamic> toJson() => {
        'isin': isin,
        'name': name,
        'symbol': symbol,
        'currency': currency,
      };

  factory Security.fromJson(Map<String, dynamic> json) => Security(
        isin: json['isin'] as String,
        name: json['name'] as String,
        symbol: json['symbol'] as String,
        currency: json['currency'] as String,
      );
}

class PricePoint {
  const PricePoint(this.date, this.priceEur);
  final DateTime date;
  final double priceEur;
}

class SecuritySnapshot {
  const SecuritySnapshot({
    required this.security,
    required this.currentPriceEur,
    required this.allTimeHighEur,
    required this.allTimeLowEur,
    required this.history,
  });

  final Security security;
  final double currentPriceEur;
  final double allTimeHighEur;
  final double allTimeLowEur;
  final List<PricePoint> history;
}
