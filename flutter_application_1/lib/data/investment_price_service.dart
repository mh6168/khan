import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/investment.dart';

const _goldApiGoldUrl =
    'https://www.goldapi.io/api/price/XAU/EGP?melt_price=true&currency_info=true';
const _goldApiSilverUrl =
    'https://www.goldapi.io/api/price/XAG/EGP?melt_price=true&currency_info=true';

class InvestmentPriceService {
  InvestmentPriceService({this.client, this.apiKey});

  final http.Client? client;
  final String? apiKey;

  Future<InvestmentPriceSnapshot> fetchPrices() async {
    final key = (apiKey ?? _configuredApiKey()).trim();
    if (key.isEmpty) {
      throw StateError('GOLD_API_KEY is missing from the Flutter .env file.');
    }

    final requestClient = client ?? http.Client();
    try {
      final responses = await Future.wait([
        _fetchMetal(requestClient, _goldApiGoldUrl, key, 'gold'),
        _fetchMetal(requestClient, _goldApiSilverUrl, key, 'silver'),
      ]);
      return parseResponses(responses[0], responses[1]);
    } finally {
      if (client == null) requestClient.close();
    }
  }

  static InvestmentPriceSnapshot parseResponses(
    Map<String, dynamic> gold,
    Map<String, dynamic> silver,
  ) {
    _requireMetal(gold, 'gold', 'XAU');
    _requireMetal(silver, 'silver', 'XAG');
    _requireEgp(gold, 'gold');
    _requireEgp(silver, 'silver');

    final goldPriceValue = _firstPositivePrice([
      _mapField(gold['price_per_unit'], 'gram'),
      _mapField(gold['melt_price_per_gram'], '24k'),
      gold['price_gram_24k'],
    ]);
    final goldPrice = _decimalValue(goldPriceValue);
    final liraSpotMinor = goldPrice != null && goldPrice > BigInt.zero
        ? _roundHalfUp(goldPrice, _decimalScale(goldPriceValue))
        : _goldTroyOunceSpotMinor(gold);
    final silver925Value = _firstPositivePrice([
      silver['price_gram_925'],
      _mapField(silver['melt_price_per_gram'], '925'),
    ]);
    final silver925 = _decimalValue(silver925Value);
    final paraSpotMinor = silver925 != null && silver925 > BigInt.zero
        ? _roundHalfUp(
            silver925 * BigInt.from(100),
            _decimalScale(silver925Value),
          )
        : _pureSilver925Minor(silver);

    return InvestmentPriceSnapshot(
      lira: InvestmentPrices.fromSpot(liraSpotMinor),
      para: InvestmentPrices.fromSpot(paraSpotMinor),
      updatedAt: DateTime.now(),
    );
  }

  Future<Map<String, dynamic>> _fetchMetal(
    http.Client client,
    String url,
    String apiKey,
    String metal,
  ) async {
    final response = await client
        .get(
          Uri.parse(url),
          headers: {'Accept': 'application/json', 'x-access-token': apiKey},
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw HttpException(
        'GoldAPI $metal request returned HTTP ${response.statusCode}. Check the API key and connectivity.',
      );
    }

    dynamic payload;
    try {
      payload = jsonDecode(response.body);
    } on FormatException {
      throw FormatException('GoldAPI $metal response was not valid JSON.');
    }
    if (payload is! Map<String, dynamic>) {
      throw FormatException('GoldAPI $metal response was not a JSON object.');
    }
    return payload;
  }

  static int _goldTroyOunceSpotMinor(Map<String, dynamic> gold) {
    _requireTroyOunce(gold, 'gold');
    final ounceValue = gold['price'];
    final ouncePrice = _decimalValue(ounceValue);
    if (ouncePrice == null || ouncePrice <= BigInt.zero) {
      throw const FormatException(
        'GoldAPI gold quote is missing a positive per-gram price or troy-ounce price.',
      );
    }

    return _roundHalfUp(
      ouncePrice * BigInt.from(10000000),
      _decimalScale(ounceValue) * BigInt.from(311034768),
    );
  }

  String _configuredApiKey() {
    if (!dotenv.isInitialized) return '';
    return dotenv.env['GOLD_API_KEY'] ?? '';
  }

  static void _requireMetal(
    Map<String, dynamic> payload,
    String name,
    String expectedMetal,
  ) {
    final metal = payload['metal'];
    if (metal is! String || metal.toUpperCase() != expectedMetal) {
      final providerError = payload['error'] ?? payload['message'];
      final detail = providerError is String && providerError.isNotEmpty
          ? providerError
          : 'response metal was ${metal ?? 'missing'}';
      throw FormatException(
        'GoldAPI $name $detail; expected metal $expectedMetal.',
      );
    }
  }

  static void _requireEgp(Map<String, dynamic> payload, String metal) {
    final currency = payload['currency'];
    if (currency is! String || currency.toUpperCase() != 'EGP') {
      throw FormatException(
        'GoldAPI $metal quote currency was not EGP; received ${currency ?? 'no currency'}.',
      );
    }
  }

  static void _requireTroyOunce(Map<String, dynamic> payload, String metal) {
    final unit = payload['unit'];
    if (unit is! String || unit.toLowerCase() != 'troy_ounce') {
      throw FormatException(
        'GoldAPI $metal quote unit was not troy_ounce; cannot convert its price safely.',
      );
    }
  }

  static dynamic _firstPositivePrice(Iterable<dynamic> values) {
    for (final value in values) {
      final parsed = _decimalValue(value);
      if (parsed != null && parsed > BigInt.zero) return value;
    }
    return null;
  }

  static BigInt? _decimalValue(dynamic value) {
    if (value is! num && value is! String) return null;
    final text = value.toString().trim();
    final match = RegExp(r'^(\d+)(?:\.(\d+))?$').firstMatch(text);
    if (match == null) return null;
    final fractional = match.group(2) ?? '';
    return BigInt.parse('${match.group(1)}$fractional');
  }

  static BigInt _decimalScale(dynamic value) {
    final text = value.toString().trim();
    final point = text.indexOf('.');
    final decimalPlaces = point < 0 ? 0 : text.length - point - 1;
    return BigInt.from(10).pow(decimalPlaces);
  }

  static dynamic _mapField(dynamic value, String key) {
    return value is Map ? value[key] : null;
  }

  static int _pureSilver925Minor(Map<String, dynamic> silver) {
    // GoldAPI's XAG response uses price_gram_24k for its pure-silver gram quote.
    final pureSilver = _firstPositivePrice([
      _mapField(silver['price_per_unit'], 'gram'),
      _mapField(silver['melt_price_per_gram'], '24k'),
      silver['price_gram_24k'],
    ]);
    final pureSilverScaled = _decimalValue(pureSilver);
    if (pureSilverScaled != null && pureSilverScaled > BigInt.zero) {
      return _pureSilverGramTo925Minor(pureSilverScaled, pureSilver);
    }

    _requireTroyOunce(silver, 'silver');
    final ounceValue = silver['price'];
    final ouncePrice = _decimalValue(ounceValue);
    if (ouncePrice == null || ouncePrice <= BigInt.zero) {
      throw const FormatException(
        'GoldAPI silver quote is missing a positive 925 price, pure-silver per-gram price, or troy-ounce price.',
      );
    }
    return _roundHalfUp(
      ouncePrice * BigInt.from(925000000),
      _decimalScale(ounceValue) * BigInt.from(311034768),
    );
  }

  static int _pureSilverGramTo925Minor(BigInt pureSilver, dynamic value) {
    return _roundHalfUp(
      pureSilver * BigInt.from(92500),
      _decimalScale(value) * BigInt.from(1000),
    );
  }

  static int _roundHalfUp(BigInt numerator, BigInt denominator) {
    return ((numerator * BigInt.two + denominator) ~/
            (denominator * BigInt.two))
        .toInt();
  }
}

class HttpException implements Exception {
  const HttpException(this.message);

  final String message;

  @override
  String toString() => message;
}
