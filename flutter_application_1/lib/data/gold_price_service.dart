import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

const _goldApiEndpoint = 'https://www.goldapi.io/api/XAU/EGP';
const _cacheTtl = Duration(minutes: 30);
const _karatFields = <int, String>{
  24: 'price_gram_24k',
  22: 'price_gram_22k',
  21: 'price_gram_21k',
  18: 'price_gram_18k',
};

class GoldPriceService {
  const GoldPriceService({this.client});

  final http.Client? client;

  static Map<int, double>? _cachedPrices;
  static DateTime? _cacheExpiresAt;

  Future<Map<int, double>> fetchPrices() async {
    final now = DateTime.now();
    if (_cachedPrices != null &&
        _cacheExpiresAt != null &&
        _cacheExpiresAt!.isAfter(now)) {
      return _cachedPrices!;
    }

    final goldApiKey = dotenv.env['GOLD_API_KEY']?.trim() ?? '';
    if (goldApiKey.isEmpty) {
      debugPrint('Gold price request skipped: GOLD_API_KEY is not configured.');
      return const {};
    }

    debugPrint('Requesting gold prices from $_goldApiEndpoint');
    final requestClient = client ?? http.Client();
    try {
      final response = await requestClient
          .get(
            Uri.parse(_goldApiEndpoint),
            headers: {
              'Accept': 'application/json',
              'x-access-token': goldApiKey,
            },
          )
          .timeout(const Duration(seconds: 12));
      debugPrint('Gold price response status: ${response.statusCode}');
      final payload = jsonDecode(response.body);

      if (response.statusCode != 200 || payload is! Map<String, dynamic>) {
        throw const FormatException('GoldAPI returned unavailable data.');
      }

      final prices = <int, double>{};
      for (final entry in _karatFields.entries) {
        final value = _positiveDouble(payload[entry.value]);
        if (value != null) {
          prices[entry.key] = value;
        }
      }
      if (prices.isEmpty) {
        throw const FormatException('GoldAPI returned no karat prices.');
      }
      _cachedPrices = prices;
      _cacheExpiresAt = now.add(_cacheTtl);
      return prices;
    } catch (error) {
      debugPrint('Gold price request failed: $error');
      return const {};
    } finally {
      if (client == null) requestClient.close();
    }
  }

  static double? _positiveDouble(dynamic value) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    return number != null && number.isFinite && number > 0 ? number : null;
  }

  static double? calculateJewelryPrice({
    required double? goldWeight,
    required int? goldKarat,
    required double? currentPremium,
    required Map<int, double> goldPrices,
  }) {
    final goldPricePerGram = goldPrices[goldKarat];
    if (goldPricePerGram == null ||
        goldWeight == null ||
        goldWeight <= 0 ||
        currentPremium == null ||
        currentPremium < 0) {
      return null;
    }

    return (goldPricePerGram + currentPremium) * goldWeight;
  }
}
