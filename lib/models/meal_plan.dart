class MealPlan {
  final String id;
  final DateTime weekStart;
  final Map<String, Map<String, String?>> plan; // {day: {breakfast/lunch/dinner: recipeId}}

  MealPlan({
    required this.id,
    required this.weekStart,
    required this.plan,
  });

  static const List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const List<String> meals = ['Breakfast', 'Lunch', 'Dinner'];

  Map<String, dynamic> toJson() => {
    'id': id,
    'weekStart': weekStart.toIso8601String(),
    'plan': plan,
  };

  factory MealPlan.fromJson(Map<String, dynamic> json) => MealPlan(
    id: json['id'],
    weekStart: DateTime.parse(json['weekStart']),
    plan: (json['plan'] as Map<String, dynamic>).map(
      (day, meals) => MapEntry(
        day,
        (meals as Map<String, dynamic>).map((meal, id) => MapEntry(meal, id as String?)),
      ),
    ),
  );

  factory MealPlan.empty() {
    final plan = <String, Map<String, String?>>{};
    for (final day in days) {
      plan[day] = {for (final meal in meals) meal: null};
    }
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return MealPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      weekStart: weekStart,
      plan: plan,
    );
  }

  MealPlan copyWithMeal(String day, String meal, String? recipeId) {
    final newPlan = Map<String, Map<String, String?>>.from(
      plan.map((d, m) => MapEntry(d, Map<String, String?>.from(m))),
    );
    newPlan[day]?[meal] = recipeId;
    return MealPlan(id: id, weekStart: weekStart, plan: newPlan);
  }
}
