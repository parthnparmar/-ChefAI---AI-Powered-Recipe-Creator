import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/recipe_request.dart';
import '../providers/recipe_provider.dart';
import '../widgets/loading_widget.dart';
import '../config/api_config.dart';
import '../utils/theme.dart';
import 'recipe_detail_screen.dart';

class RecipeGeneratorScreen extends StatefulWidget {
  const RecipeGeneratorScreen({super.key});

  @override
  State<RecipeGeneratorScreen> createState() => _RecipeGeneratorScreenState();
}

class _RecipeGeneratorScreenState extends State<RecipeGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ingredientsController = TextEditingController();

  String? _selectedCuisine;
  String? _selectedDifficulty;
  String? _selectedDishType;
  int _servings = 4;
  List<String> _selectedDietaryRestrictions = [];
  List<String> _ingredientsList = [];

  @override
  void dispose() {
    _ingredientsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<RecipeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return SafeArea(
              child: Column(
                children: [
                  _buildAppBar(context),
                  const Expanded(child: AiThinkingWidget(message: 'Crafting your perfect recipe...')),
                ],
              ),
            );
          }
          if (provider.error != null) {
            return SafeArea(
              child: Column(
                children: [
                  _buildAppBar(context),
                  Expanded(child: _buildError(context, provider.error!)),
                ],
              ),
            );
          }
          return SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                if (!ApiConfig.isApiKeyValid)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: Colors.orange, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text('Demo Mode — Configure OpenAI API key for real AI recipes',
                              style: TextStyle(color: Colors.orange, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection(context, '🥕 Ingredients', _buildIngredientsSection()),
                          const SizedBox(height: 16),
                          _buildSection(context, '⚙️ Preferences', _buildPreferencesSection()),
                          const SizedBox(height: 16),
                          _buildSection(context, '🥗 Dietary Restrictions', _buildDietarySection()),
                          const SizedBox(height: 24),
                          _buildGenerateButton(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Text('Generate Recipe',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildIngredientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _ingredientsController,
          decoration: const InputDecoration(
            hintText: 'e.g., chicken, rice, tomatoes, garlic...',
            prefixIcon: Icon(Icons.add_circle_outline_rounded),
          ),
          maxLines: 2,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter at least one ingredient' : null,
          onChanged: (_) => _updateIngredients(),
        ),
        if (_ingredientsList.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _ingredientsList.map((ing) => Chip(
              label: Text(ing.trim(), style: const TextStyle(fontSize: 12)),
              deleteIcon: const Icon(Icons.close_rounded, size: 14),
              onDeleted: () => _removeIngredient(ing),
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              side: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
              labelStyle: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      children: [
        _buildDropdown('Cuisine', AppConstants.cuisines, _selectedCuisine,
            (v) => setState(() => _selectedCuisine = v), Icons.public_rounded),
        const SizedBox(height: 10),
        _buildDropdown('Dish Type', AppConstants.dishTypes, _selectedDishType,
            (v) => setState(() => _selectedDishType = v), Icons.restaurant_rounded),
        const SizedBox(height: 10),
        _buildDropdown('Difficulty', AppConstants.difficultyLevels, _selectedDifficulty,
            (v) => setState(() => _selectedDifficulty = v), Icons.bar_chart_rounded),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.people_rounded, size: 18, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text('Servings: $_servings',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Expanded(
              child: Slider(
                value: _servings.toDouble(),
                min: 1,
                max: 12,
                divisions: 11,
                activeColor: AppTheme.primary,
                onChanged: (v) => setState(() => _servings = v.round()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value,
      ValueChanged<String?> onChanged, IconData icon) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
      ),
      items: [
        DropdownMenuItem(value: null, child: Text('Any $label')),
        ...items.map((i) => DropdownMenuItem(value: i, child: Text(i))),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildDietarySection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppConstants.dietaryRestrictions.map((r) {
        final selected = _selectedDietaryRestrictions.contains(r);
        return FilterChip(
          label: Text(r),
          selected: selected,
          onSelected: (s) => setState(() {
            if (s) _selectedDietaryRestrictions.add(r);
            else _selectedDietaryRestrictions.remove(r);
          }),
          selectedColor: AppTheme.primary.withOpacity(0.15),
          checkmarkColor: AppTheme.primary,
          side: BorderSide(color: selected ? AppTheme.primary : Colors.grey.withOpacity(0.3)),
        );
      }).toList(),
    );
  }

  Widget _buildGenerateButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _generate,
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text('Generate Recipe'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
            ),
            const SizedBox(height: 20),
            Text('Something went wrong', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(error, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<RecipeProvider>().clearError(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateIngredients() {
    final text = _ingredientsController.text;
    setState(() {
      _ingredientsList = text.isEmpty
          ? []
          : text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    });
  }

  void _removeIngredient(String ing) {
    setState(() {
      _ingredientsList.remove(ing);
      _ingredientsController.text = _ingredientsList.join(', ');
    });
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;
    final request = RecipeRequest(
      ingredients: _ingredientsList,
      dishType: _selectedDishType,
      cuisine: _selectedCuisine,
      difficulty: _selectedDifficulty,
      servings: _servings,
      dietaryRestrictions: _selectedDietaryRestrictions.isNotEmpty ? _selectedDietaryRestrictions : null,
    );
    final provider = context.read<RecipeProvider>();
    await provider.generateRecipe(request);
    if (provider.currentRecipe != null && mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipe: provider.currentRecipe!, isNewRecipe: true),
      ));
    }
  }
}
