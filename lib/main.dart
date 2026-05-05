import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/photo_service.dart';
import 'services/storage_service.dart';
import 'providers/photo_provider.dart';
import 'providers/stats_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final storageService = StorageService();
  await storageService.init();
  final photoService = PhotoService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PhotoProvider(photoService, storageService)..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => StatsProvider(storageService),
        ),
      ],
      child: const SwipeCleanApp(),
    ),
  );
}
