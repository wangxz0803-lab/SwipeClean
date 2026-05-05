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
