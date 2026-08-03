class PortfolioPosition {
  const PortfolioPosition({
    required this.isin,
    required this.name,
    required this.purchaseDate,
    required this.purchasePriceEur,
    required this.quantity,
  });

  final String isin;
  final String name;
  final DateTime purchaseDate;
  final double purchasePriceEur;
  final double quantity;

  Map<String, dynamic> toJson() => {
        'isin': isin,
        'name': name,
        'purchaseDate': purchaseDate.toIso8601String(),
        'purchasePriceEur': purchasePriceEur,
        'quantity': quantity,
      };

  factory PortfolioPosition.fromJson(Map<String, dynamic> json) => PortfolioPosition(
        isin: json['isin'] as String,
        name: json['name'] as String,
        purchaseDate: DateTime.parse(json['purchaseDate'] as String),
        purchasePriceEur: (json['purchasePriceEur'] as num).toDouble(),
        quantity: (json['quantity'] as num).toDouble(),
      );
}
