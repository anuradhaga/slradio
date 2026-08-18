import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_service/audio_service.dart';
import 'services/audio_handler.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized prior to loading storage
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background audio handler
  audioHandler = await AudioService.init(
    builder: () => RadioAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.slradio.app.channel.audio',
      androidNotificationChannelName: 'SL Radio Playback',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
    ),
  );

  // Constrain system overlays to dark theme and fix orientation
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SL Radio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
