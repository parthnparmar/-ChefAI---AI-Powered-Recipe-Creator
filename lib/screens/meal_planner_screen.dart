import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/meal_plan.dart';
import '../providers/recipe_provider.dart';
import '../screens/recipe_detail_screen.dart';

class MealPlannerScreen extends StatelessWidget {
  const MealPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Meal Planner'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<RecipeProvider>(
        builder: (context, provider, _) {
          final plan = provider.mealPlan;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: MealPlan.days.length,
            itemBuilder: (context, di) {
              final day = MealPlan.days[di];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(day,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...MealPlan.meals.map((meal) {
                        final recipeId = plan.plan[day]?[meal];
                        final recipe = recipeId != null
                            ? provider.recipes
                                .where((r) => r.id == recipeId)
                                .firstOrNull
                            : null;
                        return _MealSlot(
                          meal: meal,
                          recipe: recipe?.title,
                          onTap: () => _showPicker(context, provider, day, meal),
                          onClear: recipeId != null
                              ? () => provider.updateMealPlan(day, meal, null)
                              : null,
                          onView: recipe != null
                              ? () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          RecipeDetailScreen(recipe: recipe),
                                    ),
                                  )
                              : null,
                        );
                      }),
                    ],
                  ),
                ),
              ).animate(delay: Duration(milliseconds: di * 60)).fadeIn().slideY(begin: 0.1);
            },
          );
        },
      ),
    );
  }

  void _showPicker(BuildContext context, RecipeProvider provider, String day,
      String meal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Pick recipe for $meal on $day',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: provider.recipes.length,
                itemBuilder: (_, i) {
                  final r = provider.recipes[i];
                  return ListTile(
                    title: Text(r.title),
                    subtitle: Text('${r.totalTime} min · ${r.difficulty}'),
                    onTap: () {
                      provider.updateMealPlan(day, meal, r.id);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealSlot extends StatelessWidget {
  final String meal;
  final String? recipe;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final VoidCallback? onView;

  const _MealSlot({
    required this.meal,
    required this.recipe,
    required this.onTap,
    this.onClear,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(meal,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: recipe != null
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: recipe != null
                        ? Theme.of(context).primaryColor.withOpacity(0.3)
                        : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  recipe ?? '+ Add recipe',
                  style: TextStyle(
                    fontSize: 13,
                    color: recipe != null
                        ? Theme.of(context).primaryColor
                        : Colors.grey[500],
                    fontWeight: recipe != null ? FontWeight.w500 : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          if (onView != null)
            IconButton(
                onPressed: onView,
                icon: const Icon(Icons.open_in_new, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints()),
          if (onClear != null)
            IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 16),
                padding: const EdgeInsets.only(left: 4),
                constraints: const BoxConstraints()),
        ],
      ),
    );
  }
}
