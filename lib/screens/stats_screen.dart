import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stats_provider.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatsProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          '统计',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<StatsProvider>(
        builder: (context, stats, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Big number: total reviewed
                _buildHeroStat(stats),
                const SizedBox(height: 20),
                // Space saved & keep rate row
                Row(
                  children: [
                    Expanded(child: _buildSpaceSaved(stats)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildKeepRate(stats)),
                  ],
                ),
                const SizedBox(height: 12),
                // Streak card
                _buildStreakCard(stats),
                const SizedBox(height: 24),
                // Grid of 4 stat tiles
                const Text(
                  '详细统计',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStatsGrid(stats),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroStat(StatsProvider stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary,
            AppTheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '已审阅照片',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: stats.totalReviewed),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Text(
                '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpaceSaved(StatsProvider stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.storage_rounded,
            color: AppTheme.success.withValues(alpha: 0.8),
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            stats.spaceSavedFormatted,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '已节省空间',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeepRate(StatsProvider stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 4),
          Text(
            '${stats.keepRate}%',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          // Mini progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: stats.keepRate / 100,
              backgroundColor: AppTheme.background,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.success),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '保留率',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(StatsProvider stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.orange,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '连续 ${stats.currentStreak} 天',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                '保持每天清理的习惯',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(StatsProvider stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatTile(
          icon: Icons.visibility_rounded,
          color: AppTheme.primary,
          value: stats.totalReviewed,
          label: '已审阅',
        ),
        _buildStatTile(
          icon: Icons.delete_rounded,
          color: AppTheme.danger,
          value: stats.totalDeleted,
          label: '已删除',
        ),
        _buildStatTile(
          icon: Icons.check_circle_rounded,
          color: AppTheme.success,
          value: stats.totalKept,
          label: '已保留',
        ),
        _buildStatTile(
          icon: Icons.star_rounded,
          color: AppTheme.favorite,
          value: stats.totalFavorited,
          label: '已收藏',
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required Color color,
    required int value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, val, _) {
              return Text(
                '$val',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              );
            },
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
      ),
    );
  }
}
