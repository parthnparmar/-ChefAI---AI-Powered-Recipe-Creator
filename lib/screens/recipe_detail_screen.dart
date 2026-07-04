import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_constants.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../services/tts_service.dart';
import '../services/firebase_service.dart';
import '../widgets/cooking_timer_widget.dart';
import '../widgets/nutrition_card.dart';
import '../widgets/rating_widget.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  final bool isNewRecipe;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    this.isNewRecipe = false,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _improvementController = TextEditingController();
  final TtsService _tts = TtsService();
  bool _ttsPlaying = false;
  bool _loadingNutrition = false;
  Map<String, dynamic>? _nutrition;
  List<String>? _allergens;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tts.initialize();
    _nutrition = widget.recipe.nutrition;
    _allergens = widget.recipe.allergens;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _improvementController.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.title,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          // TTS button
          IconButton(
            onPressed: _toggleTts,
            icon: Icon(_ttsPlaying ? Icons.stop : Icons.record_voice_over),
            tooltip: 'Read Recipe',
          ),
          Consumer<RecipeProvider>(
            builder: (context, provider, child) {
              return IconButton(
                onPressed: () => provider.toggleFavorite(widget.recipe.id),
                icon: Icon(
                  widget.recipe.isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: widget.recipe.isFavorite ? Colors.red : null,
                ),
              );
            },
          ),
          IconButton(onPressed: _shareRecipe, icon: const Icon(Icons.share)),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'improve',
                child: ListTile(
                  leading: Icon(Icons.auto_fix_high),
                  title: Text('Improve Recipe'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'nutrition',
                child: ListTile(
                  leading: Icon(Icons.bar_chart),
                  title: Text('Analyze Nutrition'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'allergens',
                child: ListTile(
                  leading: Icon(Icons.warning_amber),
                  title: Text('Detect Allergens'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'grocery',
                child: ListTile(
                  leading: Icon(Icons.shopping_cart),
                  title: Text('Add to Grocery List'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'sync',
                child: ListTile(
                  leading: Icon(Icons.cloud_upload),
                  title: Text('Sync to Cloud'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (!widget.isNewRecipe)
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete',
                        style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildRecipeHeader(),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Ingredients'),
                Tab(text: 'Instructions'),
                Tab(text: 'More'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildIngredientsTab(),
                  _buildInstructionsTab(),
                  _buildMoreTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.isNewRecipe
          ? FloatingActionButton.extended(
              onPressed: _saveRecipe,
              icon: const Icon(Icons.save),
              label: const Text('Save Recipe'),
            )
          : null,
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildRecipeHeader() {
    final imageHeight = MediaQuery.of(context).size.width * 0.45;
    final imageUrl = widget.recipe.imageUrl;
    final localPath = widget.recipe.localImagePath;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recipe image matched to this recipe
          if (localPath != null)
            ClipRRect(
              child: Image.file(
                File(localPath),
                height: imageHeight,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _headerImageFallback(imageHeight),
              ),
            )
          else
            ClipRRect(
              child: Image.network(
                (imageUrl != null && imageUrl.isNotEmpty)
                    ? imageUrl
                    : _recipeImageUrl(),
                height: imageHeight,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : SizedBox(
                        height: imageHeight,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                errorBuilder: (_, __, ___) => _headerImageFallback(imageHeight),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppConstants.mediumPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: AppConstants.smallPadding,
                  runSpacing: AppConstants.smallPadding,
                  children: [
                    _chip(Icons.timer, '${widget.recipe.prepTime} min prep'),
                    _chip(Icons.schedule, '${widget.recipe.cookTime} min cook'),
                    _chip(Icons.people, '${widget.recipe.servings} servings'),
                    _chip(Icons.signal_cellular_alt, widget.recipe.difficulty),
                    if (widget.recipe.cuisine != null)
                      _chip(Icons.public, widget.recipe.cuisine!),
                    if (widget.recipe.rating > 0)
                      _chip(Icons.star, widget.recipe.rating.toStringAsFixed(1),
                          color: Colors.amber),
                  ],
                ),
                if (widget.recipe.tags != null && widget.recipe.tags!.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.smallPadding),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: widget.recipe.tags!.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(tag,
                            style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500)),
                      );
                    }).toList(),
                  ),
                ],
                if (_allergens != null && _allergens!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: _allergens!.map((a) {
                      return Chip(
                        label: Text(a, style: const TextStyle(fontSize: 11)),
                        backgroundColor: Colors.red[50],
                        side: BorderSide(color: Colors.red[200]!),
                        avatar: const Icon(Icons.warning_amber, size: 14, color: Colors.red),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _recipeImageUrl() {
    final query = Uri.encodeComponent(
        widget.recipe.title.split(' ').take(3).join(' '));
    return 'https://source.unsplash.com/featured/800x400/?$query,food';
  }

  Widget _headerImageFallback(double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: Theme.of(context).primaryColor.withOpacity(0.15),
      child: Icon(Icons.restaurant, size: 60, color: Theme.of(context).primaryColor),
    );
  }

  Widget _chip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: color ??
                  Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.7)),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  // ── Ingredients Tab ───────────────────────────────────────────────────────

  Widget _buildIngredientsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.mediumPadding),
      itemCount: widget.recipe.ingredients.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  Theme.of(context).primaryColor.withOpacity(0.1),
              child: Text('${index + 1}',
                  style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold)),
            ),
            title: Text(widget.recipe.ingredients[index]),
            trailing: IconButton(
              icon: const Icon(Icons.swap_horiz, size: 20),
              tooltip: 'Find substitutes',
              onPressed: () =>
                  _showSubstitutes(widget.recipe.ingredients[index]),
            ),
          ),
        ).animate(delay: Duration(milliseconds: index * 30)).fadeIn().slideX(begin: 0.1);
      },
    );
  }

  // ── Instructions Tab ──────────────────────────────────────────────────────

  Widget _buildInstructionsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.mediumPadding),
      itemCount: widget.recipe.instructions.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: AppConstants.mediumPadding),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.mediumPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text('${index + 1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: AppConstants.mediumPadding),
                Expanded(
                  child: Text(widget.recipe.instructions[index],
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: index * 40)).fadeIn();
      },
    );
  }

  // ── More Tab ──────────────────────────────────────────────────────────────

  Widget _buildMoreTab() {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.mediumPadding),
      children: [
        // Cooking Timer
        CookingTimerWidget(
          recipeName: widget.recipe.title,
          suggestedMinutes: widget.recipe.cookTime > 0
              ? widget.recipe.cookTime
              : 30,
        ).animate().fadeIn().slideY(begin: 0.1),

        const SizedBox(height: 12),

        // Nutrition
        if (_loadingNutrition)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (_nutrition != null)
          NutritionCard(nutrition: _nutrition!)
              .animate()
              .fadeIn()
              .slideY(begin: 0.1)
        else
          _buildAnalyzeButton(
            icon: Icons.bar_chart,
            label: 'Analyze Nutrition',
            onTap: _analyzeNutrition,
          ),

        const SizedBox(height: 12),

        // AI Improve presets
        _buildImprovePresets(),

        const SizedBox(height: 12),

        // Rating
        RatingWidget(recipe: widget.recipe)
            .animate()
            .fadeIn()
            .slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildAnalyzeButton(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildImprovePresets() {
    final presets = [
      ('Healthy', Icons.favorite_border, Colors.green),
      ('Spicy 🌶', Icons.local_fire_department, Colors.red),
      ('Vegan', Icons.eco, Colors.teal),
      ('High Protein', Icons.fitness_center, Colors.blue),
      ('Weight Loss', Icons.monitor_weight, Colors.purple),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_fix_high, size: 20),
                const SizedBox(width: 8),
                Text('AI Recipe Improvement',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presets.map((p) {
                return ActionChip(
                  avatar: Icon(p.$2, size: 16, color: p.$3),
                  label: Text(p.$1),
                  onPressed: () => _improveWithPreset(p.$1),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _showImproveDialog,
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Custom improvement...'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _handleMenuAction(String action) {
    switch (action) {
      case 'improve':
        _showImproveDialog();
        break;
      case 'nutrition':
        _analyzeNutrition();
        break;
      case 'allergens':
        _detectAllergens();
        break;
      case 'grocery':
        _addToGrocery();
        break;
      case 'sync':
        _syncToCloud();
        break;
      case 'delete':
        _deleteRecipe();
        break;
    }
  }

  Future<void> _toggleTts() async {
    if (_ttsPlaying) {
      await _tts.stop();
      setState(() => _ttsPlaying = false);
    } else {
      setState(() => _ttsPlaying = true);
      await _tts.speakRecipe(widget.recipe.title, widget.recipe.ingredients,
          widget.recipe.instructions);
      setState(() => _ttsPlaying = false);
    }
  }

  Future<void> _analyzeNutrition() async {
    setState(() => _loadingNutrition = true);
    final result =
        await context.read<RecipeProvider>().analyzeNutrition(widget.recipe);
    setState(() {
      _nutrition = result;
      _loadingNutrition = false;
    });
    if (result == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not analyze nutrition')));
    } else {
      _tabController.animateTo(2);
    }
  }

  Future<void> _detectAllergens() async {
    final result =
        await context.read<RecipeProvider>().detectAllergens(widget.recipe);
    if (mounted) {
      setState(() => _allergens = result);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.isEmpty
              ? 'No common allergens detected'
              : 'Allergens: ${result.join(', ')}')));
    }
  }

  Future<void> _addToGrocery() async {
    await context
        .read<RecipeProvider>()
        .addIngredientsToGrocery(widget.recipe.ingredients);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingredients added to grocery list!')));
    }
  }

  Future<void> _syncToCloud() async {
    final fb = FirebaseService();
    if (!fb.isSignedIn) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Sign in to sync. Go to Settings > Cloud Sync')));
      }
      return;
    }
    await fb.syncRecipe(widget.recipe);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Recipe synced to cloud!')));
    }
  }

  Future<void> _showSubstitutes(String ingredient) async {
    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text('Finding substitutes...'),
        content: Center(
            heightFactor: 1,
            child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator())),
      ),
    );

    final subs = await context
        .read<RecipeProvider>()
        .getIngredientSubstitutes(ingredient, widget.recipe);

    if (mounted) {
      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Substitutes for "$ingredient"'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: subs.isEmpty
                ? [const Text('No substitutes found')]
                : subs
                    .map((s) => ListTile(
                          leading: const Icon(Icons.swap_horiz),
                          title: Text(s),
                          dense: true,
                        ))
                    .toList(),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'))
          ],
        ),
      );
    }
  }

  void _showImproveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Improve Recipe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How would you like to improve this recipe?'),
            const SizedBox(height: AppConstants.mediumPadding),
            TextField(
              controller: _improvementController,
              decoration: const InputDecoration(
                hintText: 'e.g., Make it spicier, add more vegetables...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _improveRecipe(_improvementController.text.trim());
            },
            child: const Text('Improve'),
          ),
        ],
      ),
    );
  }

  Future<void> _improveWithPreset(String preset) async {
    await _improveRecipe('Make this recipe $preset');
  }

  Future<void> _improveRecipe(String improvement) async {
    if (improvement.isEmpty) return;
    final provider = context.read<RecipeProvider>();
    await provider.improveRecipe(widget.recipe, improvement);
    _improvementController.clear();
    if (provider.currentRecipe != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => RecipeDetailScreen(
            recipe: provider.currentRecipe!,
            isNewRecipe: true,
          ),
        ),
      );
    }
  }

  void _deleteRecipe() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: const Text('Are you sure you want to delete this recipe?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final fb = FirebaseService();
              if (fb.isSignedIn) {
                await fb.deleteCloudRecipe(widget.recipe.id);
              }
              if (context.mounted) {
                context.read<RecipeProvider>().deleteRecipe(widget.recipe.id);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _shareRecipe() {
    final text = '''
${widget.recipe.title}

Ingredients:
${widget.recipe.ingredients.map((i) => '• $i').join('\n')}

Instructions:
${widget.recipe.instructions.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}

Prep: ${widget.recipe.prepTime} min | Cook: ${widget.recipe.cookTime} min | Serves: ${widget.recipe.servings}

Generated by ChefAI
''';
    Share.share(text, subject: widget.recipe.title);
  }

  Future<void> _saveRecipe() async {
    await context.read<RecipeProvider>().saveRecipe(widget.recipe);
    // Auto-sync if signed in
    await FirebaseService().syncRecipe(widget.recipe);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Recipe saved!'),
            backgroundColor: AppConstants.primaryColor),
      );
      Navigator.of(context).pop();
    }
  }
}
