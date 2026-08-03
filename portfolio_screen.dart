import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/portfolio_position.dart';
import '../services/app_store.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'de_DE', symbol: '€');
    return AnimatedBuilder(
      animation: store,
      builder: (_, __) => Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddPosition(context),
          icon: const Icon(Icons.add),
          label: const Text('Aktie hinzufügen'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Mein Depot', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            if (store.positions.isEmpty)
              const Text('Noch keine Aktienposition eingetragen.')
            else
              ...store.positions.map((position) => Card(
                    child: ListTile(
                      title: Text(position.name),
                      subtitle: Text(
                        '${position.isin}\n${position.quantity.toStringAsFixed(2)} Stück · Kauf ${DateFormat('dd.MM.yyyy').format(position.purchaseDate)}',
                      ),
                      isThreeLine: true,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(currency.format(position.purchasePriceEur)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => store.removePosition(position),
                          ),
                        ],
                      ),
                    ),
                  )),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddPosition(BuildContext context) async {
    final isin = TextEditingController();
    final name = TextEditingController();
    final price = TextEditingController();
    final quantity = TextEditingController(text: '1');
    var date = DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Depotposition hinzufügen'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: isin, decoration: const InputDecoration(labelText: 'ISIN')),
                const SizedBox(height: 10),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 10),
                TextField(
                  controller: price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Kaufpreis in €'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: quantity,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Stückzahl'),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Kaufdatum'),
                  subtitle: Text(DateFormat('dd.MM.yyyy').format(date)),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: context,
                      firstDate: DateTime(1990),
                      lastDate: DateTime.now(),
                      initialDate: date,
                    );
                    if (selected != null) setState(() => date = selected);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Abbrechen')),
            FilledButton(
              onPressed: () async {
                final parsedPrice = double.tryParse(price.text.replaceAll(',', '.'));
                final parsedQuantity = double.tryParse(quantity.text.replaceAll(',', '.'));
                if (isin.text.trim().isEmpty ||
                    name.text.trim().isEmpty ||
                    parsedPrice == null ||
                    parsedQuantity == null) {
                  return;
                }
                await store.addPosition(PortfolioPosition(
                  isin: isin.text.trim().toUpperCase(),
                  name: name.text.trim(),
                  purchaseDate: date,
                  purchasePriceEur: parsedPrice,
                  quantity: parsedQuantity,
                ));
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }
}
