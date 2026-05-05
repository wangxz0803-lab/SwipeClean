import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/photo_item.dart';
import '../models/swipe_action.dart';
import '../providers/photo_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/photo_grid.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final Set<String> _selectedIds = {};

  List<PhotoItem> _getPendingDeletes(PhotoProvider provider) {
    // Try to access pendingDeletes directly, or derive from history
    try {
      return provider.history
          .where((r) => r.action == ActionType.delete)
          .map((r) => r.photo)
          .toList();
    } catch (_) {
      return [];
    }
  }

  void _toggleSelectAll(List<PhotoItem> photos) {
    setState(() {
      if (_selectedIds.length == photos.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.clear();
        _selectedIds.addAll(photos.map((p) => p.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotoProvider>();
    final pendingDeletes = _getPendingDeletes(provider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          '回收站',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (pendingDeletes.isNotEmpty)
            TextButton(
              onPressed: () => _toggleSelectAll(pendingDeletes),
              child: Text(
                _selectedIds.length == pendingDeletes.length ? '取消全选' : '全选',
                style: const TextStyle(color: AppTheme.primary),
              ),
            ),
        ],
      ),
      body: pendingDeletes.isEmpty
          ? _buildEmptyState()
          : _buildContent(provider, pendingDeletes),
      bottomNavigationBar: _selectedIds.isNotEmpty
          ? _buildBottomBar(provider, pendingDeletes)
          : null,
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.delete_outline_rounded,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            '回收站为空',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '左滑删除的照片会出现在这里',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      PhotoProvider provider, List<PhotoItem> pendingDeletes) {
    // Estimate space: rough average of 3MB per photo
    final estimatedMB =
        (pendingDeletes.length * 3.0).toStringAsFixed(1);

    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: AppTheme.danger.withValues(alpha: 0.05),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppTheme.danger.withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${pendingDeletes.length}张照片待删除 · 约释放 $estimatedMB MB',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.danger.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Photo grid
        Expanded(
          child: PhotoGrid(
            photos: pendingDeletes,
            selectionMode: true,
            selectedIds: _selectedIds,
            onSelectionChanged: (id, selected) {
              setState(() {
                if (selected) {
                  _selectedIds.add(id);
                } else {
                  _selectedIds.remove(id);
                }

              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(
      PhotoProvider provider, List<PhotoItem> pendingDeletes) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirmed = await _showConfirmDialog(
                  context,
                  '确认删除',
                  '确定要永久删除选中的 ${_selectedIds.length} 张照片吗？',
                );
                if (confirmed == true && mounted) {
                  await provider.confirmDeletes();
                  setState(() => _selectedIds.clear());
                }
              },
              icon: const Icon(Icons.delete_forever_rounded, size: 20),
              label: Text('确认删除 (${_selectedIds.length})'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // Undo selected items
                for (var i = 0; i < _selectedIds.length; i++) {
                  if (provider.canUndo) {
                    provider.undo();
                  }
                }
                setState(() => _selectedIds.clear());
              },
              icon: const Icon(Icons.restore_rounded, size: 20),
              label: Text('恢复选中 (${_selectedIds.length})'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.success,
                side: const BorderSide(color: AppTheme.success),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog(
      BuildContext context, String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
}
