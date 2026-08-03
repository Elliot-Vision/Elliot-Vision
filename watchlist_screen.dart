import 'package:flutter/material.dart';

import '../services/app_store.dart';
import '../services/market_data_service.dart';
import 'security_detail_screen.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key, required this.store, required this.marketData});
  final AppStore store;
  final MarketDataService marketData;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (_, __) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Favoriten', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          if (store.favorites.isEmpty)
            const Text('Noch keine Favoriten gespeichert.')
          else
            ...store.favorites.map((security) => Card(
                  child: ListTile(
                    title: Text(security.name),
                    subtitle: Text(security.isin),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => store.toggleFavorite(security),
                    ),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => SecurityDetailScreen(
                        security: security,
                        store: store,
                        marketData: marketData,
                      ),
                    )),
                  ),
                )),
        ],
      ),
    );
  }
}
