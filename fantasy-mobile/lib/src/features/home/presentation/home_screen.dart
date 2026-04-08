import 'package:fantasy_mobile/src/features/home/application/home_controller.dart';
import 'package:fantasy_mobile/src/features/home/presentation/player_detail_screen.dart';
import 'package:fantasy_mobile/src/models/game_summary.dart';
import 'package:fantasy_mobile/src/models/player_summary.dart';
import 'package:fantasy_mobile/src/models/team_summary.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final teamById = {
          for (final team in _controller.feed.teams) team.id: team,
        };

        return RefreshIndicator(
          onRefresh: _controller.refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              const _HomeHeader(),
              const SizedBox(height: 16),
              _ActionCard(
                syncing: _controller.isSyncing,
                onPressed: () => _controller.refresh(showLoading: false),
              ),
              const SizedBox(height: 16),
              _StatusCard(
                loading: _controller.isLoading,
                errorMessage: _controller.errorMessage,
                teamCount: _controller.feed.teams.length,
                playerCount: _controller.feed.players.length,
                gameCount: _controller.feed.games.length,
              ),
              const SizedBox(height: 16),
              _TeamsCard(teams: _controller.feed.teams),
              const SizedBox(height: 16),
              _PlayersCard(
                players: _controller.feed.players,
                teamById: teamById,
              ),
              const SizedBox(height: 16),
              _GamesCard(
                games: _controller.feed.games,
                teamById: teamById,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fantasy Beisbol',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'MVP local-first con backend minimo, cache en el telefono y sync por deltas.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: const Color(0xFF51606F),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.syncing, required this.onPressed});

  final bool syncing;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Primer Sync',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Carga equipos, jugadores y juegos desde Supabase hacia SQLite local para trabajar con cache inmediata.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: syncing ? null : onPressed,
              icon: syncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(syncing ? 'Sincronizando...' : 'Ejecutar sync'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.loading,
    required this.errorMessage,
    required this.teamCount,
    required this.playerCount,
    required this.gameCount,
  });

  final bool loading;
  final String? errorMessage;
  final int teamCount;
  final int playerCount;
  final int gameCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estado del MVP',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(loading ? 'Sincronizando cache local...' : 'Cache local lista para lectura inmediata.'),
            Text('Equipos locales: $teamCount'),
            Text('Jugadores locales: $playerCount'),
            Text('Juegos locales: $gameCount'),
            if (errorMessage != null) ...[
              const SizedBox(height: 8),
              Text('Ultimo error: $errorMessage'),
            ],
          ],
        ),
      ),
    );
  }
}

class _TeamsCard extends StatelessWidget {
  const _TeamsCard({required this.teams});

  final List<TeamSummary> teams;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Equipos cacheados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (teams.isEmpty)
              const Text('Aun no hay equipos locales. Ejecuta sync para traer catalogos.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: teams
                    .map(
                      (team) => Chip(label: Text(team.shortName ?? team.name)),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayersCard extends StatelessWidget {
  const _PlayersCard({required this.players, required this.teamById});

  final List<PlayerSummary> players;
  final Map<String, TeamSummary> teamById;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jugadores',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (players.isEmpty)
              const Text('No hay jugadores en cache local todavía.')
            else
              ...players.map(
                (player) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(player.fullName),
                  subtitle: Text(
                    '${player.position ?? 'N/D'} • ${teamById[player.teamId]?.name ?? 'Sin equipo'}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PlayerDetailScreen(
                          player: player,
                          team: teamById[player.teamId],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GamesCard extends StatelessWidget {
  const _GamesCard({required this.games, required this.teamById});

  final List<GameSummary> games;
  final Map<String, TeamSummary> teamById;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calendario',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (games.isEmpty)
              const Text('No hay juegos cacheados todavía.')
            else
              ...games.map(
                (game) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${teamById[game.awayTeamId]?.shortName ?? 'VIS'} @ ${teamById[game.homeTeamId]?.shortName ?? 'LOC'}',
                  ),
                  subtitle: Text(game.startsAt ?? 'Sin fecha'),
                  trailing: Text(
                    game.homeScore != null && game.awayScore != null
                        ? '${game.awayScore}-${game.homeScore}'
                        : game.status,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
