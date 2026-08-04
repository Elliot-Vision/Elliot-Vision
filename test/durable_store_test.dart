import 'dart:io';

import 'package:elliott_vision/elliott_vision.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('dauerhafte Ablage migriert Altdaten und ueberlebt einen Neustart',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final legacy = SharedPreferencesLocalStore();
    final instrument = DemoMarketDataRepository().byId('aapl');
    await legacy.saveFavorites(<String>{instrument.id});
    await legacy.saveInstruments(<Instrument>[instrument]);

    final directory = await Directory.systemTemp.createTemp(
      'elliott-vision-store-',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    final first = await DurableLocalStore.open(
      directory: directory,
      legacy: legacy,
    );
    expect(await first.loadFavorites(), contains('aapl'));
    expect((await first.loadInstruments()).single.ticker, 'AAPL');

    final holding = Holding(
      id: 'holding-durable',
      instrumentId: instrument.id,
      purchaseDate: DateTime.utc(2026, 8, 4),
      purchasePriceEuro: 180,
      quantity: 2,
    );
    await first.saveHoldings(<Holding>[holding]);

    final reopened = await DurableLocalStore.open(
      directory: directory,
      legacy: legacy,
    );
    expect((await reopened.loadHoldings()).single.id, 'holding-durable');
    expect(
      await File('${directory.path}/${DurableLocalStore.fileName}').exists(),
      isTrue,
    );

    await reopened.saveFavorites(<String>{'aapl', 'uec'});
    final primary = File(
      '${directory.path}/${DurableLocalStore.fileName}',
    );
    await primary.writeAsString('{ungueltige Sicherungsprobe', flush: true);

    final recovered = await DurableLocalStore.open(
      directory: directory,
      legacy: legacy,
    );
    expect((await recovered.loadHoldings()).single.id, 'holding-durable');
    expect(await recovered.loadFavorites(), contains('aapl'));
    expect(await recovered.loadFavorites(), isNot(contains('uec')));
  });
}
