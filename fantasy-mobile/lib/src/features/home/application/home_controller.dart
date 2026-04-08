import 'package:fantasy_mobile/src/features/home/data/public_catalog_repository.dart';
import 'package:fantasy_mobile/src/models/home_feed.dart';
import 'package:flutter/foundation.dart';

class HomeController extends ChangeNotifier {
  HomeController({PublicCatalogRepository? repository})
      : _repository = repository ?? PublicCatalogRepository();

  final PublicCatalogRepository _repository;

  HomeFeed feed = const HomeFeed();
  bool isLoading = true;
  bool isSyncing = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      feed = await _repository.loadCachedFeed();
      isLoading = false;
      notifyListeners();

      await refresh(showLoading: false);
    } catch (error) {
      isLoading = false;
      errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> refresh({bool showLoading = false}) async {
    if (showLoading) {
      isLoading = true;
    }
    isSyncing = true;
    errorMessage = null;
    notifyListeners();

    try {
      feed = await _repository.syncAndLoad();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      isSyncing = false;
      notifyListeners();
    }
  }
}