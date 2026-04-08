import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class LocalDbService {
  LocalDbService._();

  static final instance = LocalDbService._();

  Database? _database;

  static const _databaseVersion = 2;

  static const _tableDefinitions = <String, String>{
    'local_session': '''
      CREATE TABLE local_session (
        id TEXT PRIMARY KEY,
        email TEXT,
        access_token TEXT,
        refreshed_at TEXT,
        updated_at TEXT
      )
    ''',
    'local_profile': '''
      CREATE TABLE local_profile (
        id TEXT PRIMARY KEY,
        username TEXT,
        display_name TEXT,
        avatar_url TEXT,
        updated_at TEXT,
        sync_state TEXT
      )
    ''',
    'local_reference_teams': '''
      CREATE TABLE local_reference_teams (
        id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        updated_at TEXT,
        sync_state TEXT
      )
    ''',
    'local_reference_players': '''
      CREATE TABLE local_reference_players (
        id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        updated_at TEXT,
        sync_state TEXT
      )
    ''',
    'local_reference_games': '''
      CREATE TABLE local_reference_games (
        id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        updated_at TEXT,
        sync_state TEXT
      )
    ''',
    'local_reference_game_stats': '''
      CREATE TABLE local_reference_game_stats (
        id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        updated_at TEXT,
        sync_state TEXT
      )
    ''',
    'local_user_leagues': '''
      CREATE TABLE local_user_leagues (
        id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        updated_at TEXT,
        sync_state TEXT
      )
    ''',
    'local_user_fantasy_teams': '''
      CREATE TABLE local_user_fantasy_teams (
        id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        updated_at TEXT,
        sync_state TEXT
      )
    ''',
    'local_user_rosters': '''
      CREATE TABLE local_user_rosters (
        id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        updated_at TEXT,
        sync_state TEXT
      )
    ''',
    'local_user_lineups': '''
      CREATE TABLE local_user_lineups (
        id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        updated_at TEXT,
        sync_state TEXT
      )
    ''',
    'local_user_notifications': '''
      CREATE TABLE local_user_notifications (
        id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        updated_at TEXT,
        sync_state TEXT
      )
    ''',
    'local_standings_cache': '''
      CREATE TABLE local_standings_cache (
        id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        updated_at TEXT,
        sync_state TEXT
      )
    ''',
    'local_sync_jobs': '''
      CREATE TABLE local_sync_jobs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        job_type TEXT NOT NULL,
        payload TEXT,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''',
    'local_dirty_entities': '''
      CREATE TABLE local_dirty_entities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        payload TEXT,
        action_type TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(entity_type, entity_id, action_type)
      )
    ''',
    'local_kv_meta': '''
      CREATE TABLE local_kv_meta (
        meta_key TEXT PRIMARY KEY,
        meta_value TEXT,
        updated_at TEXT
      )
    ''',
  };

  Database get database {
    final database = _database;
    if (database == null) {
      throw StateError('LocalDbService has not been initialized.');
    }

    return database;
  }

  Future<void> initialize() async {
    if (_database != null) {
      return;
    }

    final basePath = await getDatabasesPath();
    final databasePath = path.join(basePath, 'fantasy_mobile.db');

    _database = await openDatabase(
      databasePath,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await _createAllTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createAllTables(db);
        }
      },
    );
  }

  Future<void> _createAllTables(Database db) async {
    for (final definition in _tableDefinitions.values) {
      await db.execute(definition);
    }
  }

  Future<void> cacheSession({
    required String userId,
    String? email,
    String? accessToken,
  }) async {
    final now = DateTime.now().toIso8601String();
    await database.insert(
      'local_session',
      {
        'id': userId,
        'email': email,
        'access_token': accessToken,
        'refreshed_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearSession() async {
    await database.delete('local_session');
  }

  Future<void> upsertProfile(Map<String, dynamic> profile) async {
    await database.insert(
      'local_profile',
      {
        'id': profile['id'],
        'username': profile['username'],
        'display_name': profile['display_name'],
        'avatar_url': profile['avatar_url'],
        'updated_at': profile['updated_at'] ?? DateTime.now().toIso8601String(),
        'sync_state': 'synced',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertJsonRows(String table, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) {
      return;
    }

    await database.transaction((txn) async {
      for (final row in rows) {
        await txn.insert(
          table,
          {
            'id': row['id'],
            'payload': jsonEncode(row),
            'updated_at': row['updated_at'] ?? row['created_at'] ?? DateTime.now().toIso8601String(),
            'sync_state': 'synced',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Map<String, Object?>>> readRows(
    String table, {
    String orderBy = 'updated_at DESC',
    int? limit,
  }) async {
    return database.query(table, orderBy: orderBy, limit: limit);
  }

  Future<void> setMeta(String key, String value) async {
    await database.insert(
      'local_kv_meta',
      {
        'meta_key': key,
        'meta_value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getMeta(String key) async {
    final rows = await database.query(
      'local_kv_meta',
      where: 'meta_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }

    return rows.first['meta_value'] as String?;
  }

  Future<void> upsertDirtyEntity({
    required String entityType,
    required String entityId,
    required String actionType,
    Map<String, dynamic>? payload,
    String status = 'pending',
  }) async {
    final now = DateTime.now().toIso8601String();
    await database.insert(
      'local_dirty_entities',
      {
        'entity_type': entityType,
        'entity_id': entityId,
        'payload': jsonEncode(payload ?? <String, dynamic>{}),
        'action_type': actionType,
        'status': status,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
