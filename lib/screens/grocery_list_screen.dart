import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../constants/app_constants.dart';
import '../models/grocery_item.dart';
import '../providers/recipe_provider.dart';

class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({super.key});

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear checked',
            onPressed: () => context.read<RecipeProvider>().clearCheckedGroceryItems(),
          ),
        ],
      ),
      body: Consumer<RecipeProvider>(
        builder: (context, provider, _) {
          final items = provider.groceryList;
          final unchecked = items.where((i) => !i.isChecked).toList();
          final checked = items.where((i) => i.isChecked).toList();

          return Column(
            children: [
              _buildAddItem(provider),
              Expanded(
                child: items.isEmpty
                    ? _buildEmpty()
                    : ListView(
                        padding: const EdgeInsets.all(AppConstants.mediumPadding),
                        children: [
                          if (unchecked.isNotEmpty) ...[
                            _buildSectionLabel('To Buy (${unchecked.length})'),
                            ...unchecked.asMap().entries.map((e) =>
                                FadeInLeft(delay: Duration(milliseconds: e.key * 50), child: _buildItem(e.value, provider))),
                          ],
                          if (checked.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildSectionLabel('Done (${checked.length})'),
                            ...checked.map((item) => _buildItem(item, provider)),
                          ],
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddItem(RecipeProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.mediumPadding),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Add item...',
                prefixIcon: Icon(Icons.add_shopping_cart),
              ),
              onSubmitted: (_) => _addItem(provider),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _addItem(provider),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addItem(RecipeProvider provider) {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      provider.addIngredientsToGrocery([text]);
      _controller.clear();
    }
  }

  Widget _buildItem(GroceryItem item, RecipeProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: Checkbox(
          value: item.isChecked,
          onChanged: (_) => provider.toggleGroceryItem(item.id),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.isChecked ? TextDecoration.lineThrough : null,
            color: item.isChecked ? Colors.grey : null,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: () => provider.removeGroceryItem(item.id),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Your grocery list is empty', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Add items or import from a recipe', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }
}
