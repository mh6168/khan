import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class PaymobService {
  PaymobService({
    this.client,
    this.apiKey,
    this.integrationId,
    this.iframeId,
    this.apiBaseUrl,
    this.redirectUrl,
    this.timeoutSeconds,
  });

  final http.Client? client;
  final String? apiKey;
  final String? integrationId;
  final String? iframeId;
  final String? apiBaseUrl;
  final String? redirectUrl;
  final int? timeoutSeconds;

  Future<PaymobCheckoutSession> createCheckoutSession({
    required int amountMinor,
    required String merchantOrderId,
    required String email,
    String? returnUrl,
  }) async {
    if (amountMinor <= 0) {
      throw ArgumentError.value(amountMinor, 'amountMinor');
    }
    final configuredApiKey = _config('PAYMOB_API_KEY', apiKey);
    final configuredIntegrationId = _config(
      'PAYMOB_INTEGRATION_ID',
      integrationId,
    );
    final configuredIframeId = _config('PAYMOB_IFRAME_ID', iframeId);
    if (int.tryParse(configuredIframeId) == null) {
      throw const PaymobException('PAYMOB_IFRAME_ID must be numeric.');
    }
    final parsedIntegrationId = int.tryParse(configuredIntegrationId);
    if (parsedIntegrationId == null) {
      throw const PaymobException('PAYMOB_INTEGRATION_ID must be numeric.');
    }
    final token = await _authenticate(configuredApiKey);

    final paymobOrder = await _request('POST', '/ecommerce/orders', token, {
      'auth_token': token,
      'delivery_needed': false,
      'amount_cents': amountMinor,
      'currency': 'EGP',
      'merchant_order_id': merchantOrderId,
    });
    final paymobOrderId = paymobOrder['id']?.toString();
    if (paymobOrderId == null || paymobOrderId.isEmpty) {
      throw const PaymobException('Paymob did not return an order ID.');
    }

    final paymentKeyBody = <String, dynamic>{
      'auth_token': token,
      'amount_cents': amountMinor,
      'expiration': 15 * 60,
      'order_id': paymobOrder['id'],
      'billing_data': {
        'apartment': 'NA',
        'email': email.isEmpty ? 'customer@example.com' : email,
        'floor': 'NA',
        'first_name': 'KHAN',
        'street': 'NA',
        'building': 'NA',
        'phone_number': 'NA',
        'shipping_method': 'NA',
        'postal_code': 'NA',
        'city': 'Cairo',
        'country': 'EG',
        'last_name': 'Customer',
        'state': 'Cairo',
      },
      'currency': 'EGP',
      'integration_id': parsedIntegrationId,
    };
    final configuredRedirectUrl =
        returnUrl ??
        redirectUrl ??
        (dotenv.isInitialized ? dotenv.env['PAYMOB_REDIRECT_URL'] : null) ??
        '';
    final appRedirectUrl = _appRedirectUrl(configuredRedirectUrl);
    if (appRedirectUrl.isNotEmpty) {
      paymentKeyBody['redirection_url'] = appRedirectUrl;
    }

    final paymentKey = await _request(
      'POST',
      '/acceptance/payment_keys',
      token,
      paymentKeyBody,
    );
    final paymentToken = paymentKey['token']?.toString();
    if (paymentToken == null || paymentToken.isEmpty) {
      throw const PaymobException('Paymob did not return a payment token.');
    }

    final baseUrl = _baseUrl;
    return PaymobCheckoutSession(
      paymobOrderId: paymobOrderId,
      checkoutUrl: Uri.parse('$baseUrl/acceptance/iframes/$configuredIframeId')
          .replace(queryParameters: {'payment_token': paymentToken}),
    );
  }

  Future<PaymobVerificationResult> verifyTransaction({
    required String transactionId,
    required String expectedMerchantOrderId,
    required int expectedAmountMinor,
  }) async {
    if (!RegExp(r'^\d+$').hasMatch(transactionId)) {
      throw const PaymobException(
        'Paymob returned an invalid transaction reference.',
      );
    }
    final token = await _authenticate(_config('PAYMOB_API_KEY', apiKey));
    final payment = await _request(
      'GET',
      '/acceptance/transactions/$transactionId',
      token,
    );

    if (payment['pending'] == true) {
      return PaymobVerificationResult.pending;
    }
    if (payment['success'] != true ||
        payment['is_refunded'] == true ||
        payment['is_voided'] == true) {
      return PaymobVerificationResult.failed;
    }
    if (payment['currency']?.toString().toUpperCase() != 'EGP' ||
        _intValue(payment['amount_cents']) != expectedAmountMinor) {
      throw const PaymobException(
        'The Paymob payment amount or currency does not match this order.',
      );
    }

    var order = _mapValue(payment['order']);
    if (order == null || order['merchant_order_id'] == null) {
      final paymobOrderId = payment['order_id']?.toString();
      if (paymobOrderId == null || paymobOrderId.isEmpty) {
        throw const PaymobException(
          'Paymob did not return the payment order details.',
        );
      }
      order = await _request('GET', '/ecommerce/orders/$paymobOrderId', token);
    }
    if (order['merchant_order_id']?.toString() != expectedMerchantOrderId) {
      throw const PaymobException(
        'This Paymob transaction does not belong to this purchase.',
      );
    }

    return PaymobVerificationResult.success(
      VerifiedPaymobPayment(
        transactionId: transactionId,
        amountMinor: expectedAmountMinor,
        merchantOrderId: expectedMerchantOrderId,
      ),
    );
  }

  Future<String> _authenticate(String apiKey) async {
    if (apiKey.isEmpty) {
      throw const PaymobException('PAYMOB_API_KEY is missing from .env.');
    }
    final response = await _request('POST', '/auth/tokens', null, {
      'api_key': apiKey,
    });
    final token = response['token']?.toString();
    if (token == null || token.isEmpty) {
      throw const PaymobException('Paymob authentication returned no token.');
    }
    return token;
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path,
    String? authToken, [
    Map<String, dynamic>? body,
  ]) async {
    final requestClient = client ?? http.Client();
    try {
      final headers = <String, String>{'Accept': 'application/json'};
      if (body != null) headers['Content-Type'] = 'application/json';
      if (authToken != null) headers['Authorization'] = 'Bearer $authToken';
      final request = http.Request(method, Uri.parse('$_baseUrl$path'))
        ..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final response = await requestClient
          .send(request)
          .timeout(Duration(seconds: _configuredTimeoutSeconds))
          .then(http.Response.fromStream);
      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw PaymobException(
          'Paymob returned an invalid response (HTTP ${response.statusCode}).',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw PaymobException(
          'Paymob request failed (HTTP ${response.statusCode}).',
        );
      }
      if (decoded is! Map) {
        throw const PaymobException('Paymob returned an unexpected response.');
      }
      return Map<String, dynamic>.from(decoded);
    } finally {
      if (client == null) requestClient.close();
    }
  }

  String _config(String name, String? override) {
    final value = override ?? (dotenv.isInitialized ? dotenv.env[name] : null);
    if (value == null || value.trim().isEmpty) {
      throw PaymobException('$name is missing from the Flutter .env file.');
    }
    return value.trim();
  }

  String get _baseUrl {
    final configured = _config('PAYMOB_API_BASE_URL', apiBaseUrl);
    return configured.replaceFirst(RegExp(r'/+$'), '');
  }

  int get _configuredTimeoutSeconds {
    final configuredTimeout = timeoutSeconds;
    if (configuredTimeout != null && configuredTimeout > 0) {
      return configuredTimeout;
    }
    final configured = dotenv.isInitialized
        ? dotenv.env['PAYMOB_TIMEOUT_SECONDS']
        : null;
    final parsed = int.tryParse(configured ?? '');
    return parsed != null && parsed > 0 ? parsed : 30;
  }

  String _appRedirectUrl(String configured) {
    final uri = Uri.tryParse(configured);
    if (kIsWeb && uri?.host == 'localhost' && !uri!.hasPort) {
      return Uri.base.replace(queryParameters: uri.queryParameters).toString();
    }
    return configured;
  }

  static int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Map<String, dynamic>? _mapValue(dynamic value) {
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }
}

class PaymobCheckoutSession {
  const PaymobCheckoutSession({
    required this.paymobOrderId,
    required this.checkoutUrl,
  });

  final String paymobOrderId;
  final Uri checkoutUrl;
}

enum PaymobVerificationStatus { success, failed, pending }

class PaymobVerificationResult {
  const PaymobVerificationResult._(this.status, this.payment);

  const PaymobVerificationResult.success(VerifiedPaymobPayment payment)
    : this._(PaymobVerificationStatus.success, payment);

  static const failed = PaymobVerificationResult._(
    PaymobVerificationStatus.failed,
    null,
  );
  static const pending = PaymobVerificationResult._(
    PaymobVerificationStatus.pending,
    null,
  );

  final PaymobVerificationStatus status;
  final VerifiedPaymobPayment? payment;
}

class VerifiedPaymobPayment {
  const VerifiedPaymobPayment({
    required this.transactionId,
    required this.amountMinor,
    required this.merchantOrderId,
  });

  final String transactionId;
  final int amountMinor;
  final String merchantOrderId;
}

class PaymobException implements Exception {
  const PaymobException(this.message);

  final String message;

  @override
  String toString() => message;
}
