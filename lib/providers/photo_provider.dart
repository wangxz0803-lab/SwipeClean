import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/photo_item.dart';
import '../models/swipe_action.dart';
import '../services/photo_service.dart';
import '../services/storage_service.dart';

class PhotoProvider extends ChangeNotifier {
  final PhotoService _photoService;
  final StorageService _storageService;

  List<PhotoItem> _photos = [];
  List<SwipeRecord> _history = [];
  List<PhotoItem> _pendingDeletes = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _permissionGranted = false;
  String? _selectedMonth;
  int _currentPage = 0;
  bool _hasMore = true;
  Map<String, int> _monthlyStats = {};
  bool _shuffleMode = false;
  int _lastXpGain = 0;
  int _lastLevelUp = 0;

  PhotoProvider(this._photoService, this._storageService);

  // --- Getters ---

  List<PhotoItem> get photos => _photos;
  PhotoItem? get currentPhoto =>
      _currentIndex < _photos.length ? _photos[_currentIndex] : null;
  bool get isLoading => _isLoading;
  bool get permissionGranted => _permissionGranted;
  bool get canUndo => _history.isNotEmpty;
  double get progress => _photos.isEmpty ? 0 : _currentIndex / _photos.length;
  int get remaining => max(0, _photos.length - _currentIndex);
  int get reviewed => _currentIndex;
  Map<String, int> get monthlyStats => _monthlyStats;
  int get pendingDeleteCount => _pendingDeletes.length;
  List<SwipeRecord> get history => _history;
  String? get selectedMonth => _selectedMonth;
  bool get hasMore => _hasMore;
  bool get shuffleMode => _shuffleMode;
  int get lastXpGain => _lastXpGain;
  int get lastLevelUp => _lastLevelUp;
  int get todayReviewed => _storageService.todayReviewed;
  double get dailyProgress => _storageService.dailyProgress;
  bool get dailyGoalReached => _storageService.dailyGoalReached;
  int get totalXp => _storageService.totalXp;
  int get level => _storageService.level;
  String get levelTitle => _storageService.levelTitle;

  // --- Init ---

  Future<void> init() async {
    _permissionGranted = await _photoService.requestPermission();
    if (!_permissionGranted) {
      notifyListeners();
      return;
    }
    _monthlyStats = await _photoService.getMonthlyStats();
    await loadPhotos();

    // Resume from last position
    final lastId = _storageService.getLastPosition();
    if (lastId != null) {
      final idx = _photos.indexWhere((p) => p.id == lastId);
      if (idx > 0) {
        _currentIndex = idx;
      }
    }

    notifyListeners();
  }

  // --- Load photos ---

  Future<void> loadPhotos() async {
    _isLoading = true;
    notifyListeners();

    try {
      List<PhotoItem> loaded;
      if (_selectedMonth != null) {
        final parts = _selectedMonth!.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        loaded = await _photoService.getPhotosByMonth(year, month);
        _hasMore = false; // Month loading gets all at once
      } else {
        loaded = await _photoService.getAllPhotos(
          page: _currentPage,
          pageSize: 50,
        );
        _hasMore = loaded.length >= 50;
      }
      _photos.addAll(loaded);
    } catch (e) {
      debugPrint('Error loading photos: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;
    _currentPage++;
    await loadPhotos();
  }

  // --- Month selection ---

  void selectMonth(String? monthKey) {
    _selectedMonth = monthKey;
    _currentIndex = 0;
    _currentPage = 0;
    _photos = [];
    _hasMore = true;
    loadPhotos();
  }

  // --- Shuffle mode ---

  void toggleShuffleMode() {
    _shuffleMode = !_shuffleMode;
    if (_shuffleMode) {
      final remaining = _photos.sublist(_currentIndex);
      remaining.shuffle(Random());
      _photos = [..._photos.sublist(0, _currentIndex), ...remaining];
    }
    notifyListeners();
  }

  // --- Swipe handling ---

  Future<void> handleSwipe(SwipeDirection direction) async {
    if (currentPhoto == null) return;

    final photo = currentPhoto!;
    final action = actionFromDirection(direction);
    int fileSize = 0;

    if (action == ActionType.delete) {
      fileSize = await photo.loadFileSize();
    }

    final record = SwipeRecord(
      photo: photo,
      action: action,
      fileSize: fileSize,
    );
    _history.add(record);

    switch (action) {
      case ActionType.delete:
        _pendingDeletes.add(photo);
        await _storageService.addDeleted(fileSize);
        break;
      case ActionType.keep:
        await _storageService.incrementKept();
        break;
      case ActionType.favorite:
        await _storageService.incrementFavorited();
        await _photoService.toggleFavorite(photo.id);
        break;
    }

    await _storageService.incrementReviewed();
    await _storageService.updateStreak();
    await _storageService.incrementDailyReviewed();

    final xpMap = {ActionType.delete: 10, ActionType.keep: 5, ActionType.favorite: 15};
    _lastXpGain = xpMap[action]!;
    _lastLevelUp = await _storageService.addXp(_lastXpGain);

    _currentIndex++;

    if (currentPhoto != null) {
      await _storageService.saveLastPosition(currentPhoto!.id);
    }

    // Preload more if near the end
    if (_hasMore && _photos.length - _currentIndex < 10) {
      loadMore();
    }

    notifyListeners();
  }

  // --- Undo ---

  Future<void> undo() async {
    if (_history.isEmpty) return;

    final record = _history.removeLast();

    switch (record.action) {
      case ActionType.delete:
        _pendingDeletes.remove(record.photo);
        await _storageService.removeDeleted(record.fileSize);
        break;
      case ActionType.keep:
        await _storageService.decrementKept();
        break;
      case ActionType.favorite:
        await _storageService.decrementFavorited();
        break;
    }

    await _storageService.decrementReviewed();
    await _storageService.decrementDailyReviewed();
    _currentIndex--;
    notifyListeners();
  }

  // --- Batch delete management ---

  Future<void> confirmDeletes() async {
    if (_pendingDeletes.isEmpty) return;
    final ids = _pendingDeletes.map((p) => p.id).toList();
    await _photoService.deletePhotos(ids);
    _pendingDeletes.clear();
    notifyListeners();
  }

  void cancelAllDeletes() {
    // Move pending deletes back into available photos — no actual deletion
    _pendingDeletes.clear();
    notifyListeners();
  }
}
