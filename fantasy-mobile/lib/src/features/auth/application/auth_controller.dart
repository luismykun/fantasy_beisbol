import 'package:fantasy_mobile/src/features/auth/data/auth_repository.dart';
import 'package:fantasy_mobile/src/services/sync_service.dart';
import 'package:flutter/foundation.dart';

class AuthController extends ChangeNotifier {
  AuthController({AuthRepository? repository})
      : _repository = repository ?? AuthRepository();

  final AuthRepository _repository;

  bool isRegisterMode = false;
  bool isBusy = false;
  String? errorMessage;
  String? infoMessage;

  void toggleMode() {
    isRegisterMode = !isRegisterMode;
    errorMessage = null;
    infoMessage = null;
    notifyListeners();
  }

  Future<bool> submit({
    required String email,
    required String password,
    String? displayName,
    String? username,
  }) async {
    isBusy = true;
    errorMessage = null;
    infoMessage = null;
    notifyListeners();

    try {
      if (isRegisterMode) {
        final result = await _repository.signUp(
          email: email,
          password: password,
          displayName: displayName ?? '',
          username: username,
        );
        infoMessage = result.message;
        await SyncService.instance.syncCurrentUserProfile();
        return !result.requiresEmailConfirmation;
      }

      await _repository.signIn(email: email, password: password);
      await SyncService.instance.syncCurrentUserProfile();
      await SyncService.instance.syncUserLeagues();
      return true;
    } catch (error) {
      errorMessage = error.toString();
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.signOut();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }
}