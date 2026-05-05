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

  int get keepRate {
    if (totalReviewed == 0) return 0;
    return (totalKept / totalReviewed * 100).round();
  }

  // --- Refresh ---

  void refresh() {
    notifyListeners();
  }
}
