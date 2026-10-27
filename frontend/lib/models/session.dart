import 'version.dart';

enum SessionStatus { active, finished }

enum EventType { substitution, quantityChange, timingChange, note, unclear }

enum EventStatus { pending, confirmed, undone }

class ParsedEvent {
  final String? original;
  final String? replacement;
  final String? quantity;

  const ParsedEvent({this.original, this.replacement, this.quantity});

  Map<String, dynamic> toJson() => {
    'original': original,
    'replacement': replacement,
    'quantity': quantity,
  };

  factory ParsedEvent.fromJson(Map<String, dynamic> json) => ParsedEvent(
    original: json['original'] as String?,
    replacement: json['replacement'] as String?,
    quantity: json['quantity'] as String?,
  );

  Substitution toSubstitution(int stepIndex) => Substitution(
    original: original ?? '',
    replacement: replacement ?? '',
    quantity: quantity,
    stepIndex: stepIndex,
  );
}

class CookingEvent {
  final String id;
  final EventType type;
  final EventStatus status;
  final int stepIndex;
  final String rawText;
  final ParsedEvent? parsed;
  final String? readBack;

  const CookingEvent({
    required this.id,
    required this.type,
    required this.status,
    required this.stepIndex,
    required this.rawText,
    this.parsed,
    this.readBack,
  });

  CookingEvent copyWith({
    String? id,
    EventType? type,
    EventStatus? status,
    int? stepIndex,
    String? rawText,
    ParsedEvent? parsed,
    String? readBack,
  }) {
    return CookingEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      stepIndex: stepIndex ?? this.stepIndex,
      rawText: rawText ?? this.rawText,
      parsed: parsed ?? this.parsed,
      readBack: readBack ?? this.readBack,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'status': status.name,
    'stepIndex': stepIndex,
    'rawText': rawText,
    'parsed': parsed?.toJson(),
    'readBack': readBack,
  };
}

class CookingSession {
  final String id;
  final String recipeId;
  final SessionStatus status;
  final int currentStep;
  final DateTime startedAt;
  final List<CookingEvent> events;

  const CookingSession({
    required this.id,
    required this.recipeId,
    required this.status,
    required this.currentStep,
    required this.startedAt,
    required this.events,
  });

  List<CookingEvent> get confirmedEvents =>
      events.where((e) => e.status == EventStatus.confirmed).toList();

  CookingSession copyWith({
    String? id,
    String? recipeId,
    SessionStatus? status,
    int? currentStep,
    DateTime? startedAt,
    List<CookingEvent>? events,
  }) {
    return CookingSession(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      startedAt: startedAt ?? this.startedAt,
      events: events ?? this.events,
    );
  }
}
