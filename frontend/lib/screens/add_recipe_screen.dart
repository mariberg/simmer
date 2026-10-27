import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/recipe.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/page_shell.dart';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _textController = TextEditingController();
  Recipe? _draft;
  bool _parsing = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _parse() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() { _parsing = true; _error = null; _draft = null; });
    try {
      final draft = await ApiService().parseRecipe(text);
      setState(() => _draft = draft);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _parsing = false);
    }
  }

  Future<void> _save() async {
    if (_draft == null) return;
    setState(() => _saving = true);
    try {
      await ApiService().saveRecipe(_draft!);
      if (mounted) context.pop();
    } on ApiException catch (e) {
      setState(() { _error = e.message; _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const Text('Add recipe'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Paste your recipe',
                  style: AppTypography.display(30)),
              const SizedBox(height: 8),
              Text(
                'Include the title, ingredients and steps.',
                style: AppTypography.body(15, color: AppColors.muted),
              ),
              const SizedBox(height: 20),

              // Big multiline paste field
              TextField(
                controller: _textController,
                maxLines: 14,
                minLines: 10,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText:
                      'Lasagne\n\n500g beef mince, 1 onion, fresh basil...\n\nStep 1: Brown the mince...',
                ),
                onChanged: (_) {
                  if (_draft != null) setState(() => _draft = null);
                },
              ),

              if (_error != null) ...[
                const SizedBox(height: 10),
                _ErrorBanner(message: _error!),
              ],

              const SizedBox(height: 16),

              if (_draft == null) ...[
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _parsing ? null : _parse,
                    child: _parsing
                        ? _spinner('Parsing…')
                        : Text('Parse',
                            style: AppTypography.body(16,
                                weight: FontWeight.w700)),
                  ),
                ),
              ] else ...[
                _DraftPreview(draft: _draft!),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => setState(() => _draft = null),
                          child: const Text('Edit text'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? _spinner('Saving…')
                              : Text('Save',
                                  style: AppTypography.body(16,
                                      weight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _spinner(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.ink),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppTypography.body(16, weight: FontWeight.w700)),
      ],
    );
  }
}

// ── Draft preview ─────────────────────────────────────────────────────────────

class _DraftPreview extends StatelessWidget {
  final Recipe draft;
  const _DraftPreview({required this.draft});

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
          Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: AppColors.green, size: 16),
              const SizedBox(width: 6),
              Text('Parsed — review before saving',
                  style: AppTypography.body(14,
                      weight: FontWeight.w600, color: AppColors.green)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: 12),
          Text(draft.title, style: AppTypography.heading(20)),
          const SizedBox(height: 6),
          Text(
            '${draft.ingredients.length} ingredients · ${draft.steps.length} steps',
            style: AppTypography.body(14, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          ...draft.ingredients.take(5).map((ing) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Container(
                  width: 5, height: 5,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(child: Text(ing.display,
                    style: AppTypography.body(14))),
              ],
            ),
          )),
          if (draft.ingredients.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+ ${draft.ingredients.length - 5} more',
                style: AppTypography.body(13, color: AppColors.muted),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Error banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: AppTypography.body(13, color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
