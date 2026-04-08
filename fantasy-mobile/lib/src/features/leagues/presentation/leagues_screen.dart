import 'package:fantasy_mobile/src/config/app_config.dart';
import 'package:fantasy_mobile/src/features/leagues/application/leagues_controller.dart';
import 'package:flutter/material.dart';

class LeaguesScreen extends StatefulWidget {
  const LeaguesScreen({super.key});

  @override
  State<LeaguesScreen> createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends State<LeaguesScreen> {
  late final LeaguesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LeaguesController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openCreateLeagueSheet() async {
    final leagueNameController = TextEditingController();
    final fantasyTeamController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _LeagueActionSheet(
          title: 'Crear liga',
          firstLabel: 'Nombre de la liga',
          secondLabel: 'Nombre de tu fantasy team',
          firstController: leagueNameController,
          secondController: fantasyTeamController,
          onSubmit: () async {
            final created = await _controller.createLeague(
              leagueName: leagueNameController.text,
              fantasyTeamName: fantasyTeamController.text,
            );
            if (!mounted) {
              return;
            }
            if (created) {
              Navigator.of(context).pop();
            }
          },
        );
      },
    );
    leagueNameController.dispose();
    fantasyTeamController.dispose();
  }

  Future<void> _openJoinLeagueSheet() async {
    final inviteCodeController = TextEditingController();
    final fantasyTeamController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _LeagueActionSheet(
          title: 'Unirse por codigo',
          firstLabel: 'Codigo de invitacion',
          secondLabel: 'Nombre de tu fantasy team',
          firstController: inviteCodeController,
          secondController: fantasyTeamController,
          onSubmit: () async {
            final joined = await _controller.joinLeague(
              inviteCode: inviteCodeController.text,
              fantasyTeamName: fantasyTeamController.text,
            );
            if (!mounted) {
              return;
            }
            if (joined) {
              Navigator.of(context).pop();
            }
          },
        );
      },
    );
    inviteCodeController.dispose();
    fantasyTeamController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return RefreshIndicator(
          onRefresh: _controller.refresh,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Mis ligas',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              if (!AppConfig.hasSupabaseCredentials)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Configura Supabase para crear o unirte a ligas.'),
                  ),
                ),
              if (_controller.errorMessage != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(_controller.errorMessage!),
                  ),
                ),
              const SizedBox(height: 12),
              if (_controller.isLoading && _controller.leagues.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (_controller.leagues.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No hay ligas locales todavía. Crea una o únete con código.'),
                  ),
                )
              else
                ..._controller.leagues.map(
                  (league) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LeagueCard(
                      title: league.name,
                      subtitle:
                          '${league.fantasyTeamName ?? 'Mi equipo'} • ${league.draftState} • ${league.inviteCode}',
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _controller.isBusy || !AppConfig.hasSupabaseCredentials
                          ? null
                          : _openCreateLeagueSheet,
                      icon: const Icon(Icons.add),
                      label: const Text('Crear liga'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _controller.isBusy || !AppConfig.hasSupabaseCredentials
                          ? null
                          : _openJoinLeagueSheet,
                      icon: const Icon(Icons.login),
                      label: const Text('Unirse'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LeagueCard extends StatelessWidget {
  const _LeagueCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _LeagueActionSheet extends StatelessWidget {
  const _LeagueActionSheet({
    required this.title,
    required this.firstLabel,
    required this.secondLabel,
    required this.firstController,
    required this.secondController,
    required this.onSubmit,
  });

  final String title;
  final String firstLabel;
  final String secondLabel;
  final TextEditingController firstController;
  final TextEditingController secondController;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: firstController,
            decoration: InputDecoration(labelText: firstLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: secondController,
            decoration: InputDecoration(labelText: secondLabel),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onSubmit,
              child: const Text('Guardar'),
            ),
          ),
        ],
      ),
    );
  }
}
