import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/recipe_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/recipe_card.dart';
import '../utils/theme.dart';
import 'recipe_generator_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';
import 'recipe_history_screen.dart';
import 'image_recipe_screen.dart';
import 'explore_recipes_screen.dart';
import 'recipe_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _HomeTab(),
    RecipeGeneratorScreen(),
    ExploreRecipesScreen(),
    FavoritesScreen(),
    RecipeHistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            backgroundColor: Colors.transparent,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_rounded), label: 'Generate'),
              BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: 'Explore'),
              BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded), label: 'Favorites'),
              BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
              BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<RecipeProvider>(
      builder: (context, provider, _) {
        final recent = provider.getRecentRecipes(limit: 6);
        final favorites = provider.favoriteRecipes.take(4).toList();
        return SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context, provider)),
              SliverToBoxAdapter(child: _buildQuickActions(context)),
              if (recent.isNotEmpty) ...[
                SliverToBoxAdapter(child: _sectionHeader(context, '🔥 Recent Recipes', () {})),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 340,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: recent.length,
                      itemBuilder: (ctx, i) => SizedBox(
                        width: MediaQuery.of(ctx).size.width * 0.68,
                        child: RecipeCard(recipe: recent[i]),
                      ).animate(delay: Duration(milliseconds: i * 60)).fadeIn().slideX(begin: 0.1),
                    ),
                  ),
                ),
              ],
              if (favorites.isNotEmpty) ...[
                SliverToBoxAdapter(child: _sectionHeader(context, '❤️ Your Favorites', () {})),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => RecipeCard(recipe: favorites[i])
                        .animate(delay: Duration(milliseconds: i * 60))
                        .fadeIn()
                        .slideY(begin: 0.05),
                    childCount: favorites.length,
                  ),
                ),
              ],
              if (recent.isEmpty && favorites.isEmpty)
                SliverFillRemaining(child: _buildEmpty(context)),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, RecipeProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hello, Chef! 👨‍🍳',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text('What are we\ncooking today?',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.2)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Image.asset('assets/images/logo.png', width: 16, height: 16, fit: BoxFit.contain),
                    const SizedBox(width: 6),
                    Text('${provider.recipes.length} recipes',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeGeneratorScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Text('Generate a new recipe...',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.05);
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      (Icons.camera_alt_rounded, 'Scan Food', AppTheme.primary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImageRecipeScreen()))),
      (Icons.explore_rounded, 'Explore', const Color(0xFF4CAF50), () {}),
      (Icons.favorite_rounded, 'Favorites', const Color(0xFFE91E63), () {}),
      (Icons.history_rounded, 'History', const Color(0xFF2196F3), () {}),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: actions.map((a) {
          return Expanded(
            child: GestureDetector(
              onTap: a.$4,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: a.$3.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: a.$3.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Icon(a.$1, color: a.$3, size: 24),
                    const SizedBox(height: 6),
                    Text(a.$2,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: a.$3)),
                  ],
                ),
              ),
            ).animate(delay: Duration(milliseconds: actions.indexOf(a) * 60)).fadeIn().scale(begin: const Offset(0.9, 0.9)),
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          TextButton(
            onPressed: onSeeAll,
            child: Text('See All',
                style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Image.asset('assets/images/logo.png', width: 60, height: 60, fit: BoxFit.contain),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 1500.ms),
            const SizedBox(height: 24),
            Text('No Recipes Yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text('Start by generating your first AI-powered recipe!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeGeneratorScreen())),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Generate Recipe'),
            ),
          ],
        ),
      ),
    );
  }
}
