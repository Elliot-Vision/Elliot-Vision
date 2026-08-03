import 'models.dart';

abstract class MarketDataRepository {
  List<Instrument> get instruments;
  Future<List<Instrument>> search(String query);
  Instrument byId(String id);
  Instrument? findById(String id);
  Future<Instrument> refresh(Instrument instrument);
  void restore(Iterable<Instrument> instruments);
}

class DemoMarketDataRepository implements MarketDataRepository {
  DemoMarketDataRepository()
    : _instruments = [
        _instrument(
          id: 'aapl',
          name: 'Apple Inc.',
          ticker: 'AAPL',
          isin: 'US0378331005',
          venue: 'Nasdaq',
          venues: const ['Nasdaq', 'Tradegate', 'LS Exchange'],
          currency: 'USD',
          originalPrice: 207.54,
          euroPrice: 190.40,
          fxRate: 0.9174,
          athEuro: 239.50,
          atlEuro: 0.08,
          history: const [
            124,
            129,
            126,
            135,
            141,
            138,
            146,
            151,
            148,
            156,
            163,
            159,
            167,
            174,
            171,
            178,
            184,
            181,
            188,
            194,
            190,
            198,
            203,
            196,
            205,
            212,
            207,
            214,
            209,
            202,
            197,
            193,
            187,
            191,
            188,
            190.4,
          ],
        ),
        _instrument(
          id: 'msft',
          name: 'Microsoft Corp.',
          ticker: 'MSFT',
          isin: 'US5949181045',
          venue: 'Nasdaq',
          venues: const ['Nasdaq', 'Tradegate', 'gettex'],
          currency: 'USD',
          originalPrice: 415.56,
          euroPrice: 381.20,
          fxRate: 0.9173,
          athEuro: 445.00,
          atlEuro: 0.09,
          history: const [
            242,
            249,
            255,
            252,
            264,
            273,
            269,
            281,
            290,
            286,
            298,
            307,
            315,
            310,
            324,
            336,
            331,
            344,
            351,
            347,
            359,
            366,
            361,
            374,
            383,
            378,
            391,
            398,
            405,
            397,
            389,
            385,
            377,
            382,
            379,
            381.2,
          ],
        ),
        _instrument(
          id: 'nvda',
          name: 'NVIDIA Corp.',
          ticker: 'NVDA',
          isin: 'US67066G1040',
          venue: 'Nasdaq',
          venues: const ['Nasdaq', 'Tradegate', 'LS Exchange'],
          currency: 'USD',
          originalPrice: 176.32,
          euroPrice: 161.75,
          fxRate: 0.9174,
          athEuro: 175.00,
          atlEuro: 0.03,
          history: const [
            39,
            42,
            45,
            43,
            49,
            54,
            51,
            59,
            64,
            61,
            69,
            75,
            72,
            81,
            88,
            84,
            95,
            103,
            99,
            111,
            119,
            115,
            128,
            135,
            132,
            144,
            151,
            147,
            158,
            166,
            160,
            154,
            149,
            156,
            159,
            161.75,
          ],
        ),
        _instrument(
          id: 'uec',
          name: 'Uranium Energy Corp.',
          ticker: 'UEC',
          isin: 'US9168961038',
          venue: 'NYSE American',
          venues: const ['NYSE American', 'Tradegate', 'Frankfurt'],
          currency: 'USD',
          originalPrice: 9.96,
          euroPrice: 9.14,
          fxRate: 0.9177,
          athEuro: 52.00,
          atlEuro: 0.32,
          history: const [
            3.1,
            3.4,
            3.2,
            3.8,
            4.1,
            3.9,
            4.6,
            5.2,
            4.9,
            5.6,
            6.1,
            5.7,
            6.5,
            7.1,
            6.8,
            7.6,
            8.2,
            7.9,
            8.6,
            9.1,
            8.7,
            9.6,
            10.2,
            9.7,
            10.6,
            11.0,
            10.4,
            9.9,
            9.3,
            8.8,
            8.4,
            8.9,
            9.3,
            9.0,
            9.2,
            9.14,
          ],
        ),
        _instrument(
          id: 'dro',
          name: 'DroneShield Ltd.',
          ticker: 'DRO',
          isin: 'AU000000DRO2',
          venue: 'ASX',
          venues: const ['ASX', 'Tradegate', 'Frankfurt'],
          currency: 'AUD',
          originalPrice: 3.73,
          euroPrice: 2.26,
          fxRate: 0.606,
          athEuro: 3.90,
          atlEuro: 0.02,
          history: const [
            0.26,
            0.29,
            0.31,
            0.28,
            0.36,
            0.42,
            0.39,
            0.49,
            0.57,
            0.53,
            0.65,
            0.72,
            0.68,
            0.82,
            0.94,
            0.89,
            1.04,
            1.18,
            1.11,
            1.29,
            1.46,
            1.38,
            1.57,
            1.73,
            1.65,
            1.88,
            2.05,
            1.96,
            2.17,
            2.42,
            2.31,
            2.14,
            2.02,
            2.18,
            2.22,
            2.26,
          ],
        ),
      ];

  final List<Instrument> _instruments;

  static Instrument _instrument({
    required String id,
    required String name,
    required String ticker,
    required String isin,
    required String venue,
    required List<String> venues,
    required String currency,
    required double originalPrice,
    required double euroPrice,
    required double fxRate,
    required double athEuro,
    required double atlEuro,
    required List<double> history,
  }) {
    return Instrument(
      id: id,
      name: name,
      ticker: ticker,
      isin: isin,
      defaultVenue: venue,
      venues: venues,
      originalCurrency: currency,
      originalPrice: originalPrice,
      euroPrice: euroPrice,
      fxRate: fxRate,
      athEuro: athEuro,
      atlEuro: atlEuro,
      dataTimestamp: DateTime.utc(2026, 8, 3, 10, 0),
      historyEuro: history,
    );
  }

  @override
  List<Instrument> get instruments => List.unmodifiable(_instruments);

  @override
  Instrument byId(String id) =>
      _instruments.firstWhere((instrument) => instrument.id == id);

  @override
  Instrument? findById(String id) {
    for (final instrument in _instruments) {
      if (instrument.id == id) {
        return instrument;
      }
    }
    return null;
  }

  @override
  Future<List<Instrument>> search(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return instruments;
    }
    return _instruments
        .where(
          (instrument) =>
              instrument.name.toLowerCase().contains(normalized) ||
              instrument.ticker.toLowerCase().contains(normalized) ||
              instrument.isin.toLowerCase().contains(normalized),
        )
        .toList();
  }

  @override
  Future<Instrument> refresh(Instrument instrument) async => instrument;

  @override
  void restore(Iterable<Instrument> instruments) {
    for (final instrument in instruments) {
      final index = _instruments.indexWhere((item) => item.id == instrument.id);
      if (index == -1) {
        _instruments.add(instrument);
      } else {
        _instruments[index] = instrument;
      }
    }
  }
}
