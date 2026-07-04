// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecipeAdapter extends TypeAdapter<Recipe> {
  @override
  final int typeId = 0;

  @override
  Recipe read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Recipe(
      id: fields[0] as String?,
      title: fields[1] as String,
      ingredients: (fields[2] as List).cast<String>(),
      instructions: (fields[3] as List).cast<String>(),
      prepTime: fields[4] as int,
      cookTime: fields[5] as int,
      servings: fields[6] as int,
      difficulty: fields[7] as String,
      createdAt: fields[8] as DateTime?,
      isFavorite: fields[9] as bool,
      cuisine: fields[10] as String?,
      tags: (fields[11] as List?)?.cast<String>(),
      imageUrl: fields[12] as String?,
      nutrition: (fields[13] as Map?)?.cast<String, dynamic>(),
      rating: (fields[14] as num?)?.toDouble() ?? 0.0,
      reviews: (fields[15] as List?)?.cast<String>(),
      allergens: (fields[16] as List?)?.cast<String>(),
      localImagePath: fields[17] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Recipe obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.ingredients)
      ..writeByte(3)
      ..write(obj.instructions)
      ..writeByte(4)
      ..write(obj.prepTime)
      ..writeByte(5)
      ..write(obj.cookTime)
      ..writeByte(6)
      ..write(obj.servings)
      ..writeByte(7)
      ..write(obj.difficulty)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.isFavorite)
      ..writeByte(10)
      ..write(obj.cuisine)
      ..writeByte(11)
      ..write(obj.tags)
      ..writeByte(12)
      ..write(obj.imageUrl)
      ..writeByte(13)
      ..write(obj.nutrition)
      ..writeByte(14)
      ..write(obj.rating)
      ..writeByte(15)
      ..write(obj.reviews)
      ..writeByte(16)
      ..write(obj.allergens)
      ..writeByte(17)
      ..write(obj.localImagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
