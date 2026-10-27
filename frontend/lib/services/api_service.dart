// Mock API service — all calls are in-memory.
// Replace baseUrl and switch to real HTTP calls when the backend is ready.

import 'dart:math';
import '../models/recipe.dart';
import '../models/version.dart';
import '../models/session.dart';
import '../data/mock_data.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  // Mutable in-memory state (mirrors what the backend would store).
  final List<Recipe> _recipes = List.from(mockRecipes);
  final Map<String, List<RecipeVersion>> _versions = {
    for (final entry in mockVersions.entries) entry.key: List.from(entry.value),
  };
  final Map<String, CookingSession> _sessions = {};

  final _rng = Random();

  String _newId(String prefix) =>
      '${prefix}_${_rng.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  // ── Recipes ────────────────────────────────────────────────────────────────

  Future<List<Recipe>> listRecipes() async {
    await _delay();
    return List.unmodifiable(_recipes);
  }

  Future<Recipe> getRecipe(String id) async {
    await _delay();
    return _recipes.firstWhere((r) => r.id == id,
        orElse: () => throw ApiException('not_found', 'Recipe not found'));
  }

  Future<List<RecipeVersion>> getVersions(String recipeId) async {
    await _delay();
    return List.unmodifiable(_versions[recipeId] ?? []);
  }

  /// Parses raw text into a draft recipe — mock returns a plausible structure.
  Future<Recipe> parseRecipe(String rawText) async {
    await _delay(ms: 900);
    // In the real app this is a model call. Here we extract a title from the
    // first non-empty line and return a minimal draft.
    final lines = rawText.trim().split('\n').where((l) => l.trim().isNotEmpty).toList();
    final title = lines.isNotEmpty ? lines.first.trim() : 'New Recipe';
    return Recipe(
      id: '',
      title: title,
      ingredients: const [
        Ingredient(name: 'ingredient 1', quantity: '1 cup'),
        Ingredient(name: 'ingredient 2', quantity: '2 tbsp'),
      ],
      steps: const [
        RecipeStep(index: 0, text: 'Step 1 — review and edit this step.'),
        RecipeStep(index: 1, text: 'Step 2 — review and edit this step.'),
      ],
      versionCount: 0,
    );
  }

  Future<Recipe> saveRecipe(Recipe draft) async {
    await _delay();
    final recipe = draft.copyWith(id: _newId('rec'), versionCount: 1);
    _recipes.insert(0, recipe);
    // Create version 1 (original).
    final v1 = RecipeVersion(
      id: _newId('ver'),
      recipeId: recipe.id,
      number: 1,
      createdAt: DateTime.now().toUtc(),
      substitutions: const [],
    );
    _versions[recipe.id] = [v1];
    return recipe;
  }

  // ── Sessions ───────────────────────────────────────────────────────────────

  Future<CookingSession> startSession(String recipeId) async {
    await _delay();
    final session = CookingSession(
      id: _newId('sess'),
      recipeId: recipeId,
      status: SessionStatus.active,
      currentStep: 0,
      startedAt: DateTime.now().toUtc(),
      events: const [],
    );
    _sessions[session.id] = session;
    return session;
  }

  Future<CookingSession> moveToStep(String sessionId, int step) async {
    await _delay();
    final session = _getSession(sessionId);
    final updated = session.copyWith(currentStep: step);
    _sessions[sessionId] = updated;
    return updated;
  }

  Future<CookingEvent> sendEvent(String sessionId, String text) async {
    await _delay(ms: 700);
    final session = _getSession(sessionId);
    if (session.status == SessionStatus.finished) {
      throw ApiException('session_finished', 'This cooking session is already finished.');
    }

    // Mock extraction: detect substitution keywords.
    final lower = text.toLowerCase();
    final isSubstitution = lower.contains(' instead') ||
        lower.contains('using') ||
        lower.contains('replacing') ||
        lower.contains('substitute') ||
        lower.contains(' for ');

    CookingEvent event;
    if (isSubstitution) {
      // Very simple mock parse — real version calls the model.
      final parsed = ParsedEvent(
        original: 'original ingredient',
        replacement: 'replacement ingredient',
        quantity: null,
      );
      event = CookingEvent(
        id: _newId('evt'),
        type: EventType.substitution,
        status: EventStatus.pending,
        stepIndex: session.currentStep,
        rawText: text,
        parsed: parsed,
        readBack: 'Noted: replacement ingredient instead of original ingredient. Right?',
      );
    } else if (lower.contains('note') || lower.contains('remember') || lower.contains('next time')) {
      event = CookingEvent(
        id: _newId('evt'),
        type: EventType.note,
        status: EventStatus.pending,
        stepIndex: session.currentStep,
        rawText: text,
        parsed: null,
        readBack: 'Got it — saved as a note. Right?',
      );
    } else {
      event = CookingEvent(
        id: _newId('evt'),
        type: EventType.unclear,
        status: EventStatus.pending,
        stepIndex: session.currentStep,
        rawText: text,
        parsed: null,
        readBack: "Sorry, I didn't catch that. Say it again or type it.",
      );
    }

    final updated = session.copyWith(events: [...session.events, event]);
    _sessions[sessionId] = updated;
    return event;
  }

  Future<CookingEvent> confirmEvent(String sessionId, String eventId) async {
    await _delay();
    return _updateEventStatus(sessionId, eventId, EventStatus.confirmed);
  }

  Future<CookingEvent> undoEvent(String sessionId, String eventId) async {
    await _delay();
    return _updateEventStatus(sessionId, eventId, EventStatus.undone);
  }

  Future<({RecipeVersion version, Recipe recipe})> finishSession(
    String sessionId, {
    required int rating,
    String? note,
  }) async {
    await _delay(ms: 600);
    final session = _getSession(sessionId);
    final recipe = await getRecipe(session.recipeId);

    final confirmed = session.confirmedEvents;
    final substitutions = confirmed
        .where((e) => e.type == EventType.substitution && e.parsed != null)
        .map((e) => e.parsed!.toSubstitution(e.stepIndex))
        .toList();

    final existingVersions = _versions[session.recipeId] ?? [];
    final newNumber = existingVersions.length + 1;

    final version = RecipeVersion(
      id: _newId('ver'),
      recipeId: session.recipeId,
      number: newNumber,
      createdAt: DateTime.now().toUtc(),
      rating: rating,
      note: note,
      substitutions: substitutions,
    );

    _versions[session.recipeId] = [version, ...existingVersions];

    // Update recipe aggregate fields.
    final allRatings = [
      ...existingVersions.where((v) => v.rating != null).map((v) => v.rating!),
      rating,
    ];
    final avg = allRatings.reduce((a, b) => a + b) / allRatings.length;
    final latestSwap = substitutions.isNotEmpty
        ? '${substitutions.last.replacement} for ${substitutions.last.original}'
        : recipe.latestSwap;

    final updatedRecipe = recipe.copyWith(
      versionCount: newNumber,
      avgRating: avg,
      lastCookedAt: DateTime.now().toUtc(),
      latestSwap: latestSwap,
    );
    final idx = _recipes.indexWhere((r) => r.id == recipe.id);
    if (idx >= 0) _recipes[idx] = updatedRecipe;

    // Mark session finished.
    _sessions[sessionId] = session.copyWith(status: SessionStatus.finished);

    return (version: version, recipe: updatedRecipe);
  }

  // ── Ask ────────────────────────────────────────────────────────────────────

  Future<AskResponse> ask(String question, List<AskTurn> history) async {
    await _delay(ms: 1200);

    // Find any versions that mention the keywords from the question.
    final lower = question.toLowerCase();
    final sources = <AskSource>[];

    for (final entry in _versions.entries) {
      final recipe = _recipes.firstWhere((r) => r.id == entry.key,
          orElse: () => _recipes.first);
      for (final version in entry.value) {
        if (version.substitutions.isEmpty) continue;
        for (final sub in version.substitutions) {
          if (lower.contains(sub.original.toLowerCase()) ||
              lower.contains(sub.replacement.toLowerCase()) ||
              lower.contains(recipe.title.toLowerCase())) {
            sources.add(AskSource(
              versionId: version.id,
              recipeId: recipe.id,
              recipeTitle: recipe.title,
              versionNumber: version.number,
              date: version.createdAt,
              rating: version.rating,
              summary: '${sub.replacement} for ${sub.original}',
            ));
          }
        }
      }
    }

    final basedOn = sources.isNotEmpty ? 'history' : 'general';
    final answer = sources.isNotEmpty
        ? _buildHistoryAnswer(sources)
        : "You haven't tried this one before. Based on general cooking knowledge: ${_genericCookingTip(question)}";

    return AskResponse(answer: answer, basedOn: basedOn, sources: sources);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  CookingSession _getSession(String id) =>
      _sessions[id] ??
      (throw ApiException('not_found', 'Session not found'));

  CookingEvent _updateEventStatus(
      String sessionId, String eventId, EventStatus newStatus) {
    final session = _getSession(sessionId);
    final events = session.events.map((e) {
      return e.id == eventId ? e.copyWith(status: newStatus) : e;
    }).toList();
    _sessions[sessionId] = session.copyWith(events: events);
    return events.firstWhere((e) => e.id == eventId);
  }

  Future<void> _delay({int ms = 300}) =>
      Future.delayed(Duration(milliseconds: ms));

  String _buildHistoryAnswer(List<AskSource> sources) {
    final buf = StringBuffer();
    for (final s in sources.take(2)) {
      buf.write('${s.recipeTitle} v${s.versionNumber}: ${s.summary}');
      if (s.rating != null) buf.write(' (${s.rating}/5)');
      buf.write('. ');
    }
    return buf.toString().trim();
  }

  String _genericCookingTip(String question) {
    return 'A 1:1 swap often works — taste as you go and adjust seasoning.';
  }

  // Dev reset.
  void devReset() {
    _recipes
      ..clear()
      ..addAll(mockRecipes.map((r) => r));
    _versions
      ..clear()
      ..addAll({
        for (final entry in mockVersions.entries) entry.key: List.from(entry.value),
      });
    _sessions.clear();
  }
}

class ApiException implements Exception {
  final String code;
  final String message;
  ApiException(this.code, this.message);
  @override
  String toString() => 'ApiException($code): $message';
}

class AskTurn {
  final String role;
  final String text;
  const AskTurn({required this.role, required this.text});
}

class AskSource {
  final String versionId;
  final String recipeId;
  final String recipeTitle;
  final int versionNumber;
  final DateTime date;
  final int? rating;
  final String summary;
  const AskSource({
    required this.versionId,
    required this.recipeId,
    required this.recipeTitle,
    required this.versionNumber,
    required this.date,
    required this.rating,
    required this.summary,
  });
}

class AskResponse {
  final String answer;
  final String basedOn;
  final List<AskSource> sources;
  const AskResponse({
    required this.answer,
    required this.basedOn,
    required this.sources,
  });
}
