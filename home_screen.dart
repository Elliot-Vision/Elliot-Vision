import 'package:flutter/material.dart';
import '../services/app_store.dart';
import '../services/market_data_service.dart';
import 'knowledge_screen.dart';
import 'portfolio_screen.dart';
import 'search_screen.dart';
import 'watchlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store});
  final AppStore store;
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final _marketData = DemoMarketDataService();
  @override Widget build(BuildContext context) {
    final screens = [
      SearchScreen(store: widget.store, marketData: _marketData),
      WatchlistScreen(store: widget.store, marketData: _marketData),
      PortfolioScreen(store: widget.store),
      const KnowledgeScreen(),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: screens)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (v) => setState(() => _index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'Analyse'),
          NavigationDestination(icon: Icon(Icons.star_border), label: 'Favoriten'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Depot'),
          NavigationDestination(icon: Icon(Icons.school_outlined), label: 'Wissen'),
        ],
      ),
    );
  }
}
