enum ScenarioKind { bullish, neutral, bearish }

extension ScenarioKindText on ScenarioKind {
  String get label {
    switch (this) {
      case ScenarioKind.bullish:
        return 'Bullisch';
      case ScenarioKind.neutral:
        return 'Neutral';
      case ScenarioKind.bearish:
        return 'Bärisch';
    }
  }
}

class Instrument {
  const Instrument({
    required this.id,
    required this.name,
    required this.ticker,
    required this.isin,
    required this.defaultVenue,
    required this.venues,
    required this.originalCurrency,
    required this.originalPrice,
    required this.euroPrice,
    required this.fxRate,
    required this.athEuro,
    required this.atlEuro,
    required this.dataTimestamp,
    required this.historyEuro,
  });

  final String id;
  final String name;
  final String ticker;
  final String isin;
  final String defaultVenue;
  final List<String> venues;
  final String originalCurrency;
  final double originalPrice;
  final double euroPrice;
  final double fxRate;
  final double athEuro;
  final double atlEuro;
  final DateTime dataTimestamp;
  final List<double> historyEuro;

  double get periodChangePercent {
    if (historyEuro.length < 2 || historyEuro.first == 0) {
      return 0;
    }
    return ((historyEuro.last / historyEuro.first) - 1) * 100;
  }
}

class AnalysisScenario {
  const AnalysisScenario({
    required this.id,
    required this.title,
    required this.kind,
    required this.probability,
    required this.score,
    required this.targetEuro,
    required this.invalidationEuro,
    required this.projectionEuro,
    required this.thesis,
  });

  final String id;
  final String title;
  final ScenarioKind kind;
  final int probability;
  final int score;
  final double targetEuro;
  final double invalidationEuro;
  final List<double> projectionEuro;
  final String thesis;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'kind': kind.name,
    'probability': probability,
    'score': score,
    'targetEuro': targetEuro,
    'invalidationEuro': invalidationEuro,
    'projectionEuro': projectionEuro,
    'thesis': thesis,
  };

  factory AnalysisScenario.fromJson(Map<String, Object?> json) {
    return AnalysisScenario(
      id: json['id']! as String,
      title: json['title']! as String,
      kind: ScenarioKind.values.byName(json['kind']! as String),
      probability: (json['probability']! as num).toInt(),
      score: (json['score']! as num).toInt(),
      targetEuro: (json['targetEuro']! as num).toDouble(),
      invalidationEuro: (json['invalidationEuro']! as num).toDouble(),
      projectionEuro: (json['projectionEuro']! as List<Object?>)
          .map((value) => (value! as num).toDouble())
          .toList(),
      thesis: json['thesis']! as String,
    );
  }
}

class AnalysisResult {
  const AnalysisResult({
    required this.id,
    required this.instrumentId,
    required this.createdAt,
    required this.dataTimestamp,
    required this.overallScore,
    required this.primaryScenarioId,
    required this.scenarios,
    required this.engineVersion,
    required this.explanationModel,
    required this.promptVersion,
  });

  final String id;
  final String instrumentId;
  final DateTime createdAt;
  final DateTime dataTimestamp;
  final int overallScore;
  final String primaryScenarioId;
  final List<AnalysisScenario> scenarios;
  final String engineVersion;
  final String explanationModel;
  final String promptVersion;

  AnalysisScenario get primaryScenario =>
      scenarios.firstWhere((scenario) => scenario.id == primaryScenarioId);

  Map<String, Object?> toJson() => {
    'id': id,
    'instrumentId': instrumentId,
    'createdAt': createdAt.toIso8601String(),
    'dataTimestamp': dataTimestamp.toIso8601String(),
    'overallScore': overallScore,
    'primaryScenarioId': primaryScenarioId,
    'scenarios': scenarios.map((scenario) => scenario.toJson()).toList(),
    'engineVersion': engineVersion,
    'explanationModel': explanationModel,
    'promptVersion': promptVersion,
  };

  factory AnalysisResult.fromJson(Map<String, Object?> json) {
    return AnalysisResult(
      id: json['id']! as String,
      instrumentId: json['instrumentId']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String),
      dataTimestamp: DateTime.parse(json['dataTimestamp']! as String),
      overallScore: (json['overallScore']! as num).toInt(),
      primaryScenarioId: json['primaryScenarioId']! as String,
      scenarios: (json['scenarios']! as List<Object?>)
          .map(
            (scenario) => AnalysisScenario.fromJson(
              Map<String, Object?>.from(scenario! as Map<Object?, Object?>),
            ),
          )
          .toList(),
      engineVersion: json['engineVersion']! as String,
      explanationModel: json['explanationModel']! as String,
      promptVersion: json['promptVersion']! as String,
    );
  }
}

class Holding {
  const Holding({
    required this.id,
    required this.instrumentId,
    required this.purchaseDate,
    required this.purchasePriceEuro,
    required this.quantity,
    this.note = '',
  });

  final String id;
  final String instrumentId;
  final DateTime purchaseDate;
  final double purchasePriceEuro;
  final double quantity;
  final String note;

  double get investedEuro => purchasePriceEuro * quantity;

  Map<String, Object?> toJson() => {
    'id': id,
    'instrumentId': instrumentId,
    'purchaseDate': purchaseDate.toIso8601String(),
    'purchasePriceEuro': purchasePriceEuro,
    'quantity': quantity,
    'note': note,
  };

  factory Holding.fromJson(Map<String, Object?> json) {
    return Holding(
      id: json['id']! as String,
      instrumentId: json['instrumentId']! as String,
      purchaseDate: DateTime.parse(json['purchaseDate']! as String),
      purchasePriceEuro: (json['purchasePriceEuro']! as num).toDouble(),
      quantity: (json['quantity']! as num).toDouble(),
      note: (json['note'] as String?) ?? '',
    );
  }
}
