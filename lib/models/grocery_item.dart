class GroceryItem {
  final String id;
  final String name;
  bool isChecked;
  final String? category;

  GroceryItem({
    required this.id,
    required this.name,
    this.isChecked = false,
    this.category,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isChecked': isChecked,
    'category': category,
  };

  factory GroceryItem.fromJson(Map<String, dynamic> json) => GroceryItem(
    id: json['id'],
    name: json['name'],
    isChecked: json['isChecked'] ?? false,
    category: json['category'],
  );
}
