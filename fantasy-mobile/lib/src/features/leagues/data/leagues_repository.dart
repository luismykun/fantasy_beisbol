import 'dart:convert';

import 'package:fantasy_mobile/src/models/league_summary.dart';
import 'package:fantasy_mobile/src/services/local_db_service.dart';
import 'package:fantasy_mobile/src/services/supabase_service.dart';
import 'package:fantasy_mobile/src/services/sync_service.dart';

class LeaguesRepository {
  LeaguesRepository({
    LocalDbService? localDbService,
    SupabaseService? supabaseService,
    SyncService? syncService,
  })  : _localDbService = localDbService ?? LocalDbService.instance,
        _supabaseService = supabaseService ?? SupabaseService.instance,
        _syncService = syncService ?? SyncService.instance;

  final LocalDbService _localDbService;
  final SupabaseService _supabaseService;
  final SyncService _syncService;

  Future<List<LeagueSummary>> loadCachedLeagues() async {
    final leaguesRows = await _localDbService.readRows(
      'local_user_leagues',
      orderBy: 'updated_at DESC',
    );
    final fantasyTeamRows = await _localDbService.readRows(
      'local_user_fantasy_teams',
      orderBy: 'updated_at DESC',
    );

    final fantasyTeamsByLeague = <String, String>{
      for (final row in fantasyTeamRows)
        (_decodePayload(row['payload'] as String)['league_id'] as String? ?? ''):
            (_decodePayload(row['payload'] as String)['name'] as String? ?? ''),
    };

    return leaguesRows.map((row) {
      final payload = _decodePayload(row['payload'] as String);
      return LeagueSummary.fromMap(
        payload,
        fantasyTeamName: fantasyTeamsByLeague[payload['id'] as String? ?? ''],
      );
    }).toList();
  }

  Future<List<LeagueSummary>> syncAndLoad() async {
    await _syncService.syncUserLeagues();
    return loadCachedLeagues();
  }

  Future<void> createLeague({
    required String leagueName,
    required String fantasyTeamName,
  }) async {
    await _supabaseService.clientOrThrow.rpc(
      'create_league_with_team',
      params: {
        'league_name': leagueName.trim(),
        'team_name': fantasyTeamName.trim(),
      },
    );
    await _syncService.syncUserLeagues();
  }

  Future<void> joinLeague({
    required String inviteCode,
    required String fantasyTeamName,
  }) async {
    await _supabaseService.clientOrThrow.rpc(
      'join_league_by_code',
      params: {
        'invite_code_input': inviteCode.trim().toUpperCase(),
        'team_name': fantasyTeamName.trim(),
      },
    );
    await _syncService.syncUserLeagues();
  }

  Map<String, dynamic> _decodePayload(String rawJson) {
    return Map<String, dynamic>.from(jsonDecode(rawJson) as Map);
  }
}