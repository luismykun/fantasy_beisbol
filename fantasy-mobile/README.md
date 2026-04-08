# Fantasy Mobile

Cliente movil Flutter para el fantasy de beisbol con enfoque local-first.

## Estado actual

Este esqueleto fue creado manualmente porque `flutter` no esta instalado en el entorno actual. La arquitectura base ya separa:

- UI y navegacion basica
- autenticacion y sesion
- acceso a Supabase
- cache local SQLite
- cola simple de sincronizacion

## Stack previsto

- Flutter
- Supabase Auth + Postgres + Edge Functions
- SQLite local para cache y trabajo offline

## Configuracion

1. Instala Flutter y Android Studio.
2. Desde esta carpeta ejecuta `flutter pub get`.
3. Copia `lib/src/config/app_config.dart` y sustituye las credenciales placeholder de Supabase.
4. Ejecuta `flutter run`.

## Estructura

- `lib/main.dart`: bootstrap de la app
- `lib/src/app.dart`: composicion principal
- `lib/src/config/app_config.dart`: configuracion de entorno
- `lib/src/services/`: Supabase, cache local y sync
- `lib/src/features/`: pantallas y logica de producto

## Pendientes inmediatos

1. Instalar Flutter y validar compilacion.
2. Crear esquema real en Supabase.
3. Implementar login completo y sincronizacion por deltas.
4. Conectar calendario, ligas y draft con datos reales.
