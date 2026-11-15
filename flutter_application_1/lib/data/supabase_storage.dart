import 'package:flutter/foundation.dart';

import 'management_api.dart';

List<String> publicSupabaseImageUrls(dynamic value) {
  if (value is! List) return const [];

  return value
      .whereType<String>()
      .map((path) => path.trim())
      .where((path) => path.isNotEmpty)
      .map(productImageEndpoint)
      .whereType<String>()
      .toList(growable: false);
}

String? publicSupabaseImageUrl(String path) {
  if (path.startsWith('https://')) return path;
  return productImageEndpoint(path);
}

void logSupabaseImageError(String url, Object error) {
  debugPrint('Supabase image failed to load ($url): $error');
}

void logSupabaseConfigurationHint() {
  debugPrint(
    'Product images use the management signed-image endpoint. '
    'Current endpoint base: $managementApiBaseUrl',
  );
}
