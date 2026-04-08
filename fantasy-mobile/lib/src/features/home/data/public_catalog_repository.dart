import 'dart:convert';

import 'package:fantasy_mobile/src/models/game_summary.dart';
import 'package:fantasy_mobile/src/models/home_feed.dart';
import 'package:fantasy_mobile/src/models/player_summary.dart';
import 'package:fantasy_mobile/src/models/team_summary.dart';
import 'package:fantasy_mobile/src/services/local_db_service.dart';
import 'package:fantasy_mobile/src/services/sync_service.dart';

class PublicCatalogRepository {
  PublicCatalogRepository({
    LocalDbService? localDbService,
    SyncService? syncService,
  })  : _localDbService = localDbService ?? LocalDbService.instance,
        _syncService = syncService ?? SyncService.instance;

  final LocalDbService _localDbService;
  final SyncService _syncService;

  Future<HomeFeed> loadCachedFeed() async {
    final teamRows = await _localDbService.readRows(
      'local_reference_teams',
      orderBy: 'updated_at DESC',
      limit: 30,
    );
    final playerRows = await _localDbService.readRows(
      'local_reference_players',
      orderBy: 'updated_at DESC',
      limit: 20,
    );
    final gameRows = await _localDbService.readRows(
      'local_reference_games',
      orderBy: 'updated_at ASC',
      limit: 20,
    );

    return HomeFeed(
      teams: teamRows
          .map((row) => TeamSummary.fromMap(_decodePayload(row['payload'] as String)))
          .toList(),
      players: playerRows
          .map((row) => PlayerSummary.fromMap(_decodePayload(row['payload'] as String)))
          .toList(),
      games: gameRows
          .map((row) => GameSummary.fromMap(_decodePayload(row['payload'] as String)))
          .toList(),
    );
  }

  Future<HomeFeed> syncAndLoad() async {
    await _syncService.syncReferenceData();
    return loadCachedFeed();
  }

  Map<String, dynamic> _decodePayload(String rawJson) {
    return Map<String, dynamic>.from(jsonDecode(rawJson) as Map);
  }
}