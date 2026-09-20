import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/anime_service.dart';
import 'services/favorites_service.dart';
import 'theme/app_theme.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Configure system UI overlay for a more immersive feel
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AnimeService()),
        ChangeNotifierProvider(create: (_) => FavoritesService()),
      ],
      child: const AnimeGrabApp(),
    ),
  );
}

class AnimeGrabApp extends StatelessWidget {
  const AnimeGrabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AnimeGrab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // Force RTL for Arabic
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const MainShell(),
    );
  }
}
