import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'utils/theme.dart';
import 'providers/recipe_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    await FirebaseService().initialize();
  } catch (_) {}
  try {
    await NotificationService().initialize();
  } catch (_) {}
  runApp(const ChefAIApp());
}

class ChefAIApp extends StatelessWidget {
  const ChefAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, langProvider, child) {
          return MaterialApp(
            title: 'ChefAI',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: Locale(langProvider.currentLanguage),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}