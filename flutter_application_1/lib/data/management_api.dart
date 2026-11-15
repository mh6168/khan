import 'package:flutter/foundation.dart';

const _configuredBaseUrl = String.fromEnvironment('MANAGEMENT_API_BASE_URL');

String get managementApiBaseUrl {
  if (_configuredBaseUrl.trim().isNotEmpty) {
    return _configuredBaseUrl.trim().replaceFirst(RegExp(r'\/$'), '');
  }

  if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
    return 'http://localhost/khan-mgmt/khan-mgmt/public';
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2/khan-mgmt/khan-mgmt/public';
  }
  return 'http://localhost/khan-mgmt/khan-mgmt/public';
}

String productImageEndpoint(String path) {
  return '$managementApiBaseUrl/product-image.php'
      '?path=${Uri.encodeQueryComponent(path)}';
}
