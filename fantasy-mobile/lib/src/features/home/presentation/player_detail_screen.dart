import 'package:fantasy_mobile/src/models/player_summary.dart';
import 'package:fantasy_mobile/src/models/team_summary.dart';
import 'package:flutter/material.dart';

class PlayerDetailScreen extends StatelessWidget {
  const PlayerDetailScreen({
    super.key,
    required this.player,
    this.team,
  });

  final PlayerSummary player;
  final TeamSummary? team;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(player.fullName)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.fullName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text('Posicion: ${player.position ?? 'N/D'}'),
                    Text('Equipo: ${team?.name ?? 'N/D'}'),
                    Text('Estado: ${player.status ?? 'active'}'),
                    const SizedBox(height: 12),
                    const Text(
                      'Detalle inicial listo para extender con stats por juego, promedios y disponibilidad.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}