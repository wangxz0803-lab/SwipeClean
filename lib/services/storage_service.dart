import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyTotalReviewed = 'total_reviewed';
  static const String _keyTotalDeleted = 'total_deleted';
  static const String _keyTotalKept = 'total_kept';
  static const String _keyTotalFavorited = 'total_favorited';
  static const String _keySpaceSavedBytes = 'space_saved_bytes';
  static const String _keyLastPhotoId = 'last_photo_id';
  static const String _keyCurrentStreak = 'current_streak';
  static const String _keyLastCleanDate = 'last_clean_date';
  static const String _keyTotalXp = 'total_xp';
  static const String _keyDailyReviewed = 'daily_reviewed';
  static const String _keyDailyDate = 'daily_date';

  static const int dailyGoal = 20;

  static const List<int> _levelThresholds = [
    0, 50, 150, 300, 500, 800, 1200, 1800, 2500, 3500,
  ];

  static const List<String> levelTitles = [
    '新手', '初级清理员', '清理学徒', '整理达人', '收纳专家',
    '清理大师', '整理狂人', '照片管家', '清理传奇', '终极整理王',
  ];

  late SharedPreferences _prefs;

  /// Initialize SharedPreferences instance.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Getters ---

  int get totalReviewed => _prefs.getInt(_keyTotalReviewed) ?? 0;
  int get totalDeleted => _prefs.getInt(_keyTotalDeleted) ?? 0;
  int get totalKept => _prefs.getInt(_keyTotalKept) ?? 0;
  int get totalFavorited => _prefs.getInt(_keyTotalFavorited) ?? 0;
  int get spaceSavedBytes => _prefs.getInt(_keySpaceSavedBytes) ?? 0;
  int get currentStreak => _prefs.getInt(_keyCurrentStreak) ?? 0;
  String? get lastCleanDate => _prefs.getString(_keyLastCleanDate);
  int get totalXp => _prefs.getInt(_keyTotalXp) ?? 0;

  int get level {
    final xp = totalXp;
    for (int i = _levelThresholds.length - 1; i >= 0; i--) {
      if (xp >= _levelThresholds[i]) return i;
    }
    return 0;
  }

  String get levelTitle => levelTitles[level];

  int get currentLevelXp => _levelThresholds[level];
  int get nextLevelXp => level < _levelThresholds.length - 1
      ? _levelThresholds[level + 1]
      : _levelThresholds.last;
  double get levelProgress {
    final range = nextLevelXp - currentLevelXp;
    if (range <= 0) return 1.0;
    return (totalXp - currentLevelXp) / range;
  }

  int get todayReviewed {
    final today = _dateString(DateTime.now());
    if (_prefs.getString(_keyDailyDate) != today) return 0;
    return _prefs.getInt(_keyDailyReviewed) ?? 0;
  }

  double get dailyProgress => (todayReviewed / dailyGoal).clamp(0.0, 1.0);
  bool get dailyGoalReached => todayReviewed >= dailyGoal;

  // --- Incrementers ---

  Future<void> incrementReviewed() async {
    await _prefs.setInt(_keyTotalReviewed, totalReviewed + 1);
  }

  Future<void> addDeleted(int bytes) async {
    await _prefs.setInt(_keyTotalDeleted, totalDeleted + 1);
    await _prefs.setInt(_keySpaceSavedBytes, spaceSavedBytes + bytes);
  }

  Future<void> incrementKept() async {
    await _prefs.setInt(_keyTotalKept, totalKept + 1);
  }

  Future<void> incrementFavorited() async {
    await _prefs.setInt(_keyTotalFavorited, totalFavorited + 1);
  }

  Future<int> addXp(int xp) async {
    final oldLevel = level;
    await _prefs.setInt(_keyTotalXp, totalXp + xp);
    return level - oldLevel;
  }

  Future<void> incrementDailyReviewed() async {
    final today = _dateString(DateTime.now());
    if (_prefs.getString(_keyDailyDate) != today) {
      await _prefs.setString(_keyDailyDate, today);
      await _prefs.setInt(_keyDailyReviewed, 1);
    } else {
      await _prefs.setInt(_keyDailyReviewed, todayReviewed + 1);
    }
  }

  Future<void> decrementDailyReviewed() async {
    final today = _dateString(DateTime.now());
    if (_prefs.getString(_keyDailyDate) == today) {
      final val = todayReviewed;
      if (val > 0) await _prefs.setInt(_keyDailyReviewed, val - 1);
    }
  }

  // --- Decrement helpers (for undo) ---

  Future<void> decrementReviewed() async {
    final val = totalReviewed;
    if (val > 0) await _prefs.setInt(_keyTotalReviewed, val - 1);
  }

  Future<void> removeDeleted(int bytes) async {
    final delVal = totalDeleted;
    if (delVal > 0) await _prefs.setInt(_keyTotalDeleted, delVal - 1);
    final spaceVal = spaceSavedBytes;
    await _prefs.setInt(_keySpaceSavedBytes, (spaceVal - bytes).clamp(0, spaceVal));
  }

  Future<void> decrementKept() async {
    final val = totalKept;
    if (val > 0) await _prefs.setInt(_keyTotalKept, val - 1);
  }

  Future<void> decrementFavorited() async {
    final val = totalFavorited;
    if (val > 0) await _prefs.setInt(_keyTotalFavorited, val - 1);
  }

  // --- Position ---

  Future<void> saveLastPosition(String photoId) async {
    await _prefs.setString(_keyLastPhotoId, photoId);
  }

  String? getLastPosition() {
    return _prefs.getString(_keyLastPhotoId);
  }

  // --- Streak ---

  Future<void> updateStreak() async {
    final today = _dateString(DateTime.now());
    final last = lastCleanDate;

    if (last == today) {
      // Already cleaned today, do nothing
      return;
    }

    final yesterday = _dateString(DateTime.now().subtract(const Duration(days: 1)));
    if (last == yesterday) {
      // Consecutive day - increment streak
      await _prefs.setInt(_keyCurrentStreak, currentStreak + 1);
    } else {
      // Streak broken or first time - reset to 1
      await _prefs.setInt(_keyCurrentStreak, 1);
    }

    await _prefs.setString(_keyLastCleanDate, today);
  }

  String _dateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // --- Reset ---

  Future<void> resetAll() async {
    await _prefs.remove(_keyTotalReviewed);
    await _prefs.remove(_keyTotalDeleted);
    await _prefs.remove(_keyTotalKept);
    await _prefs.remove(_keyTotalFavorited);
    await _prefs.remove(_keySpaceSavedBytes);
    await _prefs.remove(_keyLastPhotoId);
    await _prefs.remove(_keyCurrentStreak);
    await _prefs.remove(_keyLastCleanDate);
    await _prefs.remove(_keyTotalXp);
    await _prefs.remove(_keyDailyReviewed);
    await _prefs.remove(_keyDailyDate);
  }

  // --- Helpers ---

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 MB';
    const int mb = 1024 * 1024;
    const int gb = 1024 * 1024 * 1024;
    if (bytes >= gb) {
      final value = bytes / gb;
      return '${value.toStringAsFixed(1)} GB';
    }
    final value = bytes / mb;
    return '${value.round()} MB';
  }
}
