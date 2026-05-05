import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/photo_provider.dart';
import '../theme/app_theme.dart';
import 'swipe_screen.dart';
import 'similar_photos_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    SwipeScreen(),
    SimilarPhotosScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final pendingCount = context.watch<PhotoProvider>().pendingDeleteCount;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textSecondary.withValues(alpha: 0.5),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          backgroundColor: Colors.white,
          items: [
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.cleaning_services_rounded),
                  if (pendingCount > 0)
                    Positioned(
                      top: -6,
                      right: -10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.danger,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$pendingCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              label: '清理',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.copy_rounded),
              label: '相似',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              label: '统计',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: '设置',
            ),
          ],
        ),
      ),
    );
  }
}
