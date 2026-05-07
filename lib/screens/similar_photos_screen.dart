import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/photo_item.dart';
import '../models/swipe_action.dart';
import '../providers/photo_provider.dart';
import '../services/photo_service.dart';
import '../theme/app_theme.dart';

class SimilarPhotosScreen extends StatefulWidget {
  const SimilarPhotosScreen({super.key});

  @override
  State<SimilarPhotosScreen> createState() => _SimilarPhotosScreenState();
}

class _SimilarPhotosScreenState extends State<SimilarPhotosScreen> {
  List<List<PhotoItem>>? _groups;
  bool _isLoading = true;
  bool _cancelled = false;
  int _processed = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _findSimilarGroups();
    });
  }

  @override
  void dispose() {
    _cancelled = true;
    super.dispose();
  }

  Future<void> _findSimilarGroups() async {
    setState(() {
      _isLoading = true;
      _cancelled = false;
      _processed = 0;
      _total = 0;
    });
    try {
      final photos = context.read<PhotoProvider>().photos;
      final photoService = PhotoService();
      final groups = await photoService.findSimilarGroups(
        photos,
        onProgress: (processed, total) {
          if (mounted && !_cancelled) {
            setState(() {
              _processed = processed;
              _total = total;
            });
          }
        },
        shouldCancel: () => _cancelled,
      );
      if (mounted && !_cancelled) {
        setState(() {
          _groups = groups;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !_cancelled) {
        setState(() {
          _groups = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          '相似照片',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
            onPressed: _findSimilarGroups,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      final progress = _total > 0 ? _processed / _total : 0.0;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.primary),
              const SizedBox(height: 20),
              if (_total > 0) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                    color: AppTheme.primary,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '正在分析 $_processed / $_total 张照片...',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ] else
                const Text(
                  '正在准备分析...',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                ),
            ],
          ),
        ),
      );
    }

    if (_groups == null || _groups!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              '没有发现相似照片',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '您的照片库很整洁',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _groups!.length,
      itemBuilder: (context, index) {
        return _SimilarGroup(
          group: _groups![index],
          onKeepBest: () => _keepBest(index),
          onKeepAll: () => _keepAll(index),
        );
      },
    );
  }

  void _keepBest(int groupIndex) {
    if (_groups == null || groupIndex >= _groups!.length) return;
    final group = _groups![groupIndex];
    if (group.length <= 1) return;

    final provider = context.read<PhotoProvider>();
    // Keep the first photo (assumed best), mark rest for delete
    for (int i = 1; i < group.length; i++) {
      provider.handleSwipe(SwipeDirection.left);
    }

    setState(() {
      _groups!.removeAt(groupIndex);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已保留最佳照片，${group.length - 1}张标记为删除'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _keepAll(int groupIndex) {
    if (_groups == null || groupIndex >= _groups!.length) return;

    setState(() {
      _groups!.removeAt(groupIndex);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已全部保留'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SimilarGroup extends StatelessWidget {
  final List<PhotoItem> group;
  final VoidCallback onKeepBest;
  final VoidCallback onKeepAll;

  const _SimilarGroup({
    required this.group,
    required this.onKeepBest,
    required this.onKeepAll,
  });

  @override
  Widget build(BuildContext context) {
    final firstDate = group.first.createDate;
    final dateStr = '${firstDate.month}月${firstDate.day}日';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(
                  Icons.photo_library_rounded,
                  color: AppTheme.primary.withValues(alpha: 0.7),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${group.length}张相似照片 · $dateStr',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Photo row
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: group.length,
              itemBuilder: (context, index) {
                final photo = group[index];
                return _buildPhotoTile(context, photo, index == 0);
              },
            ),
          ),
          const SizedBox(height: 12),
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onKeepBest,
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: const Text('保留最佳'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: BorderSide(
                          color: AppTheme.primary.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onKeepAll,
                    icon: const Icon(Icons.select_all_rounded, size: 18),
                    label: const Text('全部保留'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.success,
                      side: BorderSide(
                          color: AppTheme.success.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoTile(
      BuildContext context, PhotoItem photo, bool isBest) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _showFullImage(context, photo),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 120,
                height: 140,
                child: FutureBuilder<Uint8List?>(
                  future: photo.loadThumbnail(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        color: AppTheme.background,
                        child: const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      );
                    }
                    if (snapshot.data == null) {
                      return Container(
                        color: AppTheme.background,
                        child: const Icon(Icons.broken_image_outlined,
                            color: AppTheme.textSecondary),
                      );
                    }
                    return Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    );
                  },
                ),
              ),
            ),
            if (isBest)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '最佳',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, PhotoItem photo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullImageView(photo: photo),
      ),
    );
  }
}

class _FullImageView extends StatelessWidget {
  final PhotoItem photo;

  const _FullImageView({required this.photo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: FutureBuilder<Uint8List?>(
          future: photo.loadFullImage(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(color: Colors.white);
            }
            if (snapshot.data == null) {
              return const Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: 64,
              );
            }
            return InteractiveViewer(
              child: Image.memory(
                snapshot.data!,
                fit: BoxFit.contain,
              ),
            );
          },
        ),
      ),
    );
  }
}
