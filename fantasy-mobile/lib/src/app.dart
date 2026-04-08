import 'package:fantasy_mobile/src/config/app_config.dart';
import 'package:fantasy_mobile/src/features/auth/presentation/auth_screen.dart';
import 'package:fantasy_mobile/src/features/root/presentation/root_screen.dart';
import 'package:fantasy_mobile/src/services/supabase_service.dart';
import 'package:fantasy_mobile/src/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FantasyMobileApp extends StatelessWidget {
  const FantasyMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _AppSessionGate(),
    );
  }
}

class _AppSessionGate extends StatelessWidget {
  const _AppSessionGate();

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.hasSupabaseCredentials) {
      return const RootScreen(readOnlyMode: true);
    }

    return StreamBuilder<AuthState>(
      stream: SupabaseService.instance.authStateChanges,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        SupabaseService.instance.currentSession,
      ),
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        if (session == null) {
          return const AuthScreen();
        }

        return const RootScreen();
      },
    );
  }
}
