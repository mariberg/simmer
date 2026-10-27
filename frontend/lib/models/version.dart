class Substitution {
  final String original;
  final String replacement;
  final String? quantity;
  final int stepIndex;

  const Substitution({
    required this.original,
    required this.replacement,
    this.quantity,
    required this.stepIndex,
  });

  Map<String, dynamic> toJson() => {
    'original': original,
    'replacement': replacement,
    'quantity': quantity,
    'stepIndex': stepIndex,
  };

  factory Substitution.fromJson(Map<String, dynamic> json) => Substitution(
    original: json['original'] as String,
    replacement: json['replacement'] as String,
    quantity: json['quantity'] as String?,
    stepIndex: json['stepIndex'] as int,
  );
}

class RecipeVersion {
  final String id;
  final String recipeId;
  final int number;
  final DateTime createdAt;
  final int? rating;
  final String? note;
  final List<Substitution> substitutions;

  const RecipeVersion({
    required this.id,
    required this.recipeId,
    required this.number,
    required this.createdAt,
    this.rating,
    this.note,
    required this.substitutions,
  });

  bool get isOriginal => number == 1;

  Map<String, dynamic> toJson() => {
    'id': id,
    'recipeId': recipeId,
    'number': number,
    'createdAt': createdAt.toIso8601String(),
    'rating': rating,
    'note': note,
    'substitutions': substitutions.map((s) => s.toJson()).toList(),
  };

  factory RecipeVersion.fromJson(Map<String, dynamic> json) => RecipeVersion(
    id: json['id'] as String,
    recipeId: json['recipeId'] as String,
    number: json['number'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
    rating: json['rating'] as int?,
    note: json['note'] as String?,
    substitutions: (json['substitutions'] as List)
        .map((s) => Substitution.fromJson(s as Map<String, dynamic>))
        .toList(),
  );
}
