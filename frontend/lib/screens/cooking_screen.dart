import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/recipe.dart';
import '../models/session.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/page_shell.dart';

class CookingScreen extends StatefulWidget {
  final String recipeId;
  final Recipe? recipe;
  const CookingScreen({super.key, required this.recipeId, this.recipe});

  @override
  State<CookingScreen> createState() => _CookingScreenState();
}

class _CookingScreenState extends State<CookingScreen> {
  Recipe? _recipe;
  CookingSession? _session;
  bool _loading = true;
  String? _error;

  final _textController = TextEditingController();
  bool _sending = false;
  bool _showTextInput = false;
  bool _ingredientsExpanded = false;

  // Timer
  int? _timerRemaining;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final recipe = widget.recipe ?? await ApiService().getRecipe(widget.recipeId);
      final session = await ApiService().startSession(widget.recipeId);
      setState(() {
        _recipe = recipe;
        _session = session;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _textController.dispose();
    super.dispose();
  }

  RecipeStep get _step => _recipe!.steps[_session!.currentStep];
  bool get _isFirst => _session!.currentStep == 0;
  bool get _isLast  => _session!.currentStep == _recipe!.steps.length - 1;

  Future<void> _navigate(int delta) async {
    final next = _session!.currentStep + delta;
    if (next < 0 || next >= _recipe!.steps.length) return;
    _stopTimer();
    setState(() => _ingredientsExpanded = false);
    final updated = await ApiService().moveToStep(_session!.id, next);
    setState(() => _session = updated);
  }

  Future<void> _send(String text) async {
    text = text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    setState(() { _sending = true; _showTextInput = false; });
    try {
      final event = await ApiService().sendEvent(_session!.id, text);
      setState(() {
        _session = _session!.copyWith(events: [..._session!.events, event]);
        _sending = false;
      });
    } catch (e) {
      setState(() => _sending = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _confirm(String eventId) async {
    final evt = await ApiService().confirmEvent(_session!.id, eventId);
    _replaceEvent(evt);
  }

  Future<void> _undo(String eventId) async {
    final evt = await ApiService().undoEvent(_session!.id, eventId);
    _replaceEvent(evt);
  }

  void _replaceEvent(CookingEvent updated) {
    final events = _session!.events
        .map((e) => e.id == updated.id ? updated : e)
        .toList();
    setState(() => _session = _session!.copyWith(events: events));
  }

  void _startTimer() {
    final secs = _step.timerSeconds;
    if (secs == null) return;
    _stopTimer();
    setState(() { _timerRemaining = secs; });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timerRemaining == null || _timerRemaining! <= 0) {
        _ticker?.cancel();
        return;
      }
      setState(() => _timerRemaining = _timerRemaining! - 1);
    });
  }

  void _pauseTimer() {
    _ticker?.cancel();
    _ticker = null;
    setState(() {}); // re-render to swap button label
  }

  bool get _timerRunning => _ticker != null && _ticker!.isActive;

  void _stopTimer() {
    _ticker?.cancel();
    _ticker = null;
    setState(() { _timerRemaining = null; });
  }

  String _fmt(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  // Label shown above the time (first word of step, uppercased)
  String get _timerLabel {
    final words = _step.text.split(' ');
    return words.first.replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.darkBg,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }
    if (_error != null || _recipe == null || _session == null) {
      return Scaffold(
        backgroundColor: AppColors.darkBg,
        appBar: AppBar(backgroundColor: AppColors.darkBg),
        body: Center(
          child: Text(_error ?? 'Error', style: AppTypography.body(16, color: AppColors.darkText)),
        ),
      );
    }

    final step = _step;
    final pendingEvents = _session!.events.where((e) => e.status == EventStatus.pending).toList();
    final confirmedEvents = _session!.confirmedEvents;
    final totalSteps = _recipe!.steps.length;
    final currentStep = _session!.currentStep;

    return PageShell(
      child: Scaffold(
        backgroundColor: AppColors.darkBg,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    // Close
                    SizedBox(
                      height: 44,
                      child: TextButton(
                        onPressed: _showExitDialog,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.darkMuted,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(44, 44),
                        ),
                        child: Text('Close', style: AppTypography.body(16, color: AppColors.darkMuted)),
                      ),
                    ),
                    const Spacer(),
                    // Recipe · step
                    Text(
                      '${_recipe!.title} · Step ${currentStep + 1} of $totalSteps',
                      style: AppTypography.body(15, color: AppColors.darkMuted),
                    ),
                  ],
                ),
              ),

              // ── Progress bar ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (currentStep + 1) / totalSteps,
                    minHeight: 6,
                    backgroundColor: AppColors.progressTrack,
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
              ),

              // ── Scrollable body ───────────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const SizedBox(height: 20),

                    // Step text
                    Text(
                      step.text,
                      style: AppTypography.heading(30,
                          color: AppColors.darkText)
                          .copyWith(height: 1.2),
                    ),
                    const SizedBox(height: 16),

                    // Timer card
                    if (step.timerSeconds != null)
                      _TimerCard(
                        label: _timerLabel,
                        total: step.timerSeconds!,
                        remaining: _timerRemaining,
                        running: _timerRunning,
                        onStart: _startTimer,
                        onPause: _pauseTimer,
                        fmt: _fmt,
                      ),

                    const SizedBox(height: 12),

                    // Ingredients toggle
                    _IngredientsToggle(
                      recipe: _recipe!,
                      expanded: _ingredientsExpanded,
                      onToggle: () => setState(() => _ingredientsExpanded = !_ingredientsExpanded),
                    ),

                    const SizedBox(height: 16),

                    // Confirmed events
                    if (confirmedEvents.isNotEmpty) ...[
                      Text(
                        'LOGGED SO FAR',
                        style: AppTypography.smallCaps(color: AppColors.darkMuted),
                      ),
                      const SizedBox(height: 8),
                      ...confirmedEvents.map((e) => _ConfirmedChip(
                        event: e,
                        onUndo: () => _undo(e.id),
                      )),
                      const SizedBox(height: 8),
                    ],

                    // Pending events (confirm cards)
                    ...pendingEvents.map((e) => _ConfirmCard(
                      event: e,
                      onConfirm: e.type != EventType.unclear ? () => _confirm(e.id) : null,
                      onFix: () {
                        _undo(e.id);
                        setState(() => _showTextInput = true);
                        // Focus is best-effort; no context needed here.

                      },
                    )),

                    const SizedBox(height: 80),
                  ],
                ),
              ),

              // ── Bottom area ───────────────────────────────────────────────
              _CookingBottomArea(
                isFirst: _isFirst,
                isLast: _isLast,
                showTextInput: _showTextInput,
                sending: _sending,
                controller: _textController,
                onMicOrType: () => setState(() => _showTextInput = !_showTextInput),
                onSend: () => _send(_textController.text),
                onBack: () => _navigate(-1),
                onNext: _isLast ? _goToFinish : () => _navigate(1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToFinish() {
    context.push('/finish/${_session!.id}', extra: _session);
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Text('Leave session?',
            style: AppTypography.heading(18, color: AppColors.darkText)),
        content: Text(
          "Your notes won't be saved.",
          style: AppTypography.body(15, color: AppColors.darkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Stay', style: AppTypography.body(15, color: AppColors.accent)),
          ),
          TextButton(
            onPressed: () { Navigator.pop(ctx); context.pop(); },
            child: Text('Leave', style: AppTypography.body(15, color: AppColors.darkMuted)),
          ),
        ],
      ),
    );
  }
}

// ── Timer card ────────────────────────────────────────────────────────────────

class _TimerCard extends StatelessWidget {
  final String label;
  final int total;
  final int? remaining;
  final bool running;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final String Function(int) fmt;

  const _TimerCard({
    required this.label,
    required this.total,
    required this.remaining,
    required this.running,
    required this.onStart,
    required this.onPause,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final display = remaining ?? total;
    final isDone = remaining == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkLine),
      ),
      child: Row(
        children: [
          // Label + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.smallCaps(color: AppColors.darkMuted)),
                const SizedBox(height: 2),
                Text(
                  isDone ? "Time's up" : fmt(display),
                  style: AppTypography.display(44, color: isDone ? AppColors.accent : AppColors.darkText),
                ),
              ],
            ),
          ),
          // Button
          if (!isDone)
            _AccentPill(
              height: 52,
              label: running ? 'Pause' : 'Start timer',
              fontSize: 17,
              onTap: running ? onPause : onStart,
            ),
        ],
      ),
    );
  }
}

// ── Ingredients toggle ────────────────────────────────────────────────────────

class _IngredientsToggle extends StatelessWidget {
  final Recipe recipe;
  final bool expanded;
  final VoidCallback onToggle;

  const _IngredientsToggle({
    required this.recipe,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkLine),
            ),
            child: Row(
              children: [
                Text(
                  'Ingredients (${recipe.ingredients.length})',
                  style: AppTypography.body(15, color: AppColors.darkText),
                ),
                const Spacer(),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.darkMuted,
                ),
              ],
            ),
          ),
        ),
        if (expanded) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkLine),
            ),
            child: Column(
              children: recipe.ingredients.map((ing) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(ing.name,
                          style: AppTypography.body(15, color: AppColors.darkText)),
                    ),
                    Text(
                      [if (ing.quantity != null) ing.quantity!, if (ing.unit != null) ing.unit!].join(' '),
                      style: AppTypography.body(14, color: AppColors.darkMuted),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Confirmed chip ────────────────────────────────────────────────────────────

class _ConfirmedChip extends StatelessWidget {
  final CookingEvent event;
  final VoidCallback onUndo;

  const _ConfirmedChip({required this.event, required this.onUndo});

  @override
  Widget build(BuildContext context) {
    final parsed = event.parsed;
    final label = parsed != null
        ? '${parsed.original} → ${parsed.replacement}${parsed.quantity != null ? ' · ${parsed.quantity}' : ''}'
        : event.rawText;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkLine),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTypography.body(16, color: AppColors.darkText)),
          ),
          TextButton(
            onPressed: onUndo,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 44),
            ),
            child: Text('Undo',
                style: AppTypography.body(15,
                    weight: FontWeight.w700, color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
}

// ── Confirm card ──────────────────────────────────────────────────────────────

class _ConfirmCard extends StatelessWidget {
  final CookingEvent event;
  final VoidCallback? onConfirm;
  final VoidCallback onFix;

  const _ConfirmCard({required this.event, this.onConfirm, required this.onFix});

  @override
  Widget build(BuildContext context) {
    final isUnclear = event.type == EventType.unclear;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(event.readBack ?? event.rawText,
              style: AppTypography.body(16, color: AppColors.darkText)),
          if (!isUnclear && onConfirm != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AccentPill(
                    height: 44,
                    label: 'Yes',
                    fontSize: 16,
                    onTap: onConfirm,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onFix,
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.darkText),
                      ),
                      alignment: Alignment.center,
                      child: Text('Fix',
                          style: AppTypography.body(16,
                              weight: FontWeight.w600,
                              color: AppColors.darkText)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Bottom area ───────────────────────────────────────────────────────────────

class _CookingBottomArea extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final bool showTextInput;
  final bool sending;
  final TextEditingController controller;
  final VoidCallback onMicOrType;
  final VoidCallback onSend;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _CookingBottomArea({
    required this.isFirst,
    required this.isLast,
    required this.showTextInput,
    required this.sending,
    required this.controller,
    required this.onMicOrType,
    required this.onSend,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkBg,
      padding: EdgeInsets.fromLTRB(20, 12, 20, 28 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Text input (shown when toggled or typing)
          if (showTextInput) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    style: AppTypography.body(15, color: AppColors.darkText),
                    decoration: InputDecoration(
                      hintText: 'Describe your substitution or note…',
                      hintStyle: AppTypography.body(15, color: AppColors.darkMuted),
                      filled: true,
                      fillColor: AppColors.darkSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.darkLine),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.darkLine),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.accent),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: sending ? null : onSend,
                  icon: sending
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                        )
                      : const Icon(Icons.send, color: AppColors.accent),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Row: "Type instead" pill + mic
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // "Type instead" pill
              GestureDetector(
                onTap: onMicOrType,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.darkLine),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    showTextInput ? 'Hide input' : 'Type instead',
                    style: AppTypography.body(15, color: AppColors.darkText),
                  ),
                ),
              ),
              // Mic button (72 px round, accent fill)
              GestureDetector(
                onTap: onMicOrType,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic, color: AppColors.ink, size: 28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Nav row: Back + Next step
          Row(
            children: [
              SizedBox(
                width: 104,
                height: 60,
                child: OutlinedButton(
                  onPressed: isFirst ? null : onBack,
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    side: BorderSide(
                      color: isFirst ? AppColors.darkLine : AppColors.darkMuted,
                    ),
                    foregroundColor: AppColors.darkText,
                  ),
                  child: Text('Back',
                      style: AppTypography.body(16, color: isFirst ? AppColors.darkMuted : AppColors.darkText)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkText,  // #F4F6F3
                      foregroundColor: AppColors.darkBg,    // #16201B
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    child: Text(
                      isLast ? 'Finish cooking' : 'Next step',
                      style: AppTypography.body(18,
                          weight: FontWeight.w700, color: AppColors.darkBg),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared: accent pill button ────────────────────────────────────────────────

class _AccentPill extends StatelessWidget {
  final double height;
  final String label;
  final double fontSize;
  final VoidCallback? onTap;

  const _AccentPill({
    required this.height,
    required this.label,
    required this.fontSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(color: AppColors.accentEdge),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: AppTypography.body(fontSize,
                weight: FontWeight.w700, color: AppColors.ink)),
      ),
    );
  }
}
