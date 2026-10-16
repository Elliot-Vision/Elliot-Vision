import 'package:elliott_vision/elliott_vision.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder field(String label) => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label);

Future<AppState> openSheet(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final state = AppState(
      marketData: DemoMarketDataRepository(),
      analysisGateway: RuleBasedAnalysisGateway(),
      store: SharedPreferencesLocalStore());
  await state.initialize();
  await tester.pumpWidget(ElliottVisionApp(state: state));
  await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Position hinzufügen'));
  await tester.pumpAndSettle();
  return state;
}

void main() {
  testWidgets(
      'Position speichern und während der Schließanimation neu zeichnen',
      (tester) async {
    final state = await openSheet(tester);
    await tester.ensureVisible(find.text('Apple Inc.').last);
    await tester.tap(find.text('Apple Inc.').last);
    await tester.ensureVisible(field('Kaufpreis in €'));
    await tester.enterText(field('Kaufpreis in €'), '123,45');
    await tester.enterText(field('Stückzahl'), '2,5');
    tester.testTextInput.hide();
    await tester.ensureVisible(find.text('Position speichern'));
    await tester.tap(find.text('Position speichern'));
    await tester.pump();
    // The route's Future completes before the reverse transition unmounts it.
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(state.holdings, hasLength(1));
    expect(state.holdings.single.purchasePriceEuro, 123.45);
    expect(state.holdings.single.quantity, 2.5);
    expect(find.text('Position speichern'), findsNothing);
    await tester.tap(find.byTooltip('Position hinzufügen'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field('Kaufpreis in €')).controller!.text,
        isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Positiondialog mit fokussierter Suche schließen und erneut öffnen',
      (tester) async {
    final state = await openSheet(tester);
    await tester.enterText(field('Wertpapier suchen'), 'Apple');
    final context = tester.element(field('Wertpapier suchen'));
    Navigator.of(context).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(state.holdings, isEmpty);
    await tester.tap(find.byTooltip('Position hinzufügen'));
    await tester.pumpAndSettle();
    expect(
        tester.widget<TextField>(field('Wertpapier suchen')).controller!.text,
        isEmpty);
    expect(tester.takeException(), isNull);
  });
}
