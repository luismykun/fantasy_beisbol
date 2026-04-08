import 'package:fantasy_mobile/src/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static final instance = SupabaseService._();

  bool _initialized = false;

  bool get isConfigured => AppConfig.hasSupabaseCredentials;

  SupabaseClient? get client {
    if (!_initialized || !isConfigured) {
      return null;
    }

    return Supabase.instance.client;
  }

  SupabaseClient get clientOrThrow {
    final currentClient = client;
    if (currentClient == null) {
      throw StateError(AppConfig.missingConfigMessage);
    }

    return currentClient;
  }

  Session? get currentSession => client?.auth.currentSession;

  User? get currentUser => client?.auth.currentUser;

  Stream<AuthState> get authStateChanges {
    if (!isConfigured || !_initialized) {
      return const Stream.empty();
    }

    return Supabase.instance.client.auth.onAuthStateChange;
  }

  Future<void> initialize() async {
    if (_initialized || !isConfigured) {
      return;
    }

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );

    _initialized = true;
  }

  Future<void> ensureProfileForCurrentUser() async {
    final currentClient = client;
    final user = currentUser;
    if (currentClient == null || user == null) {
      return;
    }

    final metadata = user.userMetadata ?? <String, dynamic>{};
    final displayName = (metadata['display_name'] as String?)?.trim();
    final username = (metadata['username'] as String?)?.trim();

    await currentClient.from('users_profile').upsert({
      'id': user.id,
      'username': username?.isEmpty == true ? null : username,
      'display_name': displayName?.isNotEmpty == true
          ? displayName
          : (user.email?.split('@').first ?? 'Manager'),
      'avatar_url': metadata['avatar_url'],
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'id');
  }
}
