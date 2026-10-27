import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/session.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/page_shell.dart';

class FinishRateScreen extends StatefulWidget {
  final String sessionId;
  final CookingSession? session;
  const FinishRateScreen({super.key, required this.sessionId, this.session});

  @override
  State<FinishRateScreen> createState() => _FinishRateScreenState();
}

class _FinishRateScreenState extends State<FinishRateScreen> {
  int _rating = 0;
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // Figure out what version number this will be (existing + 1).
  String get _versionLabel {
    // The session has the recipeId but not the count — we use a placeholder.
    return 'version ?';
  }

  Future<void> _save() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a star rating first.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final result = await ApiService().finishSession(
        widget.sessionId,
        rating: _rating,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      if (mounted) {
        context.go('/recipes/${result.recipe.id}');
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final confirmed = widget.session?.confirmedEvents ?? [];
    final recipeTitle = ''; // We don't have the title here without a lookup.

    return PageShell(
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Small line + title
              Text(
                recipeTitle.isNotEmpty ? '$recipeTitle · $_versionLabel' : 'New version',
                style: AppTypography.body(15, color: AppColors.muted),
              ),
              const SizedBox(height: 6),
              Text('How did it turn out?', style: AppTypography.display(30)),
              const SizedBox(height: 24),

              // "What you changed" card
              _ChangesCard(events: confirmed),
              const SizedBox(height: 24),

              // Star rating
              Text('Rating', style: AppTypography.body(15, weight: FontWeight.w600)),
              const SizedBox(height: 12),
              _StarPicker(
                rating: _rating,
                onChanged: (r) => setState(() => _rating = r),
              ),
              const SizedBox(height: 24),

              // Notes
              Text('Notes', style: AppTypography.body(15, weight: FontWeight.w600)),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: TextField(
                  controller: _noteController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: 'What worked? What would you change next time?',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.mic, size: 18),
                label: const Text('Add note by voice'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.green),
                  foregroundColor: AppColors.green,
                ),
              ),

              const SizedBox(height: 32),

              // Save button (pinned-style at bottom of scroll)
              _SaveButton(saving: _saving, onSave: _save),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/'),
                child: Text('Skip', style: AppTypography.body(15, color: AppColors.muted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── What you changed card ─────────────────────────────────────────────────────

class _ChangesCard extends StatelessWidget {
  final List<CookingEvent> events;
  const _ChangesCard({required this.events});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WHAT YOU CHANGED', style: AppTypography.smallCaps()),
          const SizedBox(height: 10),
          if (events.isEmpty)
            Text('No changes. Cooked as written.',
                style: AppTypography.body(17))
          else
            ...events.map((e) {
              final parsed = e.parsed;
              final label = parsed != null
                  ? '${parsed.original} → ${parsed.replacement}${parsed.quantity != null ? ' · ${parsed.quantity}' : ''}'
                  : e.rawText;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(label, style: AppTypography.body(17)),
              );
            }),
        ],
      ),
    );
  }
}

// ── Star picker ───────────────────────────────────────────────────────────────

class _StarPicker extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;
  const _StarPicker({required this.rating, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(5, (i) {
        final filled = i < rating;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () => onChanged(i + 1),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 40,
              color: AppColors.green,
            ),
          ),
        );
      }),
    );
  }
}

// ── Save button ───────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final bool saving;
  final VoidCallback onSave;
  const _SaveButton({required this.saving, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: saving ? null : onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.ink,
          shape: const StadiumBorder(
            side: BorderSide(color: AppColors.accentEdge),
          ),
          elevation: 0,
        ),
        child: saving
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.ink),
                  ),
                  const SizedBox(width: 10),
                  Text('Saving…',
                      style: AppTypography.body(17, weight: FontWeight.w700)),
                ],
              )
            : Text('Save as version',
                style: AppTypography.body(17, weight: FontWeight.w700)),
      ),
    );
  }
}
