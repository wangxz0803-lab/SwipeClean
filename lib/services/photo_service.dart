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

  static const int _maxPhotosForSimilarity = 200;

  Future<List<List<PhotoItem>>> findSimilarGroups(
    List<PhotoItem> photos, {
    void Function(int processed, int total, String phase)? onProgress,
    bool Function()? shouldCancel,
  }) async {
    final limited = photos.length > _maxPhotosForSimilarity
        ? photos.sublist(0, _maxPhotosForSimilarity)
        : photos;
    if (limited.length < 2) return [];

    final total = limited.length;
    final Map<String, int> hashes = {};

    for (int i = 0; i < total; i++) {
      if (shouldCancel?.call() == true) return [];
      try {
        final hash = await _computePerceptualHash(limited[i]);
        if (hash != 0) {
          hashes[limited[i].id] = hash;
        }
      } catch (_) {}
      onProgress?.call(i + 1, total, '正在分析照片');
      await Future.delayed(const Duration(milliseconds: 50));
    }

    final List<List<PhotoItem>> groups = [];
    final Set<String> grouped = {};
    final photoList = limited.where((p) => hashes.containsKey(p.id)).toList();

    for (int i = 0; i < photoList.length; i++) {
      if (grouped.contains(photoList[i].id)) continue;

      final List<PhotoItem> group = [photoList[i]];
      final hash1 = hashes[photoList[i].id]!;

      for (int j = i + 1; j < photoList.length; j++) {
        if (grouped.contains(photoList[j].id)) continue;

        final hash2 = hashes[photoList[j].id]!;
        if (_hammingDistance(hash1, hash2) <= 10) {
          group.add(photoList[j]);
          grouped.add(photoList[j].id);
        }
      }

      if (group.length >= 2) {
        groups.add(group);
        grouped.add(photoList[i].id);
      }
    }

    // 预加载分组照片缩略图，逐张加载避免并发堵死平台线程
    final allGroupPhotos = groups.expand((g) => g).toList();
    for (int i = 0; i < allGroupPhotos.length; i++) {
      if (shouldCancel?.call() == true) return groups;
      await allGroupPhotos[i].loadThumbnail();
      onProgress?.call(i + 1, allGroupPhotos.length, '正在加载预览');
      await Future.delayed(const Duration(milliseconds: 30));
    }

    return groups;
  }

  /// Compute a 64-bit perceptual hash (average hash) for a photo.
  /// Resizes to 8x8 grayscale and compares each pixel to the mean.
  Future<int> _computePerceptualHash(PhotoItem photo) async {
    final bytes = await photo.asset.thumbnailDataWithSize(
      const ThumbnailSize(32, 32),
      quality: 50,
    );
    if (bytes == null) return 0;

    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 8,
      targetHeight: 8,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (byteData == null) return 0;

    final pixels = byteData.buffer.asUint8List();
    final int pixelCount = pixels.length ~/ 4;
    int sum = 0;
    final gray = List<int>.filled(pixelCount, 0);
    for (int i = 0; i < pixelCount; i++) {
      final off = i * 4;
      final v = (pixels[off] * 299 + pixels[off + 1] * 587 + pixels[off + 2] * 114) ~/ 1000;
      gray[i] = v;
      sum += v;
    }

    final avg = sum / pixelCount;
    int hash = 0;
    for (int i = 0; i < pixelCount && i < 64; i++) {
      if (gray[i] > avg) hash |= (1 << i);
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
