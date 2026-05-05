import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MonthPicker extends StatelessWidget {
  final Map<String, int> monthlyStats;
  final String? selected;
  final void Function(String? monthKey) onSelect;

  const MonthPicker({
    super.key,
    required this.monthlyStats,
    this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    // Sort keys descending (most recent first)
    final sortedKeys = monthlyStats.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: sortedKeys.length + 1, // +1 for "全部"
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildChip(
              label: '全部',
              count: null,
              isSelected: selected == null,
              onTap: () => onSelect(null),
            );
          }

          final key = sortedKeys[index - 1];
          final count = monthlyStats[key] ?? 0;
          final label = _formatMonthKey(key);

          return _buildChip(
            label: label,
            count: count,
            isSelected: selected == key,
            onTap: () => onSelect(key),
          );
        },
      ),
    );
  }

  Widget _buildChip({
    required String label,
    int? count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final displayText =
        count != null ? '$label ($count)' : label;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primary
                : AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primary
                  : AppTheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Text(
            displayText,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  String _formatMonthKey(String key) {
    // key is "YYYY-MM"
    final parts = key.split('-');
    if (parts.length != 2) return key;
    final year = parts[0];
    final month = int.tryParse(parts[1]) ?? 0;
    return '$year年${month}月';
  }
}
