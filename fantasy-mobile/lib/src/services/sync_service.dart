import 'dart:convert';

import 'package:fantasy_mobile/src/services/local_db_service.dart';
import 'package:fantasy_mobile/src/services/supabase_service.dart';

class SyncService {
  SyncService._();

  static final instance = SyncService._();

  Future<void> queueJob({
    required String jobType,
    Map<String, dynamic>? payload,
  }) async {
    final now = DateTime.now().toIso8601String();

    await LocalDbService.instance.database.insert('local_sync_jobs', {
      'job_type': jobType,
      'payload': jsonEncode(payload ?? <String, dynamic>{}),
      'status': 'pending',
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> syncBootstrapData() async {
    await syncReferenceData();
  }

  Future<void> syncReferenceData() async {
    final client = SupabaseService.instance.client;
    if (client == null) {
      return;
    }

    final teams = await _fetchDeltaRows(
      table: 'teams',
      select: 'id, name, short_name, logo_url, updated_at',
      orderColumn: 'updated_at',
      metaKey: 'teams_last_sync_at',
    );
    final players = await _fetchDeltaRows(
      table: 'players',
      select: 'id, full_name, position, team_id, status, updated_at',
      orderColumn: 'updated_at',
      metaKey: 'players_last_sync_at',
    );
    final games = await _fetchDeltaRows(
      table: 'games',
      select: 'id, starts_at, home_team_id, away_team_id, status, home_score, away_score, updated_at',
      orderColumn: 'updated_at',
      metaKey: 'games_last_sync_at',
    );
    final gameStats = await _fetchDeltaRows(
      table: 'player_game_stats',
      select: 'id, game_id, player_id, stat_line_json, fantasy_points_cached, updated_at',
      orderColumn: 'updated_at',
      metaKey: 'game_stats_last_sync_at',
    );

    await LocalDbService.instance.upsertJsonRows('local_reference_teams', teams);
    await LocalDbService.instance.upsertJsonRows('local_reference_players', players);
    await LocalDbService.instance.upsertJsonRows('local_reference_games', games);
    await LocalDbService.instance.upsertJsonRows('local_reference_game_stats', gameStats);
  }

  Future<void> syncCurrentUserProfile() async {
    final client = SupabaseService.instance.client;
    final user = SupabaseService.instance.currentUser;
    if (client == null || user == null) {
      await LocalDbService.instance.clearSession();
      return;
    }

    await LocalDbService.instance.cacheSession(
      userId: user.id,
      email: user.email,
      accessToken: SupabaseService.instance.currentSession?.accessToken,
    );

    final rows = List<Map<String, dynamic>>.from(
      await client
          .from('users_profile')
          .select('id, username, display_name, avatar_url, updated_at')
          .eq('id', user.id)
          .limit(1),
    );

    if (rows.isNotEmpty) {
      await LocalDbService.instance.upsertProfile(rows.first);
    }
  }

  Future<void> syncUserLeagues() async {
    final client = SupabaseService.instance.client;
    final user = SupabaseService.instance.currentUser;
    if (client == null || user == null) {
      return;
    }

    final leagues = List<Map<String, dynamic>>.from(
      await client
          .from('leagues')
          .select('id, name, invite_code, draft_state, created_at, updated_at')
          .order('created_at', ascending: false),
    );
    final fantasyTeams = List<Map<String, dynamic>>.from(
      await client
          .from('fantasy_teams')
          .select('id, league_id, user_id, name, created_at, updated_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false),
    );
    final notifications = List<Map<String, dynamic>>.from(
      await client
          .from('notifications')
          .select('id, type, payload_json, read_at, created_at, updated_at')
          .order('created_at', ascending: false)
          .limit(50),
    );

    await LocalDbService.instance.upsertJsonRows('local_user_leagues', leagues);
    await LocalDbService.instance.upsertJsonRows('local_user_fantasy_teams', fantasyTeams);
    await LocalDbService.instance.upsertJsonRows('local_user_notifications', notifications);
  }

  Future<void> processPendingJobs() async {
    final db = LocalDbService.instance.database;
    final jobs = await db.query(
      'local_sync_jobs',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
      limit: 20,
    );

    for (final job in jobs) {
      final jobId = job['id'] as int;
      await db.update(
        'local_sync_jobs',
        {
          'status': 'running',
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [jobId],
      );

      final jobType = job['job_type'] as String;
      if (jobType == 'refresh_reference_data') {
        await syncReferenceData();
      }

      await db.update(
        'local_sync_jobs',
        {
          'status': 'completed',
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [jobId],
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchDeltaRows({
    required String table,
    required String select,
    required String orderColumn,
    required String metaKey,
  }) async {
    final client = SupabaseService.instance.client;
    if (client == null) {
      return const <Map<String, dynamic>>[];
    }

    final lastSync = await LocalDbService.instance.getMeta(metaKey);
    dynamic query = client.from(table).select(select);
    if (lastSync != null && lastSync.isNotEmpty) {
      query = query.gte(orderColumn, lastSync);
    }

    final rows = List<Map<String, dynamic>>.from(
      await query.order(orderColumn, ascending: true),
    );
    if (rows.isNotEmpty) {
      final newestValue = rows.last[orderColumn] as String?;
      if (newestValue != null && newestValue.isNotEmpty) {
        await LocalDbService.instance.setMeta(metaKey, newestValue);
      }
    }

    return rows;
  }
}
