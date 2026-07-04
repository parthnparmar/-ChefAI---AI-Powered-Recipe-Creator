import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_constants.dart';
import '../providers/recipe_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      await StorageService().initialize();
      if (mounted) {
        context.read<ThemeProvider>().loadTheme();
        context.read<LanguageProvider>().loadLanguage();
        context.read<RecipeProvider>().loadRecipes();
      }
      await Future.delayed(const Duration(seconds: 3));
      final onboardingCompleted =
          StorageService().getSetting('onboarding_completed', defaultValue: false) ?? false;
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => onboardingCompleted ? const HomeScreen() : const OnboardingScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) _showErrorDialog(e.toString());
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Initialization Error'),
        content: Text('Failed to initialize app: $error'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeApp(); // Retry
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppConstants.extraLargeRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Image.asset('assets/images/logo.png', width: 80, height: 80, fit: BoxFit.contain),
                    ),
                    const SizedBox(height: AppConstants.extraLargePadding),
                    const Text('ChefAI',
                        style: TextStyle(
                            fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 3))
                        .animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
                    const SizedBox(height: AppConstants.mediumPadding),
                    const Text('AI-Powered Recipe Creator',
                        style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w300))
                        .animate().fadeIn(delay: 600.ms),
                    const SizedBox(height: AppConstants.extraLargePadding * 2),
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ).animate().fadeIn(delay: 800.ms),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}