import 'package:fantasy_mobile/src/features/leagues/data/leagues_repository.dart';
import 'package:fantasy_mobile/src/models/league_summary.dart';
import 'package:flutter/foundation.dart';

class LeaguesController extends ChangeNotifier {
  LeaguesController({LeaguesRepository? repository})
      : _repository = repository ?? LeaguesRepository();

  final LeaguesRepository _repository;

  List<LeagueSummary> leagues = const <LeagueSummary>[];
  bool isLoading = true;
  bool isBusy = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      leagues = await _repository.loadCachedLeagues();
      isLoading = false;
      notifyListeners();

      await refresh(showLoading: false);
    } catch (error) {
      isLoading = false;
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> refresh({bool showLoading = true}) async {
    if (showLoading) {
      isLoading = true;
    }
    errorMessage = null;
    notifyListeners();

    try {
      leagues = await _repository.syncAndLoad();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createLeague({
    required String leagueName,
    required String fantasyTeamName,
  }) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.createLeague(
        leagueName: leagueName,
        fantasyTeamName: fantasyTeamName,
      );
      leagues = await _repository.loadCachedLeagues();
      return true;
    } catch (error) {
      errorMessage = error.toString();
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> joinLeague({
    required String inviteCode,
    required String fantasyTeamName,
  }) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.joinLeague(
        inviteCode: inviteCode,
        fantasyTeamName: fantasyTeamName,
      );
      leagues = await _repository.loadCachedLeagues();
      return true;
    } catch (error) {
      errorMessage = error.toString();
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }
}