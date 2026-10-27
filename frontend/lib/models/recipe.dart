class Ingredient {
  final String name;
  final String? quantity;
  final String? unit;

  const Ingredient({required this.name, this.quantity, this.unit});

  String get display {
    final parts = <String>[];
    if (quantity != null) parts.add(quantity!);
    if (unit != null) parts.add(unit!);
    parts.add(name);
    return parts.join(' ');
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'unit': unit,
  };

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
    name: json['name'] as String,
    quantity: json['quantity'] as String?,
    unit: json['unit'] as String?,
  );
}

class RecipeStep {
  final int index;
  final String text;
  final int? timerSeconds;

  const RecipeStep({required this.index, required this.text, this.timerSeconds});

  Map<String, dynamic> toJson() => {
    'index': index,
    'text': text,
    'timerSeconds': timerSeconds,
  };

  factory RecipeStep.fromJson(Map<String, dynamic> json) => RecipeStep(
    index: json['index'] as int,
    text: json['text'] as String,
    timerSeconds: json['timerSeconds'] as int?,
  );
}

class Recipe {
  final String id;
  final String title;
  final List<Ingredient> ingredients;
  final List<RecipeStep> steps;
  final int versionCount;
  final double? avgRating;
  final DateTime? lastCookedAt;
  final String? latestSwap;

  const Recipe({
    required this.id,
    required this.title,
    required this.ingredients,
    required this.steps,
    required this.versionCount,
    this.avgRating,
    this.lastCookedAt,
    this.latestSwap,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'ingredients': ingredients.map((i) => i.toJson()).toList(),
    'steps': steps.map((s) => s.toJson()).toList(),
    'versionCount': versionCount,
    'avgRating': avgRating,
    'lastCookedAt': lastCookedAt?.toIso8601String(),
    'latestSwap': latestSwap,
  };

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
    id: json['id'] as String,
    title: json['title'] as String,
    ingredients: (json['ingredients'] as List)
        .map((i) => Ingredient.fromJson(i as Map<String, dynamic>))
        .toList(),
    steps: (json['steps'] as List)
        .map((s) => RecipeStep.fromJson(s as Map<String, dynamic>))
        .toList(),
    versionCount: json['versionCount'] as int,
    avgRating: (json['avgRating'] as num?)?.toDouble(),
    lastCookedAt: json['lastCookedAt'] != null
        ? DateTime.parse(json['lastCookedAt'] as String)
        : null,
    latestSwap: json['latestSwap'] as String?,
  );

  Recipe copyWith({
    String? id,
    String? title,
    List<Ingredient>? ingredients,
    List<RecipeStep>? steps,
    int? versionCount,
    double? avgRating,
    DateTime? lastCookedAt,
    String? latestSwap,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      versionCount: versionCount ?? this.versionCount,
      avgRating: avgRating ?? this.avgRating,
      lastCookedAt: lastCookedAt ?? this.lastCookedAt,
      latestSwap: latestSwap ?? this.latestSwap,
    );
  }
}
