import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

List<String> publicSupabaseImageUrls(dynamic value) {
  if (value is! List) return const [];

  final baseUrl = _environmentValue('SUPABASE_URL');
  final bucket = _environmentValue('SUPABASE_STORAGE_BUCKET');
  if (baseUrl == null || baseUrl.isEmpty || bucket == null || bucket.isEmpty) {
    logSupabaseConfigurationHint();
    return const [];
  }

  return value
      .whereType<String>()
      .map((path) => path.trim())
      .where((path) => path.isNotEmpty)
      .map((path) => _publicUrl(baseUrl, bucket, path))
      .toList(growable: false);
}

String publicSupabaseImageUrl(String path, {String? baseUrl, String? bucket}) {
  final configuredBaseUrl = baseUrl ?? _environmentValue('SUPABASE_URL');
  final configuredBucket =
      bucket ?? _environmentValue('SUPABASE_STORAGE_BUCKET');
  if (configuredBaseUrl == null ||
      configuredBaseUrl.isEmpty ||
      configuredBucket == null ||
      configuredBucket.isEmpty) {
    logSupabaseConfigurationHint();
    return '';
  }
  return _publicUrl(configuredBaseUrl, configuredBucket, path.trim());
}

String? _environmentValue(String name) {
  if (!dotenv.isInitialized) return null;
  return dotenv.env[name]?.trim();
}

String _publicUrl(String baseUrl, String bucket, String path) {
  if (path.startsWith('https://')) return path;

  final encodedPath = path.split('/').map(Uri.encodeComponent).join('/');
  return '${baseUrl.replaceFirst(RegExp(r'\/$'), '')}'
      '/storage/v1/object/public/${Uri.encodeComponent(bucket)}/$encodedPath';
}

void logSupabaseImageError(String url, Object error) {
  debugPrint('Supabase public image failed to load: $error');
}

void logSupabaseConfigurationHint() {
  debugPrint(
    'Supabase public images require SUPABASE_URL and '
    'SUPABASE_STORAGE_BUCKET in .env.',
  );
}
