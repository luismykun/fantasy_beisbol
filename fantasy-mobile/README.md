# Fantasy Mobile

Cliente movil Flutter para fantasy beisbol con arquitectura local-first, Supabase como backend minimo y SQLite como cache oficial del dispositivo.

## Estado actual

La base del proyecto ya incluye:

- shell Flutter con navegacion inferior
- bootstrap robusto con modo local si faltan credenciales
- autenticacion email/password con Supabase
- persistencia de sesion y perfil en cache local
- cache SQLite ampliada para catalogos, ligas, notificaciones y cola de sync
- carga real de equipos, jugadores y juegos desde Supabase hacia SQLite
- listado de jugadores, detalle simple y calendario basico
- creacion y union a ligas via funciones RPC en Supabase

## Bloqueo real del entorno

En este contenedor Linux no existe Flutter ni Dart en PATH.

Comprobaciones ejecutadas:

- `command -v flutter` -> `FLUTTER_NOT_FOUND`
- `command -v dart` -> `DART_NOT_FOUND`
- `flutter pub get` -> `bash: flutter: command not found`

Por eso no fue posible ejecutar:

- `flutter --version`
- `flutter create .`
- `flutter pub get` con exito
- compilacion real del APK

El codigo se dejo preparado para compilar cuando el SDK quede instalado correctamente.

## Configuracion del SDK Flutter

En la maquina objetivo deja un unico SDK funcional y aseguralo en PATH.

Pasos recomendados en Windows:

1. Elige un solo SDK valido, por ejemplo `C:\src\flutter`.
2. Verifica que exista `C:\src\flutter\bin\flutter.bat`.
3. Agrega `C:\src\flutter\bin` al PATH del usuario.
4. Ejecuta `flutter doctor`.
5. En la carpeta del proyecto ejecuta `flutter create .` para generar `android/`, `ios/`, `web/`, `test/` y metadatos faltantes.
6. Ejecuta `flutter pub get`.

## Configuracion de Supabase

La app ya no hardcodea secretos. Usa `String.fromEnvironment` y define variables en runtime.

Archivo de ejemplo: `.env.example`

Ejemplo de uso:

```bash
flutter run --dart-define-from-file=.env
```

Variables requeridas:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

## Esquema y seguridad

Archivo principal: `supabase/schema.sql`

Incluye:

- tablas canonicas del fantasy y de datos publicos
- columnas `updated_at` para sync incremental
- triggers para mantener `updated_at`
- RLS para datos publicos y datos privados por membresia
- funcion RPC sensible `create_league_with_team`
- funcion RPC sensible `join_league_by_code`

Tablas backend previstas:

- `users_profile`
- `seasons`
- `teams`
- `players`
- `games`
- `player_game_stats`
- `leagues`
- `league_members`
- `fantasy_teams`
- `drafts`
- `draft_picks`
- `rosters`
- `lineup_entries`
- `standings_snapshots`
- `notifications`
- `provider_runs`

Tablas locales SQLite creadas por la app:

- `local_session`
- `local_profile`
- `local_reference_teams`
- `local_reference_players`
- `local_reference_games`
- `local_reference_game_stats`
- `local_user_leagues`
- `local_user_fantasy_teams`
- `local_user_rosters`
- `local_user_lineups`
- `local_user_notifications`
- `local_standings_cache`
- `local_sync_jobs`
- `local_dirty_entities`
- `local_kv_meta`

## Estructura actual

- `lib/src/features/auth/`: auth presentation, controller y repository
- `lib/src/features/home/`: lectura local-first de catalogos publicos
- `lib/src/features/leagues/`: lectura local-first y acciones de ligas
- `lib/src/features/profile/`: estado de sesion y logout
- `lib/src/models/`: modelos ligeros del cliente
- `lib/src/services/`: Supabase, SQLite y sincronizacion

## Que ya funciona en codigo

- bootstrap sin romper la app cuando faltan credenciales
- flujo de login/registro con email y password
- upsert de `users_profile` para usuario autenticado
- lectura local primero y refresco remoto despues
- sincronizacion incremental basica con `updated_at`
- cache local de equipos, jugadores, juegos, ligas y notificaciones
- crear liga y unirse por codigo usando RPC en backend

## Que sigue pendiente

1. Ejecutar `flutter create .` y `flutter pub get` cuando el SDK quede reparado.
2. Probar compilacion Android real y corregir cualquier error del toolchain.
3. Completar lectura real de drafts, picks, rosters y standings en UI.
4. Agregar acciones offline pendientes para lineups y roster moves.
5. Si el draft requiere picks oficiales desde cliente, mover esa accion a RPC adicional o Edge Function.
