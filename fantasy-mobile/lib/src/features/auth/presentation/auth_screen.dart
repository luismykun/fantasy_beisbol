import 'package:fantasy_mobile/src/config/app_config.dart';
import 'package:fantasy_mobile/src/features/auth/application/auth_controller.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late final AuthController _controller;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AuthController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await _controller.submit(
      email: _emailController.text,
      password: _passwordController.text,
      displayName: _displayNameController.text,
      username: _usernameController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final theme = Theme.of(context);

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Acceso',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sesion persistente con Supabase Auth y perfil sincronizado en SQLite local.',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 20),
                            if (_controller.isRegisterMode) ...[
                              TextFormField(
                                controller: _displayNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre visible',
                                ),
                                validator: (value) {
                                  if (!_controller.isRegisterMode) {
                                    return null;
                                  }
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Ingresa un nombre visible.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(labelText: 'Email'),
                              validator: (value) {
                                if (value == null || !value.contains('@')) {
                                  return 'Ingresa un email valido.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(labelText: 'Password'),
                              validator: (value) {
                                if (value == null || value.length < 6) {
                                  return 'Minimo 6 caracteres.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            if (!AppConfig.hasSupabaseCredentials)
                              const _AuthMessageCard(
                                message: 'Configuracion pendiente. Define SUPABASE_URL y SUPABASE_ANON_KEY para activar login.',
                              ),
                            if (_controller.errorMessage != null)
                              _AuthMessageCard(message: _controller.errorMessage!),
                            if (_controller.infoMessage != null)
                              _AuthMessageCard(message: _controller.infoMessage!),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _controller.isBusy || !AppConfig.hasSupabaseCredentials
                                    ? null
                                    : _submit,
                                child: _controller.isBusy
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Text(_controller.isRegisterMode ? 'Crear cuenta' : 'Entrar'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _controller.isBusy ? null : _controller.toggleMode,
                              child: Text(
                                _controller.isRegisterMode
                                    ? 'Ya tengo cuenta'
                                    : 'Crear una cuenta nueva',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AuthMessageCard extends StatelessWidget {
  const _AuthMessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFDE8E8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(message),
        ),
      ),
    );
  }
}