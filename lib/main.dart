import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/app_state.dart';
import 'src/analysis_engine.dart';
import 'src/demo_data.dart';
import 'src/live_market_data.dart';
import 'src/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final state = AppState(
    marketData: LiveMarketDataRepository(
      seed: DemoMarketDataRepository().instruments,
    ),
    analysisGateway: RuleBasedAnalysisGateway(),
    store: await DurableLocalStore.open(),
  );
  await state.initialize();

  runApp(ElliottVisionApp(state: state));
}
