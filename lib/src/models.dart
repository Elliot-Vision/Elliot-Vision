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

enum AssetType { stock, etf, crypto }

extension AssetTypeText on AssetType {
  String get label {
    switch (this) {
      case AssetType.stock:
        return 'Aktie';
      case AssetType.etf:
        return 'ETF';
      case AssetType.crypto:
        return 'Krypto';
    }
  }

  String get tradingHours {
    switch (this) {
      case AssetType.crypto:
        return '24/7 handelbar';
      case AssetType.stock:
      case AssetType.etf:
        return 'Börsenzeiten des Handelsplatzes';
    }
  }
}

enum ChartTimeframe {
  oneDay,
  fiveDays,
  oneMonth,
  threeMonths,
  oneYear,
  fiveYears,
  maximum,
}

extension ChartTimeframeText on ChartTimeframe {
  String get label {
    switch (this) {
      case ChartTimeframe.oneDay:
        return '1 Tag';
      case ChartTimeframe.fiveDays:
        return '5 Tage';
      case ChartTimeframe.oneMonth:
        return '1 Monat';
      case ChartTimeframe.threeMonths:
        return '3 Monate';
      case ChartTimeframe.oneYear:
        return '1 Jahr';
      case ChartTimeframe.fiveYears:
        return '5 Jahre';
      case ChartTimeframe.maximum:
        return 'Max';
    }
  }

  String get range {
    switch (this) {
      case ChartTimeframe.oneDay:
        return '1d';
      case ChartTimeframe.fiveDays:
        return '5d';
      case ChartTimeframe.oneMonth:
        return '1mo';
      case ChartTimeframe.threeMonths:
        return '3mo';
      case ChartTimeframe.oneYear:
        return '1y';
      case ChartTimeframe.fiveYears:
        return '5y';
      case ChartTimeframe.maximum:
        return 'max';
    }
  }

  String get interval {
    switch (this) {
      case ChartTimeframe.oneDay:
        return '5m';
      case ChartTimeframe.fiveDays:
        return '30m';
      case ChartTimeframe.oneMonth:
        return '1d';
      case ChartTimeframe.threeMonths:
        return '1d';
      case ChartTimeframe.oneYear:
        return '1wk';
      case ChartTimeframe.fiveYears:
        return '1mo';
      case ChartTimeframe.maximum:
        return '1mo';
    }
  }
}

class PricePoint {
  const PricePoint({required this.timestamp, required this.euro});

  final DateTime timestamp;
  final double euro;

  Map<String, Object?> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'euro': euro,
  };

  factory PricePoint.fromJson(Map<String, Object?> json) => PricePoint(
    timestamp: DateTime.parse(json['timestamp']! as String),
    euro: (json['euro']! as num).toDouble(),
  );
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
    this.historyTimestamps = const <DateTime>[],
    this.venueSymbols = const <String, String>{},
    this.assetType = AssetType.stock,
    this.timeframe = ChartTimeframe.maximum,
    this.dataSource = 'Lokaler Datenstand',
    this.dataDelay = 'Gespeicherter Kursstand',
    this.isLive = false,
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
  final List<DateTime> historyTimestamps;
  /// Vom Datenanbieter bestaetigte Zuordnung Handelsplatz -> Kurssymbol.
  /// Nur Handelsplaetze mit einem Eintrag werden in der Auswahl angeboten.
  final Map<String, String> venueSymbols;
  final AssetType assetType;
  final ChartTimeframe timeframe;
  final String dataSource;
  final String dataDelay;
  final bool isLive;

  String get selectedSymbol => venueSymbols[defaultVenue] ?? ticker;

  double get periodChangePercent {
    if (historyEuro.length < 2 || historyEuro.first == 0) {
      return 0;
    }
    return ((historyEuro.last / historyEuro.first) - 1) * 100;
  }

  double get distanceToAthPercent => athEuro <= 0
      ? 0
      : ((euroPrice / athEuro) - 1) * 100;

  double get distanceToAtlPercent => atlEuro <= 0
      ? 0
      : ((euroPrice / atlEuro) - 1) * 100;

  List<PricePoint> get pricePoints {
    final timestamps = normalizedHistoryTimestamps;
    return List<PricePoint>.generate(
      historyEuro.length,
      (index) => PricePoint(
        timestamp: timestamps[index],
        euro: historyEuro[index],
      ),
      growable: false,
    );
  }

  List<DateTime> get normalizedHistoryTimestamps {
    if (historyTimestamps.length == historyEuro.length) {
      return historyTimestamps;
    }
    final step = timeframe == ChartTimeframe.oneDay
        ? const Duration(minutes: 5)
        : timeframe == ChartTimeframe.fiveDays
        ? const Duration(minutes: 30)
        : timeframe == ChartTimeframe.oneMonth ||
              timeframe == ChartTimeframe.threeMonths
        ? const Duration(days: 1)
        : timeframe == ChartTimeframe.oneYear
        ? const Duration(days: 7)
        : const Duration(days: 30);
    return List<DateTime>.generate(
      historyEuro.length,
      (index) => dataTimestamp.subtract(
        Duration(
          microseconds:
              step.inMicroseconds * (historyEuro.length - index - 1),
        ),
      ),
      growable: false,
    );
  }

  Instrument copyWith({
    String? name,
    String? ticker,
    String? isin,
    String? defaultVenue,
    List<String>? venues,
    Map<String, String>? venueSymbols,
    String? originalCurrency,
    double? originalPrice,
    double? euroPrice,
    double? fxRate,
    double? athEuro,
    double? atlEuro,
    DateTime? dataTimestamp,
    List<double>? historyEuro,
    List<DateTime>? historyTimestamps,
    ChartTimeframe? timeframe,
    String? dataSource,
    String? dataDelay,
    bool? isLive,
  }) => Instrument(
    id: id,
    name: name ?? this.name,
    ticker: ticker ?? this.ticker,
    isin: isin ?? this.isin,
    defaultVenue: defaultVenue ?? this.defaultVenue,
    venues: venues ?? this.venues,
    venueSymbols: venueSymbols ?? this.venueSymbols,
    originalCurrency: originalCurrency ?? this.originalCurrency,
    originalPrice: originalPrice ?? this.originalPrice,
    euroPrice: euroPrice ?? this.euroPrice,
    fxRate: fxRate ?? this.fxRate,
    athEuro: athEuro ?? this.athEuro,
    atlEuro: atlEuro ?? this.atlEuro,
    dataTimestamp: dataTimestamp ?? this.dataTimestamp,
    historyEuro: historyEuro ?? this.historyEuro,
    historyTimestamps: historyTimestamps ?? this.historyTimestamps,
    assetType: assetType,
    timeframe: timeframe ?? this.timeframe,
    dataSource: dataSource ?? this.dataSource,
    dataDelay: dataDelay ?? this.dataDelay,
    isLive: isLive ?? this.isLive,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'ticker': ticker,
    'isin': isin,
    'defaultVenue': defaultVenue,
    'venues': venues,
    'originalCurrency': originalCurrency,
    'originalPrice': originalPrice,
    'euroPrice': euroPrice,
    'fxRate': fxRate,
    'athEuro': athEuro,
    'atlEuro': atlEuro,
    'dataTimestamp': dataTimestamp.toIso8601String(),
    'historyEuro': historyEuro,
    'historyTimestamps': historyTimestamps
        .map((value) => value.toIso8601String())
        .toList(),
    'venueSymbols': venueSymbols,
    'assetType': assetType.name,
    'timeframe': timeframe.name,
    'dataSource': dataSource,
    'dataDelay': dataDelay,
    'isLive': isLive,
  };

  factory Instrument.fromJson(Map<String, Object?> json) {
    final rawTimestamps = json['historyTimestamps'];
    final rawVenueSymbols = json['venueSymbols'];
    return Instrument(
      id: json['id']! as String,
      name: json['name']! as String,
      ticker: json['ticker']! as String,
      isin: (json['isin'] as String?) ?? 'Nicht verfügbar',
      defaultVenue: json['defaultVenue']! as String,
      venues: (json['venues']! as List<Object?>)
          .map((venue) => venue! as String)
          .toList(),
      originalCurrency: json['originalCurrency']! as String,
      originalPrice: (json['originalPrice']! as num).toDouble(),
      euroPrice: (json['euroPrice']! as num).toDouble(),
      fxRate: (json['fxRate']! as num).toDouble(),
      athEuro: (json['athEuro']! as num).toDouble(),
      atlEuro: (json['atlEuro']! as num).toDouble(),
      dataTimestamp: DateTime.parse(json['dataTimestamp']! as String),
      historyEuro: (json['historyEuro']! as List<Object?>)
          .map((value) => (value! as num).toDouble())
          .toList(),
      historyTimestamps: rawTimestamps is List<Object?>
          ? rawTimestamps
                .whereType<String>()
                .map(DateTime.parse)
                .toList()
          : const <DateTime>[],
      venueSymbols: rawVenueSymbols is Map<Object?, Object?>
          ? rawVenueSymbols.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : const <String, String>{},
      assetType: AssetType.values.byName(
        (json['assetType'] as String?) ?? AssetType.stock.name,
      ),
      timeframe: ChartTimeframe.values.byName(
        (json['timeframe'] as String?) ?? ChartTimeframe.maximum.name,
      ),
      dataSource: (json['dataSource'] as String?) ?? 'Gespeicherter Datenstand',
      dataDelay: (json['dataDelay'] as String?) ?? 'Gespeicherter Kursstand',
      isLive: (json['isLive'] as bool?) ?? false,
    );
  }
}

class WaveMarker {
  const WaveMarker({
    required this.historyIndex,
    required this.priceEuro,
    required this.label,
  });

  final int historyIndex;
  final double priceEuro;
  final String label;

  Map<String, Object?> toJson() => {
    'historyIndex': historyIndex,
    'priceEuro': priceEuro,
    'label': label,
  };

  factory WaveMarker.fromJson(Map<String, Object?> json) => WaveMarker(
    historyIndex: (json['historyIndex']! as num).toInt(),
    priceEuro: (json['priceEuro']! as num).toDouble(),
    label: json['label']! as String,
  );
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
    this.countMethod = 'Regelbasierte Zählung',
    this.entryLowEuro = 0,
    this.entryHighEuro = 0,
    this.exitLowEuro = 0,
    this.exitHighEuro = 0,
    this.stopLossEuro = 0,
    this.probabilityFactors = const <String>[],
    this.waveLabels = const <String>['1', '2', '3', '4', '5', 'A', 'C'],
    this.waveMarkers = const <WaveMarker>[],
    this.ruleChecks = const <String>[],
    this.rulesSatisfied = 0,
    this.rulesTotal = 0,
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
  final String countMethod;
  final double entryLowEuro;
  final double entryHighEuro;
  final double exitLowEuro;
  final double exitHighEuro;
  final double stopLossEuro;
  final List<String> probabilityFactors;
  final List<String> waveLabels;
  final List<WaveMarker> waveMarkers;
  final List<String> ruleChecks;
  final int rulesSatisfied;
  final int rulesTotal;

  bool get passesAllHardRules =>
      rulesTotal > 0 && rulesSatisfied == rulesTotal;

  double get riskRewardRatio {
    final entry = (entryLowEuro + entryHighEuro) / 2;
    final risk = (entry - stopLossEuro).abs();
    final reward = (targetEuro - entry).abs();
    return risk <= 0 ? 0 : reward / risk;
  }

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
    'countMethod': countMethod,
    'entryLowEuro': entryLowEuro,
    'entryHighEuro': entryHighEuro,
    'exitLowEuro': exitLowEuro,
    'exitHighEuro': exitHighEuro,
    'stopLossEuro': stopLossEuro,
    'probabilityFactors': probabilityFactors,
    'waveLabels': waveLabels,
    'waveMarkers': waveMarkers.map((marker) => marker.toJson()).toList(),
    'ruleChecks': ruleChecks,
    'rulesSatisfied': rulesSatisfied,
    'rulesTotal': rulesTotal,
  };

  factory AnalysisScenario.fromJson(Map<String, Object?> json) {
    final target = (json['targetEuro']! as num).toDouble();
    final invalidation = (json['invalidationEuro']! as num).toDouble();
    final projection = (json['projectionEuro']! as List<Object?>)
        .map((value) => (value! as num).toDouble())
        .toList();
    final start = projection.isEmpty ? target : projection.first;
    return AnalysisScenario(
      id: json['id']! as String,
      title: json['title']! as String,
      kind: ScenarioKind.values.byName(json['kind']! as String),
      probability: (json['probability']! as num).toInt(),
      score: (json['score']! as num).toInt(),
      targetEuro: target,
      invalidationEuro: invalidation,
      projectionEuro: projection,
      thesis: json['thesis']! as String,
      countMethod:
          (json['countMethod'] as String?) ?? 'Gespeicherte Beta-Zählung',
      entryLowEuro:
          (json['entryLowEuro'] as num?)?.toDouble() ?? start * 0.97,
      entryHighEuro:
          (json['entryHighEuro'] as num?)?.toDouble() ?? start * 1.01,
      exitLowEuro: (json['exitLowEuro'] as num?)?.toDouble() ?? target * 0.97,
      exitHighEuro: (json['exitHighEuro'] as num?)?.toDouble() ?? target * 1.03,
      stopLossEuro:
          (json['stopLossEuro'] as num?)?.toDouble() ?? invalidation,
      probabilityFactors: (json['probabilityFactors'] as List<Object?>?)
              ?.whereType<String>()
              .toList() ??
          const <String>['Historische Beta-Bewertung'],
      waveLabels: (json['waveLabels'] as List<Object?>?)
              ?.whereType<String>()
              .toList() ??
          const <String>['1', '2', '3', '4', '5', 'A', 'C'],
      waveMarkers: (json['waveMarkers'] as List<Object?>?)
              ?.whereType<Map<Object?, Object?>>()
              .map(
                (marker) => WaveMarker.fromJson(
                  Map<String, Object?>.from(marker),
                ),
              )
              .toList() ??
          const <WaveMarker>[],
      ruleChecks: (json['ruleChecks'] as List<Object?>?)
              ?.whereType<String>()
              .toList() ??
          const <String>[],
      rulesSatisfied: (json['rulesSatisfied'] as num?)?.toInt() ?? 0,
      rulesTotal: (json['rulesTotal'] as num?)?.toInt() ?? 0,
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
    this.timeframe = ChartTimeframe.maximum,
    this.instrumentSnapshot,
    this.methodology =
        'Wendepunkte, Trend, Momentum, Volatilität und Fibonacci-Zonen',
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
  final ChartTimeframe timeframe;
  final Instrument? instrumentSnapshot;
  final String methodology;

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
    'timeframe': timeframe.name,
    'instrumentSnapshot': instrumentSnapshot?.toJson(),
    'methodology': methodology,
  };

  factory AnalysisResult.fromJson(Map<String, Object?> json) {
    final rawSnapshot = json['instrumentSnapshot'];
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
      timeframe: ChartTimeframe.values.byName(
        (json['timeframe'] as String?) ?? ChartTimeframe.maximum.name,
      ),
      instrumentSnapshot: rawSnapshot is Map<Object?, Object?>
          ? Instrument.fromJson(Map<String, Object?>.from(rawSnapshot))
          : null,
      methodology:
          (json['methodology'] as String?) ?? 'Historische Beta-Methodik',
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
