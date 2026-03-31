import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  await Hive.openBox('cache_box');
  await NotificationService.instance.initialize();

  runApp(
    const ProviderScope(
      child: TradeHubApp(),
    ),
  );
}

class TradeHubApp extends StatelessWidget {
  const TradeHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TradeHub',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
