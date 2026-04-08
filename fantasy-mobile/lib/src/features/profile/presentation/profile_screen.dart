import 'package:fantasy_mobile/src/config/app_config.dart';
import 'package:fantasy_mobile/src/features/auth/application/auth_controller.dart';
import 'package:fantasy_mobile/src/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = AuthController();
  }

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AppConfig.hasSupabaseCredentials
          ? SupabaseService.instance.authStateChanges
          : const Stream.empty(),
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        SupabaseService.instance.currentSession,
      ),
      builder: (context, snapshot) {
        final session = snapshot.data?.session;

        return AnimatedBuilder(
          animation: _authController,
          builder: (context, _) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Perfil',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Configuracion actual',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppConfig.hasSupabaseCredentials
                                ? 'Supabase configurado.'
                                : 'Supabase pendiente de configurar.',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            session?.user.email != null
                                ? 'Sesion activa: ${session!.user.email}'
                                : 'Sin sesion autenticada.',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppConfig.hasSupabaseCredentials
                                ? 'Auth y perfil local preparados para trabajar sobre Supabase.'
                                : AppConfig.missingConfigMessage,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (session != null)
                    FilledButton.icon(
                      onPressed: _authController.isBusy ? null : _authController.signOut,
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar sesion'),
                    ),
                  if (_authController.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(_authController.errorMessage!),
                  ],
                ],
              ),
            ),
          },
        );
      },
    );
  }
}