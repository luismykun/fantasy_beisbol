import 'package:fantasy_mobile/src/services/supabase_service.dart';

class AuthActionResult {
  const AuthActionResult({
    this.requiresEmailConfirmation = false,
    this.message,
  });

  final bool requiresEmailConfirmation;
  final String? message;
}

class AuthRepository {
  AuthRepository({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService.instance;

  final SupabaseService _supabaseService;

  Future<AuthActionResult> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabaseService.clientOrThrow.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );

    if (response.user != null) {
      await _supabaseService.ensureProfileForCurrentUser();
    }

    return const AuthActionResult();
  }

  Future<AuthActionResult> signUp({
    required String email,
    required String password,
    required String displayName,
    String? username,
  }) async {
    final response = await _supabaseService.clientOrThrow.auth.signUp(
          email: email.trim(),
          password: password,
          data: {
            'display_name': displayName.trim(),
            'username': username?.trim(),
          },
        );

    if (response.session != null) {
      await _supabaseService.ensureProfileForCurrentUser();
    }

    return AuthActionResult(
      requiresEmailConfirmation: response.session == null,
      message: response.session == null
          ? 'Registro creado. Revisa tu correo para confirmar la cuenta.'
          : 'Cuenta creada correctamente.',
    );
  }

  Future<void> signOut() {
    return _supabaseService.clientOrThrow.auth.signOut();
  }
}