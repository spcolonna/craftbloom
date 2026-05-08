import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:craftbloom/core/config/app_config.dart';
import 'package:craftbloom/core/router/app_router.dart';
import 'package:craftbloom/core/theme/app_theme.dart';
import 'package:craftbloom/core/theme/seasonal_theme.dart';
import 'package:craftbloom/core/utils/firebase_logger.dart';
import 'package:craftbloom/features/settings/data/settings_repository.dart';
import 'package:craftbloom/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const ProviderScope(
    observers: [FirebaseErrorObserver()],
    child: CraftBloomApp(),
  ));
}

class CraftBloomApp extends ConsumerWidget {
  const CraftBloomApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final season = ref.watch(seasonalThemeProvider).value ?? SeasonalTheme.normal;
    return MaterialApp.router(
      title: AppConfig.businessName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.forSeason(season),
      routerConfig: router,
    );
  }
}
