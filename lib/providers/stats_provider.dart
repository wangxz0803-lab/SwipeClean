import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

class StatsProvider extends ChangeNotifier {
  final StorageService _storageService;

  StatsProvider(this._storageService);

  // --- Getters ---

  int get totalReviewed => _storageService.totalReviewed;
  int get totalDeleted => _storageService.totalDeleted;
  int get totalKept => _storageService.totalKept;
  int get totalFavorited => _storageService.totalFavorited;
  int get spaceSaved => _storageService.spaceSavedBytes;
  String get spaceSavedFormatted => StorageService.formatBytes(_storageService.spaceSavedBytes);
  int get currentStreak => _storageService.currentStreak;

  int get totalXp => _storageService.totalXp;
  int get level => _storageService.level;
  String get levelTitle => _storageService.levelTitle;
  double get levelProgress => _storageService.levelProgress;
  int get nextLevelXp => _storageService.nextLevelXp;
  int get currentLevelXp => _storageService.currentLevelXp;
  int get todayReviewed => _storageService.todayReviewed;
  int get dailyGoal => StorageService.dailyGoal;
  double get dailyProgress => _storageService.dailyProgress;
  bool get dailyGoalReached => _storageService.dailyGoalReached;

  int get keepRate {
    if (totalReviewed == 0) return 0;
    return (totalKept / totalReviewed * 100).round();
  }

  // --- Refresh ---

  void refresh() {
    notifyListeners();
  }
}
