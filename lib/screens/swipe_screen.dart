import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/swipe_action.dart';
import '../providers/photo_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/card_stack.dart';
import '../widgets/action_buttons.dart';
import '../widgets/month_picker.dart';
import '../widgets/progress_ring.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotoProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(PhotoProvider provider) {
    // Permission not granted
    if (!provider.permissionGranted && !provider.isLoading) {
      return _buildPermissionRequest();
    }

    // Loading
    if (provider.isLoading && provider.photos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 16),
            Text(
              '正在加载照片...',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    // All photos reviewed
    if (provider.currentPhoto == null && provider.photos.isNotEmpty) {
      return _buildCompletionView(provider);
    }

    // Main swipe interface
    return Column(
      children: [
        // Top bar: month picker + progress ring
        _buildTopBar(provider),
        // Card stack (takes remaining space)
        Expanded(
          child: CardStack(
            photos: provider.photos,
            currentIndex: provider.reviewed,
            onSwipe: (direction) {
              provider.handleSwipe(direction);
            },
          ),
        ),
        // Action buttons
        ActionButtons(
          canUndo: provider.canUndo,
          undoCount: provider.history.length,
          onUndo: provider.canUndo ? () => provider.undo() : null,
          onDelete: () => provider.handleSwipe(SwipeDirection.left),
          onKeep: () => provider.handleSwipe(SwipeDirection.right),
          onFavorite: () => provider.handleSwipe(SwipeDirection.up),
        ),
        // Status bar with delete action
        _buildStatusBar(provider),
      ],
    );
  }

  Widget _buildTopBar(PhotoProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 12, 4),
      child: Row(
        children: [
          // Month picker
          Expanded(
            child: MonthPicker(
              monthlyStats: provider.monthlyStats,
              selected: null, // TODO: track selected month in state
              onSelect: (monthKey) {
                provider.selectMonth(monthKey);
              },
            ),
          ),
          // Progress ring (small)
          ProgressRing(
            progress: provider.progress,
            reviewed: provider.reviewed,
            total: provider.photos.length,
            size: 56,
            strokeWidth: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 80,
              color: AppTheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              '需要访问您的照片',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '请授予照片库访问权限，以便我们帮您清理照片',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.read<PhotoProvider>().init();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '授予权限',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionView(PhotoProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Animated checkmark
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.success.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.success,
                size: 64,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '本月清理完毕！',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 32),
          // Stats summary
          _buildStatsSummary(provider),
          const SizedBox(height: 40),
          // Confirm delete button
          if (provider.pendingDeleteCount > 0) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final confirmed = await _showDeleteConfirmation(
                    context,
                    provider.pendingDeleteCount,
                  );
                  if (confirmed == true && mounted) {
                    await context.read<PhotoProvider>().confirmDeletes();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '确认删除 (${provider.pendingDeleteCount}张)',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Undo all button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  while (provider.canUndo) {
                    provider.undo();
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                      color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '全部撤销',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsSummary(PhotoProvider provider) {
    final reviewed = provider.reviewed;
    final deleted = provider.pendingDeleteCount;
    final kept = reviewed - deleted; // approximate

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatTile('已审阅', '$reviewed', Icons.visibility_rounded,
            AppTheme.primary),
        _buildStatTile(
            '保留', '$kept', Icons.check_circle_rounded, AppTheme.success),
        _buildStatTile(
            '删除', '$deleted', Icons.delete_rounded, AppTheme.danger),
      ],
    );
  }

  Widget _buildStatTile(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBar(PhotoProvider provider) {
    final hasPending = provider.pendingDeleteCount > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4, left: 20, right: 20),
      child: Row(
        children: [
          // Stats text
          Expanded(
            child: Text(
              '已审阅 ${provider.reviewed} · 剩余 ${provider.remaining}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          // Delete confirm button (always visible when there are pending deletes)
          if (hasPending)
            GestureDetector(
              onTap: () => _showDeleteBottomSheet(context, provider),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.danger,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.delete_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '待删除 ${provider.pendingDeleteCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteBottomSheet(BuildContext context, PhotoProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final count = provider.pendingDeleteCount;
        final pendingPhotos = provider.history
            .where((r) => r.action == ActionType.delete)
            .map((r) => r.photo)
            .toList();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                // Icon + count
                Icon(
                  Icons.delete_sweep_rounded,
                  size: 48,
                  color: AppTheme.danger.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 12),
                Text(
                  '$count 张照片待删除',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '确认后将从相册中永久移除',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                // Thumbnail preview grid
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: GridView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemCount: pendingPhotos.length,
                    itemBuilder: (context, index) {
                      final photo = pendingPhotos[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FutureBuilder<Uint8List?>(
                          future: photo.loadThumbnail(size: 150),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.done &&
                                snapshot.data != null) {
                              return Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                              );
                            }
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // Confirm delete button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await context.read<PhotoProvider>().confirmDeletes();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('已删除 $count 张照片'),
                            backgroundColor: AppTheme.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.delete_forever_rounded),
                    label: Text('确认删除 $count 张'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Cancel button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      '继续审阅',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _showDeleteConfirmation(
      BuildContext context, int count) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要永久删除这 $count 张照片吗？此操作不可撤销。'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
