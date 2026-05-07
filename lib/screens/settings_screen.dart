import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _swipeSensitivity = 0.5;
  bool _showPhotoInfo = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _swipeSensitivity = prefs.getDouble('swipe_sensitivity') ?? 0.5;
      _showPhotoInfo = prefs.getBool('show_photo_info') ?? true;
      _loaded = true;
    });
  }

  Future<void> _saveSensitivity(double value) async {
    setState(() => _swipeSensitivity = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('swipe_sensitivity', value);
  }

  Future<void> _saveShowPhotoInfo(bool value) async {
    setState(() => _showPhotoInfo = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_photo_info', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          '设置',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _loaded
          ? ListView(
              children: [
                const SizedBox(height: 12),
                // App branding
                _buildAppHeader(),
                const SizedBox(height: 24),
                // Clean settings
                _buildSectionHeader('清理设置'),
                _buildSettingsCard([
                  _buildSensitivityTile(),
                  const Divider(height: 1),
                  _buildShowInfoToggle(),
                ]),
                const SizedBox(height: 24),
                // Data section
                _buildSectionHeader('数据'),
                _buildSettingsCard([
                  _buildResetStatsTile(),
                  const Divider(height: 1),
                  _buildClearTrashTile(),
                ]),
                const SizedBox(height: 24),
                // About section
                _buildSectionHeader('关于'),
                _buildSettingsCard([
                  _buildVersionTile(),
                  const Divider(height: 1),
                  _buildTaglineTile(),
                ]),
                const SizedBox(height: 40),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
    );
  }

  Widget _buildAppHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary,
                  AppTheme.primary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.cleaning_services_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'SwipeClean',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '滑动清理，轻松管理照片',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.primary.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSensitivityTile() {
    String sensitivityLabel;
    if (_swipeSensitivity < 0.33) {
      sensitivityLabel = '低';
    } else if (_swipeSensitivity < 0.66) {
      sensitivityLabel = '中';
    } else {
      sensitivityLabel = '高';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swipe_rounded,
                  color: AppTheme.primary, size: 22),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '滑动灵敏度',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                sensitivityLabel,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.primary,
              inactiveTrackColor: AppTheme.primary.withValues(alpha: 0.15),
              thumbColor: AppTheme.primary,
              overlayColor: AppTheme.primary.withValues(alpha: 0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: _swipeSensitivity,
              onChanged: _saveSensitivity,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowInfoToggle() {
    return ListTile(
      leading: const Icon(Icons.info_outline_rounded,
          color: AppTheme.primary, size: 22),
      title: const Text(
        '显示照片信息',
        style: TextStyle(fontSize: 16, color: AppTheme.textPrimary),
      ),
      subtitle: const Text(
        '在卡片上显示日期和尺寸',
        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
      ),
      trailing: Switch.adaptive(
        value: _showPhotoInfo,
        onChanged: _saveShowPhotoInfo,
        activeTrackColor: AppTheme.primary,
      ),
    );
  }

  Widget _buildResetStatsTile() {
    return ListTile(
      leading: const Icon(Icons.restart_alt_rounded,
          color: Colors.orange, size: 22),
      title: const Text(
        '重置统计数据',
        style: TextStyle(fontSize: 16, color: AppTheme.textPrimary),
      ),
      subtitle: const Text(
        '清除所有清理记录和统计',
        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
      ),
      trailing:
          const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: () => _showConfirmAction(
        title: '重置统计数据',
        message: '确定要重置所有统计数据吗？此操作不可撤销。',
        onConfirm: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          await _loadSettings();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('统计数据已重置'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildClearTrashTile() {
    return ListTile(
      leading: const Icon(Icons.delete_sweep_rounded,
          color: AppTheme.danger, size: 22),
      title: const Text(
        '清空回收站',
        style: TextStyle(fontSize: 16, color: AppTheme.textPrimary),
      ),
      subtitle: const Text(
        '永久删除回收站中的所有照片',
        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
      ),
      trailing:
          const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: () => _showConfirmAction(
        title: '清空回收站',
        message: '确定要永久删除回收站中的所有照片吗？此操作不可撤销。',
        onConfirm: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('回收站已清空'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildVersionTile() {
    return const ListTile(
      leading:
          Icon(Icons.info_rounded, color: AppTheme.primary, size: 22),
      title: Text(
        '版本',
        style: TextStyle(fontSize: 16, color: AppTheme.textPrimary),
      ),
      trailing: Text(
        'v1.2.0',
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTaglineTile() {
    return const ListTile(
      leading: Icon(Icons.favorite_rounded, color: AppTheme.danger, size: 22),
      title: Text(
        '无广告，永远免费 :)',
        style: TextStyle(
          fontSize: 16,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  void _showConfirmAction({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
}
