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

  /// Find groups of similar photos (taken within 3 seconds of each other).
  /// Returns lists where each inner list has 2+ similar photos.
  List<List<PhotoItem>> findSimilarGroups(List<PhotoItem> photos) {
    if (photos.length < 2) return [];

    // Sort by creation date
    final sorted = List<PhotoItem>.from(photos)
      ..sort((a, b) => a.createDate.compareTo(b.createDate));

    final List<List<PhotoItem>> groups = [];
    List<PhotoItem> currentGroup = [sorted.first];

    for (int i = 1; i < sorted.length; i++) {
      final diff = sorted[i].createDate.difference(sorted[i - 1].createDate).inSeconds.abs();
      if (diff <= 3) {
        currentGroup.add(sorted[i]);
      } else {
        if (currentGroup.length >= 2) {
          groups.add(List.from(currentGroup));
        }
        currentGroup = [sorted[i]];
      }
    }

    // Don't forget the last group
    if (currentGroup.length >= 2) {
      groups.add(List.from(currentGroup));
    }

    return groups;
  }
}
