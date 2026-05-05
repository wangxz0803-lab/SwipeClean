import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

class SwipeCleanApp extends StatelessWidget {
  const SwipeCleanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SwipeClean',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
