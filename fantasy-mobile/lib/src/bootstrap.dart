import 'package:fantasy_mobile/src/services/local_db_service.dart';
import 'package:fantasy_mobile/src/services/supabase_service.dart';
import 'package:fantasy_mobile/src/services/sync_service.dart';

Future<void> bootstrap() async {
  await SupabaseService.instance.initialize();
  await LocalDbService.instance.initialize();

  if (SupabaseService.instance.currentUser != null) {
    await SupabaseService.instance.ensureProfileForCurrentUser();
    await SyncService.instance.syncCurrentUserProfile();
  } else {
    await LocalDbService.instance.clearSession();
  }
}
