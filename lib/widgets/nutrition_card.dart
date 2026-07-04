import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NutritionCard extends StatelessWidget {
  final Map<String, dynamic> nutrition;

  const NutritionCard({super.key, required this.nutrition});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NutritionItem('Calories', nutrition['calories'], 'kcal', Colors.orange, 2000),
      _NutritionItem('Protein', nutrition['protein'], 'g', Colors.blue, 50),
      _NutritionItem('Carbs', nutrition['carbs'], 'g', Colors.green, 300),
      _NutritionItem('Fat', nutrition['fat'], 'g', Colors.red, 65),
      if (nutrition['fiber'] != null)
        _NutritionItem('Fiber', nutrition['fiber'], 'g', Colors.teal, 25),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, size: 20),
                const SizedBox(width: 8),
                Text('Nutrition (per serving)',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            ...items.asMap().entries.map((e) => _buildRow(context, e.value, e.key)),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, _NutritionItem item, int index) {
    final value = (item.value ?? 0).toDouble();
    final pct = (value / item.dailyValue).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.label,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              Text('${value.toStringAsFixed(0)} ${item.unit}',
                  style: TextStyle(color: item.color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(item.color),
              minHeight: 6,
            ),
          ).animate(delay: Duration(milliseconds: index * 100)).slideX(begin: -1, end: 0),
        ],
      ),
    );
  }
}

class _NutritionItem {
  final String label;
  final dynamic value;
  final String unit;
  final Color color;
  final double dailyValue;
  const _NutritionItem(this.label, this.value, this.unit, this.color, this.dailyValue);
}
