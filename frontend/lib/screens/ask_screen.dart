import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/page_shell.dart';

class AskScreen extends StatefulWidget {
  const AskScreen({super.key});

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<AskTurn> _history = [];
  final List<_ChatMessage> _messages = [];
  bool _thinking = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _ask([String? preset]) async {
    final text = preset ?? _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    setState(() {
      _messages.add(_ChatMessage(role: 'user', text: text));
      _history.add(AskTurn(role: 'user', text: text));
      _thinking = true;
    });
    _scrollToBottom();

    try {
      final res = await ApiService().ask(text, List.from(_history));
      setState(() {
        _messages.add(_ChatMessage(
          role: 'assistant',
          text: res.answer,
          sources: res.sources,
        ));
        _history.add(AskTurn(role: 'assistant', text: res.answer));
        _thinking = false;
      });
      _scrollToBottom();
    } catch (_) {
      setState(() {
        _messages.add(const _ChatMessage(
          role: 'assistant',
          text: 'Something went wrong. Try again.',
          isError: true,
        ));
        _thinking = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                child: Text('Ask', style: AppTypography.display(30)),
              ),

              // Chat area
              Expanded(
                child: _messages.isEmpty
                    ? _EmptyState(onSuggestion: _ask)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        itemCount: _messages.length + (_thinking ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (_thinking && i == _messages.length) {
                            return const _ThinkingBubble();
                          }
                          return _BubbleRow(message: _messages[i]);
                        },
                      ),
              ),

              // Input bar
              _InputBar(
                controller: _controller,
                thinking: _thinking,
                onSend: () => _ask(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final void Function(String) onSuggestion;
  const _EmptyState({required this.onSuggestion});

  static const _suggestions = [
    'Have I used dried basil in lasagne before?',
    'What swaps worked well last time?',
    "What's my best-rated cook?",
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ask about your cooking history, substitutions, or what worked before.',
            style: AppTypography.body(16, color: AppColors.muted, height: 1.5),
          ),
          const SizedBox(height: 20),
          ..._suggestions.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => onSuggestion(s),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: Text(s, style: AppTypography.body(15)),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

// ── Chat bubbles ──────────────────────────────────────────────────────────────

class _BubbleRow extends StatelessWidget {
  final _ChatMessage message;
  const _BubbleRow({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: isUser ? 300 : 320,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser ? AppColors.green : AppColors.card,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isUser
                    ? const Radius.circular(16)
                    : const Radius.circular(4),
                bottomRight: isUser
                    ? const Radius.circular(4)
                    : const Radius.circular(16),
              ),
              border: isUser ? null : Border.all(color: AppColors.line),
            ),
            child: Text(
              message.text,
              style: AppTypography.body(
                16,
                color: isUser ? Colors.white : AppColors.ink,
                height: 1.45,
              ),
            ),
          ),

          // Source cards
          if (message.sources != null && message.sources!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('FROM YOUR HISTORY',
                style: AppTypography.smallCaps()),
            const SizedBox(height: 6),
            ...message.sources!.map((s) => _SourceCard(source: s)),
          ],
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  final AskSource source;
  const _SourceCard({required this.source});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d').format(source.date.toLocal());
    return GestureDetector(
      onTap: () => context.push('/recipes/${source.recipeId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${source.recipeTitle} v${source.versionNumber} · $dateStr'
              '${source.rating != null ? ' · ★ ${source.rating}' : ''}',
              style: AppTypography.body(14, weight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(source.summary,
                style: AppTypography.body(14, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: AppColors.line),
        ),
        child: const _DotLoader(),
      ),
    );
  }
}

class _DotLoader extends StatefulWidget {
  const _DotLoader();
  @override
  State<_DotLoader> createState() => _DotLoaderState();
}

class _DotLoaderState extends State<_DotLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 14,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (i) {
            final offset = ((_ctrl.value * 3 - i) % 3).clamp(0.0, 1.0);
            final scale = 0.55 +
                0.45 *
                    (1 - (offset - 0.5).abs() * 2).clamp(0.0, 1.0);
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.muted,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool thinking;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.thinking,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20, 10, 20, 10 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          // Text field: 52 high, radius 26, pill shaped
          Expanded(
            child: SizedBox(
              height: 52,
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Ask about your cooking…',
                  hintStyle: AppTypography.body(15, color: AppColors.muted),
                  filled: true,
                  fillColor: AppColors.card,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: const BorderSide(color: AppColors.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: const BorderSide(color: AppColors.green, width: 1.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Round accent mic button, 52 px
          GestureDetector(
            onTap: thinking ? null : onSend,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: thinking ? AppColors.line : AppColors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accentEdge),
              ),
              child: thinking
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.green),
                    )
                  : const Icon(Icons.mic, color: AppColors.ink, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String role;
  final String text;
  final List<AskSource>? sources;
  final bool isError;

  const _ChatMessage({
    required this.role,
    required this.text,
    this.sources,
    this.isError = false,
  });
}
