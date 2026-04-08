class AppConfig {
  static const appName = 'Fantasy Beisbol';
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get hasSupabaseCredentials {
    return supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  }

  static String get missingConfigMessage {
    return 'Faltan SUPABASE_URL y SUPABASE_ANON_KEY. Usa --dart-define o --dart-define-from-file.';
  }
}
