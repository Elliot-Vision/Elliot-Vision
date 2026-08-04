import 'package:elliott_vision/elliott_vision.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Instrument migriert alte Daten und erzeugt Zeitachsen', () {
    final instrument = Instrument.fromJson(<String, Object?>{
      'id': 'legacy',
      'name': 'Legacy AG',
      'ticker': 'LEG',
      'isin': 'DE0000000001',
      'defaultVenue': 'Xetra',
      'venues': <Object?>['Xetra'],
      'originalCurrency': 'EUR',
      'originalPrice': 12.0,
      'euroPrice': 12.0,
      'fxRate': 1.0,
      'athEuro': 15.0,
      'atlEuro': 5.0,
      'dataTimestamp': '2026-08-04T12:00:00Z',
      'historyEuro': <Object?>[10.0, 11.0, 12.0],
      'venueSymbols': <String, Object?>{'Xetra': 'LEG.DE'},
      'isLive': false,
    });

    expect(instrument.assetType, AssetType.stock);
    expect(instrument.pricePoints, hasLength(3));
    expect(instrument.pricePoints.last.euro, 12.0);
    expect(instrument.selectedSymbol, 'LEG.DE');
  });

  test('Snapshot speichert Instrument, Zonen und Analyseversion', () {
    final repository = DemoMarketDataRepository();
    final result = RuleBasedAnalysisGateway().analyze(
      repository.byId('aapl'),
      now: DateTime.utc(2026, 8, 4),
    );
    final restored = AnalysisResult.fromJson(result.toJson());

    expect(restored.instrumentSnapshot?.ticker, 'AAPL');
    expect(restored.primaryScenario.entryLowEuro, greaterThan(0));
    expect(restored.engineVersion, result.engineVersion);
    expect(restored.primaryScenario.ruleChecks, isNotEmpty);
    expect(
      restored.primaryScenario.waveMarkers.length,
      result.primaryScenario.waveMarkers.length,
    );
  });
}
