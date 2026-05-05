import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';

class PhotoItem {
  final AssetEntity asset;
  int fileSize;
  Uint8List? thumbnailData;

  PhotoItem({required this.asset, this.fileSize = 0, this.thumbnailData});

  String get id => asset.id;
  DateTime get createDate => asset.createDateTime;
  int get width => asset.width;
  int get height => asset.height;
  AssetType get type => asset.type;

  String get monthKey {
    return '${createDate.year}-${createDate.month.toString().padLeft(2, '0')}';
  }

  Future<Uint8List?> loadThumbnail({int size = 300}) async {
    thumbnailData ??=
        await asset.thumbnailDataWithSize(ThumbnailSize(size, size));
    return thumbnailData;
  }

  Future<Uint8List?> loadFullImage() async {
    return await asset.originBytes;
  }

  Future<int> loadFileSize() async {
    if (fileSize > 0) return fileSize;
    final file = await asset.file;
    fileSize = file?.lengthSync() ?? 0;
    return fileSize;
  }
}
