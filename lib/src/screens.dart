import 'package:flutter/material.dart';

import 'app.dart';
import 'app_state.dart';
import 'chart.dart';
import 'formatters.dart';
import 'models.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _index = 0;

  static const _screens = <Widget>[
    DiscoverScreen(),
    FavoritesScreen(),
    PortfolioScreen(),
    HistoryScreen(),
    LearnScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.search_rounded, color: AppPalette.ink),
            label: 'Entdecken',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_border_rounded),
            selectedIcon: Icon(Icons.star_rounded, color: AppPalette.ink),
            label: 'Favoriten',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(
              Icons.account_balance_wallet,
              color: AppPalette.ink,
            ),
            label: 'Depot',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_rounded, color: AppPalette.ink),
            label: 'Historie',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school_rounded, color: AppPalette.ink),
            label: 'Wissen',
          ),
        ],
      ),
    );
  }
}

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _searchController = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final results = state.search(_query);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          const _BrandHeader(),
          const SizedBox(height: 28),
          Text(
            'Szenarien statt\nScheinsicherheit.',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppPalette.ink,
              fontWeight: FontWeight.w800,
              height: 1.02,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Finde ein Wertpapier und vergleiche mehrere plausible '
            'Elliott-Wellen-Zählungen transparent.',
            style: TextStyle(
              color: AppPalette.muted,
              fontSize: 16,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'ISIN, Name oder Ticker',
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Suche leeren',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          const _DemoNotice(),
          const SizedBox(height: 28),
          _SectionTitle(
            title: _query.isEmpty ? 'Beispielwerte' : 'Suchergebnisse',
            trailing: '${results.length}',
          ),
          const SizedBox(height: 12),
          if (results.isEmpty)
            const _EmptyState(
              icon: Icons.manage_search_rounded,
              title: 'Kein Wertpapier gefunden',
              text:
                  'Prüfe die ISIN oder suche nach Name beziehungsweise Ticker.',
            )
          else
            ...results.map(
              (instrument) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InstrumentCard(instrument: instrument),
              ),
            ),
          if (state.history.isNotEmpty) ...[
            const SizedBox(height: 22),
            const _SectionTitle(title: 'Zuletzt analysiert'),
            const SizedBox(height: 12),
            ...state.history.take(2).map((snapshot) {
              final instrument = state.marketData.byId(snapshot.instrumentId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _HistoryTile(snapshot: snapshot, instrument: instrument),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final favorites = state.favoriteInstruments;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          const _ScreenHeader(
            eyebrow: 'WATCHLIST',
            title: 'Favoriten',
            subtitle: 'Deine gespeicherten Wertpapiere auf einen Blick.',
          ),
          const SizedBox(height: 24),
          if (favorites.isEmpty)
            const _EmptyState(
              icon: Icons.star_border_rounded,
              title: 'Noch keine Favoriten',
              text:
                  'Tippe in einer Analyse auf den Stern, um ein Wertpapier zu speichern.',
            )
          else
            ...favorites.map(
              (instrument) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InstrumentCard(instrument: instrument),
              ),
            ),
        ],
      ),
    );
  }
}

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final holdings = state.holdings;
    final invested = holdings.fold<double>(
      0,
      (sum, holding) => sum + holding.investedEuro,
    );
    final currentValue = holdings.fold<double>(0, (sum, holding) {
      final instrument = state.marketData.byId(holding.instrumentId);
      return sum + instrument.euroPrice * holding.quantity;
    });
    final result = currentValue - invested;
    final resultPercent = invested == 0 ? 0.0 : result / invested * 100;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          _ScreenHeader(
            eyebrow: 'MEIN DEPOT',
            title: 'Positionen',
            subtitle: 'Kaufdaten lokal speichern und Entwicklung vergleichen.',
            action: IconButton.filled(
              tooltip: 'Position hinzufügen',
              onPressed: () => _showAddHoldingSheet(context, state),
              style: IconButton.styleFrom(
                backgroundColor: AppPalette.ink,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add_rounded),
            ),
          ),
          const SizedBox(height: 24),
          _PortfolioSummary(
            currentValue: currentValue,
            invested: invested,
            result: result,
            resultPercent: resultPercent,
          ),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'Positionen'),
          const SizedBox(height: 12),
          if (holdings.isEmpty)
            _EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Dein Depot ist leer',
              text: 'Füge Kaufpreis, Stückzahl und Kaufdatum hinzu.',
              actionLabel: 'Erste Position hinzufügen',
              onAction: () => _showAddHoldingSheet(context, state),
            )
          else
            ...holdings.map(
              (holding) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _HoldingCard(holding: holding),
              ),
            ),
        ],
      ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          const _ScreenHeader(
            eyebrow: 'SNAPSHOTS',
            title: 'Historie',
            subtitle:
                'Gespeicherte Analysen bleiben mit ihrem damaligen Datenstand erhalten.',
          ),
          const SizedBox(height: 24),
          if (state.history.isEmpty)
            const _EmptyState(
              icon: Icons.history_toggle_off_rounded,
              title: 'Noch keine Analyse gespeichert',
              text: 'Öffne eine Analyse und tippe auf „Analyse speichern“.',
            )
          else
            ...state.history.map((snapshot) {
              final instrument = state.marketData.byId(snapshot.instrumentId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _HistoryTile(snapshot: snapshot, instrument: instrument),
              );
            }),
        ],
      ),
    );
  }
}

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: const [
          _ScreenHeader(
            eyebrow: 'ELLIOTT-WELLEN',
            title: 'Wissen',
            subtitle:
                'Die wichtigsten Begriffe, damit du jede Analyse nachvollziehen kannst.',
          ),
          SizedBox(height: 24),
          _LearningCard(
            number: '01',
            title: 'Impulswellen 1–5',
            text:
                'Ein Trendimpuls besteht typischerweise aus fünf Wellen. Die Wellen 1, 3 und 5 laufen mit dem Trend; 2 und 4 korrigieren ihn. Welle 3 darf dabei nicht die kürzeste Impulswelle sein.',
          ),
          SizedBox(height: 12),
          _LearningCard(
            number: '02',
            title: 'Korrektur A–B–C',
            text:
                'Nach einem Impuls folgt häufig eine dreiteilige Korrektur. Je nach Form kann sie als Zigzag, Flat, Triangle oder komplexe Kombination auftreten.',
          ),
          SizedBox(height: 12),
          _LearningCard(
            number: '03',
            title: 'Invalidierung',
            text:
                'Die Invalidierungsmarke zeigt, ab welchem Kurs eine Zählung nach ihren Regeln nicht mehr gültig ist. Sie ist wichtiger als eine scheinbar exakte Prognose.',
          ),
          SizedBox(height: 12),
          _LearningCard(
            number: '04',
            title: 'Szenarien & Wahrscheinlichkeit',
            text:
                'Mehrere Zählungen können gleichzeitig plausibel sein. Wahrscheinlichkeiten und Scores sind Orientierungshilfen – keine Gewissheiten oder Kaufempfehlungen.',
          ),
          SizedBox(height: 20),
          _RiskNotice(),
        ],
      ),
    );
  }
}

class InstrumentCard extends StatelessWidget {
  const InstrumentCard({required this.instrument, super.key});

  final Instrument instrument;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final positive = instrument.periodChangePercent >= 0;

    return _SurfaceCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AnalysisScreen(instrument: instrument),
        ),
      ),
      child: Row(
        children: [
          _TickerBadge(ticker: instrument.ticker),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instrument.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppPalette.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${instrument.isin} · ${instrument.defaultVenue}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppPalette.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                euro(instrument.euroPrice),
                style: const TextStyle(
                  color: AppPalette.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                percentage(instrument.periodChangePercent, signed: true),
                style: TextStyle(
                  color: positive ? AppPalette.limeDark : AppPalette.red,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: state.isFavorite(instrument.id)
                ? 'Aus Favoriten entfernen'
                : 'Zu Favoriten hinzufügen',
            onPressed: () => state.toggleFavorite(instrument.id),
            icon: Icon(
              state.isFavorite(instrument.id)
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              color: state.isFavorite(instrument.id)
                  ? AppPalette.ink
                  : AppPalette.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({required this.instrument, super.key});

  final Instrument instrument;

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  AnalysisResult? _analysis;
  Set<String> _visibleScenarioIds = {};
  late String _venue = widget.instrument.defaultVenue;
  var _historyPoints = 36;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_analysis != null) {
      return;
    }
    _analysis = AppScope.of(context).analyze(widget.instrument);
    _visibleScenarioIds = _analysis!.scenarios
        .map((scenario) => scenario.id)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final analysis = _analysis!;
    final instrument = widget.instrument;
    final primary = analysis.primaryScenario;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Zurück',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(instrument.ticker),
        actions: [
          IconButton(
            tooltip: state.isFavorite(instrument.id)
                ? 'Aus Favoriten entfernen'
                : 'Zu Favoriten hinzufügen',
            onPressed: () => state.toggleFavorite(instrument.id),
            icon: Icon(
              state.isFavorite(instrument.id)
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instrument.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppPalette.ink,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${instrument.isin} · ${instrument.originalCurrency}',
                      style: const TextStyle(color: AppPalette.muted),
                    ),
                  ],
                ),
              ),
              _ScoreBadge(score: analysis.overallScore),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            euro(instrument.euroPrice),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppPalette.ink,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${number(instrument.originalPrice)} ${instrument.originalCurrency} '
            '· FX ${number(instrument.fxRate, digits: 4)}',
            style: const TextStyle(color: AppPalette.muted),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _CompactDropdown<String>(
                  label: 'Handelsplatz',
                  value: _venue,
                  items: instrument.venues,
                  itemLabel: (value) => value,
                  onChanged: (value) => setState(() => _venue = value),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompactDropdown<int>(
                  label: 'Zeitraum',
                  value: _historyPoints,
                  items: const [8, 16, 36],
                  itemLabel: _periodLabel,
                  onChanged: (value) => setState(() => _historyPoints = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SurfaceCard(
            padding: const EdgeInsets.all(12),
            child: ElliottScenarioChart(
              instrument: instrument,
              analysis: analysis,
              visibleScenarioIds: _visibleScenarioIds,
              historyPoints: _historyPoints,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: analysis.scenarios.map((scenario) {
              final selected = _visibleScenarioIds.contains(scenario.id);
              final color = scenarioColor(scenario.kind);
              return FilterChip(
                selected: selected,
                showCheckmark: false,
                avatar: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                label: Text('${scenario.kind.label} ${scenario.probability} %'),
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _visibleScenarioIds.add(scenario.id);
                    } else {
                      _visibleScenarioIds.remove(scenario.id);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 26),
          _SectionTitle(
            title: 'Hauptszenario',
            trailing: '${primary.probability} %',
          ),
          const SizedBox(height: 12),
          _ScenarioCard(scenario: primary, primary: true),
          const SizedBox(height: 22),
          const _SectionTitle(title: 'Alternative Zählungen'),
          const SizedBox(height: 12),
          ...analysis.scenarios
              .where((scenario) => scenario.id != primary.id)
              .map(
                (scenario) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ScenarioCard(scenario: scenario),
                ),
              ),
          const SizedBox(height: 12),
          _MarketDataDetails(instrument: instrument, analysis: analysis),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () async {
              await state.saveAnalysis(analysis);
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Analyse als Snapshot gespeichert.'),
                ),
              );
            },
            icon: const Icon(Icons.bookmark_add_outlined),
            label: const Text('Analyse speichern'),
          ),
          const SizedBox(height: 16),
          const _RiskNotice(),
        ],
      ),
    );
  }
}

class SnapshotScreen extends StatelessWidget {
  const SnapshotScreen({
    required this.instrument,
    required this.snapshot,
    super.key,
  });

  final Instrument instrument;
  final AnalysisResult snapshot;

  @override
  Widget build(BuildContext context) {
    final visibleIds = snapshot.scenarios
        .map((scenario) => scenario.id)
        .toSet();
    return Scaffold(
      appBar: AppBar(title: const Text('Analyse-Snapshot')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
        children: [
          Text(
            instrument.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppPalette.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Gespeichert am ${dateTimeText(snapshot.createdAt)}',
            style: const TextStyle(color: AppPalette.muted),
          ),
          const SizedBox(height: 20),
          _SurfaceCard(
            padding: const EdgeInsets.all(12),
            child: ElliottScenarioChart(
              instrument: instrument,
              analysis: snapshot,
              visibleScenarioIds: visibleIds,
              historyPoints: instrument.historyEuro.length,
            ),
          ),
          const SizedBox(height: 22),
          _SectionTitle(
            title: 'Gespeichertes Hauptszenario',
            trailing: '${snapshot.primaryScenario.probability} %',
          ),
          const SizedBox(height: 12),
          _ScenarioCard(scenario: snapshot.primaryScenario, primary: true),
          const SizedBox(height: 18),
          _MarketDataDetails(instrument: instrument, analysis: snapshot),
          const SizedBox(height: 16),
          const _RiskNotice(),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: AppPalette.ink,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text(
            'EV',
            style: TextStyle(
              color: AppPalette.lime,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Elliott Vision',
            style: TextStyle(
              color: AppPalette.ink,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ),
        const _Pill(text: 'MVP · DEMO', color: AppPalette.lime),
      ],
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: AppPalette.limeDark,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppPalette.ink,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
            ),
            if (action != null) action!,
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppPalette.muted,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppPalette.ink,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(
              color: AppPalette.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.line),
      ),
      child: child,
    );
    if (onTap == null) {
      return content;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class _TickerBadge extends StatelessWidget {
  const _TickerBadge({required this.ticker});

  final String ticker;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppPalette.background,
        shape: BoxShape.circle,
        border: Border.all(color: AppPalette.line),
      ),
      child: Text(
        ticker.length > 4 ? ticker.substring(0, 4) : ticker,
        style: const TextStyle(
          color: AppPalette.ink,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.lime.withAlpha(75),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined, size: 20, color: AppPalette.limeDark),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'MVP-Demo: Kurse und Analysen sind Beispieldaten. '
              'Live-Daten folgen über einen geprüften Datenanbieter.',
              style: TextStyle(
                color: AppPalette.ink,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppPalette.ink,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: AppPalette.ink,
        shape: BoxShape.circle,
        border: Border.all(color: AppPalette.lime, width: 4),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$score',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'SCORE',
            style: TextStyle(
              color: AppPalette.lime,
              fontSize: 7,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactDropdown<T> extends StatelessWidget {
  const _CompactDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T value) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 6),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppPalette.muted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              style: const TextStyle(
                color: AppPalette.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              items: items
                  .map(
                    (item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(
                        itemLabel(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (item) {
                if (item != null) {
                  onChanged(item);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({required this.scenario, this.primary = false});

  final AnalysisScenario scenario;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final color = scenarioColor(scenario.kind);
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  scenario.title,
                  style: const TextStyle(
                    color: AppPalette.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (primary) const _Pill(text: 'HAUPT', color: AppPalette.lime),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            scenario.thesis,
            style: const TextStyle(
              color: AppPalette.muted,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: 'ZIEL',
                  value: euro(scenario.targetEuro),
                ),
              ),
              Expanded(
                child: _MiniMetric(
                  label: 'INVALIDIERUNG',
                  value: euro(scenario.invalidationEuro),
                ),
              ),
              Expanded(
                child: _MiniMetric(
                  label: 'SCORE',
                  value: '${scenario.score}/100',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppPalette.muted,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          style: const TextStyle(
            color: AppPalette.ink,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MarketDataDetails extends StatelessWidget {
  const _MarketDataDetails({required this.instrument, required this.analysis});

  final Instrument instrument;
  final AnalysisResult analysis;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daten & Nachvollziehbarkeit',
            style: TextStyle(
              color: AppPalette.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _DetailRow(
            label: 'Datenstand',
            value: dateTimeText(analysis.dataTimestamp),
          ),
          _DetailRow(
            label: 'Originalkurs',
            value:
                '${number(instrument.originalPrice)} ${instrument.originalCurrency}',
          ),
          _DetailRow(label: 'Allzeithoch', value: euro(instrument.athEuro)),
          _DetailRow(label: 'Allzeittief', value: euro(instrument.atlEuro)),
          _DetailRow(label: 'Analyse', value: analysis.engineVersion),
          _DetailRow(label: 'Erklärung', value: analysis.explanationModel),
          _DetailRow(
            label: 'Prompt-Version',
            value: analysis.promptVersion,
            last: true,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppPalette.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(color: AppPalette.muted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppPalette.ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioSummary extends StatelessWidget {
  const _PortfolioSummary({
    required this.currentValue,
    required this.invested,
    required this.result,
    required this.resultPercent,
  });

  final double currentValue;
  final double invested;
  final double result;
  final double resultPercent;

  @override
  Widget build(BuildContext context) {
    final positive = result >= 0;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppPalette.ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AKTUELLER DEMO-WERT',
            style: TextStyle(
              color: AppPalette.lime,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            euro(currentValue),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DarkMetric(label: 'INVESTIERT', value: euro(invested)),
              ),
              Expanded(
                child: _DarkMetric(
                  label: 'ERGEBNIS',
                  value:
                      '${result >= 0 ? '+' : ''}${euro(result)} · ${percentage(resultPercent, signed: true)}',
                  valueColor: positive
                      ? AppPalette.lime
                      : const Color(0xFFFF8791),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DarkMetric extends StatelessWidget {
  const _DarkMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9EA196),
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _HoldingCard extends StatelessWidget {
  const _HoldingCard({required this.holding});

  final Holding holding;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final instrument = state.marketData.byId(holding.instrumentId);
    final current = instrument.euroPrice * holding.quantity;
    final result = current - holding.investedEuro;
    final resultPercent = holding.investedEuro == 0
        ? 0.0
        : result / holding.investedEuro * 100;
    final positive = result >= 0;

    return _SurfaceCard(
      child: Column(
        children: [
          Row(
            children: [
              _TickerBadge(ticker: instrument.ticker),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instrument.name,
                      style: const TextStyle(
                        color: AppPalette.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${number(holding.quantity)} Stück · Kauf ${shortDate(holding.purchaseDate)}',
                      style: const TextStyle(
                        color: AppPalette.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Position löschen',
                onPressed: () => state.removeHolding(holding.id),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppPalette.line),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: 'KAUFPREIS',
                  value: euro(holding.purchasePriceEuro),
                ),
              ),
              Expanded(
                child: _MiniMetric(label: 'WERT', value: euro(current)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ERGEBNIS',
                      style: TextStyle(
                        color: AppPalette.muted,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      percentage(resultPercent, signed: true),
                      style: TextStyle(
                        color: positive ? AppPalette.limeDark : AppPalette.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.snapshot, required this.instrument});

  final AnalysisResult snapshot;
  final Instrument instrument;

  @override
  Widget build(BuildContext context) {
    final primary = snapshot.primaryScenario;
    return _SurfaceCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              SnapshotScreen(instrument: instrument, snapshot: snapshot),
        ),
      ),
      child: Row(
        children: [
          _TickerBadge(ticker: instrument.ticker),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instrument.name,
                  style: const TextStyle(
                    color: AppPalette.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${dateTimeText(snapshot.createdAt)} · ${primary.kind.label}',
                  style: const TextStyle(color: AppPalette.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ScoreBadge(score: snapshot.overallScore),
        ],
      ),
    );
  }
}

class _LearningCard extends StatelessWidget {
  const _LearningCard({
    required this.number,
    required this.title,
    required this.text,
  });

  final String number;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppPalette.lime,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: AppPalette.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppPalette.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: AppPalette.muted,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskNotice extends StatelessWidget {
  const _RiskNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2E0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD9A5)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF8A5200)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Keine Anlageberatung. Elliott-Wellen sind interpretationsabhängig. '
              'Prüfe Daten und Risiken immer eigenständig.',
              style: TextStyle(
                color: Color(0xFF6E4300),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: AppPalette.background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppPalette.muted, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppPalette.ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppPalette.muted,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

Future<void> _showAddHoldingSheet(BuildContext context, AppState state) async {
  final priceController = TextEditingController();
  final quantityController = TextEditingController();
  final noteController = TextEditingController();
  var selectedInstrument = state.marketData.instruments.first;
  var purchaseDate = DateTime.now();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppPalette.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppPalette.line,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Position hinzufügen',
                    style: TextStyle(
                      color: AppPalette.ink,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  InputDecorator(
                    decoration: const InputDecoration(labelText: 'Wertpapier'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Instrument>(
                        value: selectedInstrument,
                        isExpanded: true,
                        isDense: true,
                        items: state.marketData.instruments
                            .map(
                              (instrument) => DropdownMenuItem<Instrument>(
                                value: instrument,
                                child: Text(
                                  '${instrument.name} · ${instrument.ticker}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (instrument) {
                          if (instrument == null) {
                            return;
                          }
                          setSheetState(() => selectedInstrument = instrument);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Kaufpreis in €',
                            hintText: '0,00',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: quantityController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Stückzahl',
                            hintText: '0',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SurfaceCard(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(1990),
                        lastDate: DateTime.now(),
                        initialDate: purchaseDate,
                      );
                      if (!context.mounted) {
                        return;
                      }
                      if (picked != null) {
                        setSheetState(() => purchaseDate = picked);
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'KAUFDATUM',
                                style: TextStyle(
                                  color: AppPalette.muted,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                shortDate(purchaseDate),
                                style: const TextStyle(
                                  color: AppPalette.ink,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Notiz (optional)',
                      hintText: 'Zum Beispiel Sparplan',
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () async {
                      final price = double.tryParse(
                        priceController.text.trim().replaceAll(',', '.'),
                      );
                      final quantity = double.tryParse(
                        quantityController.text.trim().replaceAll(',', '.'),
                      );
                      if (price == null ||
                          price <= 0 ||
                          quantity == null ||
                          quantity <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Bitte Kaufpreis und Stückzahl prüfen.',
                            ),
                          ),
                        );
                        return;
                      }
                      await state.addHolding(
                        Holding(
                          id: 'holding-${DateTime.now().microsecondsSinceEpoch}',
                          instrumentId: selectedInstrument.id,
                          purchaseDate: purchaseDate,
                          purchasePriceEuro: price,
                          quantity: quantity,
                          note: noteController.text.trim(),
                        ),
                      );
                      if (sheetContext.mounted)
                        Navigator.of(sheetContext).pop();
                    },
                    child: const Text('Position speichern'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  priceController.dispose();
  quantityController.dispose();
  noteController.dispose();
}

String _periodLabel(int value) {
  if (value == 8) {
    return '3 Monate';
  }
  if (value == 16) {
    return '1 Jahr';
  }
  return '3 Jahre';
}
