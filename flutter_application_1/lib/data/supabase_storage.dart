import 'package:flutter/foundation.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseBucket = String.fromEnvironment(
  'SUPABASE_STORAGE_BUCKET',
  defaultValue: 'jeweler-documents',
);

List<String> publicSupabaseImageUrls(dynamic value) {
  if (value is! List) return const [];

  return value
      .whereType<String>()
      .map((path) => path.trim())
      .where((path) => path.isNotEmpty)
      .map(publicSupabaseImageUrl)
      .whereType<String>()
      .toList(growable: false);
}

String? publicSupabaseImageUrl(String path) {
  if (path.startsWith('https://')) return path;
  if (_supabaseUrl.isEmpty || _supabaseBucket.isEmpty) return null;

  final encodedPath = path.split('/').map(Uri.encodeComponent).join('/');
  return '${_supabaseUrl.replaceFirst(RegExp(r'\/$'), '')}'
      '/storage/v1/object/public/${Uri.encodeComponent(_supabaseBucket)}'
      '/$encodedPath';
}

bool get isSupabaseConfigured => _supabaseUrl.isNotEmpty;

void logSupabaseConfigurationHint() {
  if (!isSupabaseConfigured) {
    debugPrint(
      'Supabase public images are disabled. Run Flutter with '
      '--dart-define=SUPABASE_URL=https://<project>.supabase.co.',
    );
  }
}
