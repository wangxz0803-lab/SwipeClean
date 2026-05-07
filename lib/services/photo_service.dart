import 'dart:ui' as ui;
import 'package:photo_manager/photo_manager.dart';
import '../models/photo_item.dart';

class PhotoService {
  /// Request photo library access. Returns true if granted.
  Future<bool> requestPermission() async {
    final permission = await PhotoManager.requestPermissionExtend();
    return permission.isAuth;
  }

  /// Get all photo albums.
  Future<List<AssetPathEntity>> getAlbums() async {
    return await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
    );
  }

  /// Load photos paginated, sorted by date descending.
  Future<List<PhotoItem>> getAllPhotos({int page = 0, int pageSize = 50}) async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
      filterOption: FilterOptionGroup(
        orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
      ),
    );
    if (albums.isEmpty) return [];

    final allAlbum = albums.first;
    final assets = await allAlbum.getAssetListPaged(page: page, size: pageSize);
    return assets.map((asset) => PhotoItem(asset: asset)).toList();
  }

  /// Get all photos for a specific month.
  Future<List<PhotoItem>> getPhotosByMonth(int year, int month) async {
    final start = DateTime(year, month);
    final end = (month == 12) ? DateTime(year + 1, 1) : DateTime(year, month + 1);

    final filterOption = FilterOptionGroup(
      createTimeCond: DateTimeCond(min: start, max: end),
      orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
    );

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
      filterOption: filterOption,
    );
    if (albums.isEmpty) return [];

    final allAlbum = albums.first;
    final count = await allAlbum.assetCountAsync;
    if (count == 0) return [];

    final assets = await allAlbum.getAssetListRange(start: 0, end: count);
    return assets.map((asset) => PhotoItem(asset: asset)).toList();
  }

  /// Delete photos by their IDs.
  Future<List<String>> deletePhotos(List<String> ids) async {
    return await PhotoManager.editor.deleteWithIds(ids);
  }

  /// Toggle favorite status for a photo (iOS only).
  Future<bool> toggleFavorite(String id) async {
    try {
      final asset = await AssetEntity.fromId(id);
      if (asset == null) return false;
      await PhotoManager.editor.darwin.favoriteAsset(
        entity: asset,
        favorite: !asset.isFavorite,
      );
      return true;
    } catch (e) {
      // favoriteAsset may not be supported on all devices
      return false;
    }
  }

  /// Get monthly photo counts. Returns Map of "YYYY-MM" -> count.
  Future<Map<String, int>> getMonthlyStats() async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
      filterOption: FilterOptionGroup(
        orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
      ),
    );
    if (albums.isEmpty) return {};

    final allAlbum = albums.first;
    final totalCount = await allAlbum.assetCountAsync;
    if (totalCount == 0) return {};

    final Map<String, int> stats = {};

    // Load all assets in batches to count by month
    const batchSize = 500;
    for (int offset = 0; offset < totalCount; offset += batchSize) {
      final end = (offset + batchSize > totalCount) ? totalCount : offset + batchSize;
      final assets = await allAlbum.getAssetListRange(start: offset, end: end);
      for (final asset in assets) {
        final date = asset.createDateTime;
        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        stats[key] = (stats[key] ?? 0) + 1;
      }
    }

    return stats;
  }

  /// Find groups of visually similar photos using perceptual hashing.
  /// Returns lists where each inner list has 2+ similar photos.
  Future<List<List<PhotoItem>>> findSimilarGroups(List<PhotoItem> photos) async {
    if (photos.length < 2) return [];

    // Step 1: Compute perceptual hash for each photo
    final Map<String, int> hashes = {};

    for (final photo in photos) {
      try {
        final hash = await _computePerceptualHash(photo);
        if (hash != 0) {
          hashes[photo.id] = hash;
        }
      } catch (_) {
        // Skip photos that can't be hashed
      }
    }

    // Step 2: Group photos with similar hashes (hamming distance <= 10)
    final List<List<PhotoItem>> groups = [];
    final Set<String> grouped = {};

    final photoList = photos.where((p) => hashes.containsKey(p.id)).toList();

    for (int i = 0; i < photoList.length; i++) {
      if (grouped.contains(photoList[i].id)) continue;

      final List<PhotoItem> group = [photoList[i]];
      final hash1 = hashes[photoList[i].id]!;

      for (int j = i + 1; j < photoList.length; j++) {
        if (grouped.contains(photoList[j].id)) continue;

        final hash2 = hashes[photoList[j].id]!;
        final distance = _hammingDistance(hash1, hash2);

        if (distance <= 10) {
          group.add(photoList[j]);
          grouped.add(photoList[j].id);
        }
      }

      if (group.length >= 2) {
        groups.add(group);
        grouped.add(photoList[i].id);
      }
    }

    return groups;
  }

  /// Compute a 64-bit perceptual hash (average hash) for a photo.
  /// Resizes to 8x8 grayscale and compares each pixel to the mean.
  Future<int> _computePerceptualHash(PhotoItem photo) async {
    // Get a small thumbnail
    final bytes = await photo.asset.thumbnailDataWithSize(
      const ThumbnailSize(32, 32),
      quality: 50,
    );
    if (bytes == null) return 0;

    // Decode to raw pixels using dart:ui
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 8,
      targetHeight: 8,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return 0;

    final pixels = byteData.buffer.asUint8List();

    // Convert to grayscale values
    final List<int> gray = [];
    for (int i = 0; i < pixels.length; i += 4) {
      final r = pixels[i];
      final g = pixels[i + 1];
      final b = pixels[i + 2];
      gray.add((r * 299 + g * 587 + b * 114) ~/ 1000);
    }

    // Compute average
    final avg = gray.reduce((a, b) => a + b) / gray.length;

    // Build hash: each bit = 1 if pixel > average
    int hash = 0;
    for (int i = 0; i < gray.length && i < 64; i++) {
      if (gray[i] > avg) {
        hash |= (1 << i);
      }
    }

    return hash;
  }

  /// Count differing bits between two hashes.
  int _hammingDistance(int hash1, int hash2) {
    int xor = hash1 ^ hash2;
    int count = 0;
    while (xor != 0) {
      count += xor & 1;
      xor >>= 1;
    }
    return count;
  }
}
