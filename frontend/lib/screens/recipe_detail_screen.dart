import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/recipe.dart';
import '../models/version.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/page_shell.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;
  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  late Future<(Recipe, List<RecipeVersion>)> _future;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  void _load() {
    _future = Future.wait([
      ApiService().getRecipe(widget.recipeId),
      ApiService().getVersions(widget.recipeId),
    ]).then((r) => (r[0] as Recipe, r[1] as List<RecipeVersion>));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(Recipe, List<RecipeVersion>)>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.bg,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || snap.data == null) {
          return Scaffold(
            backgroundColor: AppColors.bg,
            appBar: AppBar(),
            body: Center(child: Text(snap.error?.toString() ?? 'Error')),
          );
        }
        final (recipe, versions) = snap.data!;
        return _DetailView(recipe: recipe, versions: versions, tabs: _tabs);
      },
    );
  }
}

class _DetailView extends StatelessWidget {
  final Recipe recipe;
  final List<RecipeVersion> versions;
  final TabController tabs;
  const _DetailView({required this.recipe, required this.versions, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return PageShell(
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              pinned: true,
              expandedHeight: 120,
              backgroundColor: AppColors.bg,
              foregroundColor: AppColors.ink,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.fromLTRB(20, 0, 16, 52),
                title: Text(recipe.title, style: AppTypography.heading(20)),
                background: Container(color: AppColors.bg),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(44),
                child: TabBar(
                  controller: tabs,
                  indicatorColor: AppColors.green,
                  labelColor: AppColors.green,
                  unselectedLabelColor: AppColors.muted,
                  labelStyle: AppTypography.body(15, weight: FontWeight.w700),
                  unselectedLabelStyle: AppTypography.body(15, weight: FontWeight.w500),
                  tabs: const [
                    Tab(text: 'Recipe'),
                    Tab(text: 'Ingredients'),
                    Tab(text: 'Versions'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: tabs,
            children: [
              _StepsTab(recipe: recipe),
              _IngredientsTab(recipe: recipe),
              _VersionsTab(versions: versions),
            ],
          ),
        ),
        // "Start cooking" as a large accent button
        bottomNavigationBar: _StartCookingBar(recipe: recipe),
      ),
    );
  }
}

// ── Start cooking bar ─────────────────────────────────────────────────────────

class _StartCookingBar extends StatelessWidget {
  final Recipe recipe;
  const _StartCookingBar({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
      child: SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: () => context.push('/cook/${recipe.id}', extra: recipe),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.ink,
            shape: const StadiumBorder(
              side: BorderSide(color: AppColors.accentEdge),
            ),
            elevation: 0,
          ),
          child: Text(
            'Start cooking',
            style: AppTypography.body(17, weight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

// ── Steps tab ────────────────────────────────────────────────────────────────

class _StepsTab extends StatelessWidget {
  final Recipe recipe;
  const _StepsTab({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      itemCount: recipe.steps.length,
      itemBuilder: (context, i) {
        final step = recipe.steps[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step number circle
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${i + 1}',
                  style: AppTypography.body(13,
                      weight: FontWeight.w700, color: AppColors.green),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.text,
                        style: AppTypography.body(16, height: 1.6)),
                    if (step.timerSeconds != null) ...[
                      const SizedBox(height: 6),
                      _TimerLabel(seconds: step.timerSeconds!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimerLabel extends StatelessWidget {
  final int seconds;
  const _TimerLabel({required this.seconds});

  String get _label {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s == 0 ? '$m min' : '$m min ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer_outlined, size: 13, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(_label, style: AppTypography.body(13, color: AppColors.muted)),
      ],
    );
  }
}

// ── Ingredients tab ───────────────────────────────────────────────────────────

class _IngredientsTab extends StatelessWidget {
  final Recipe recipe;
  const _IngredientsTab({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      itemCount: recipe.ingredients.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.line),
      itemBuilder: (context, i) {
        final ing = recipe.ingredients[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 12, top: 1),
                decoration: const BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(ing.name, style: AppTypography.body(16)),
              ),
              Text(
                [if (ing.quantity != null) ing.quantity!, if (ing.unit != null) ing.unit!].join(' '),
                style: AppTypography.body(14, color: AppColors.muted),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Versions tab ──────────────────────────────────────────────────────────────

class _VersionsTab extends StatelessWidget {
  final List<RecipeVersion> versions;
  const _VersionsTab({required this.versions});

  @override
  Widget build(BuildContext context) {
    if (versions.isEmpty) {
      return Center(
        child: Text('No versions yet',
            style: AppTypography.body(15, color: AppColors.muted)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      itemCount: versions.length,
      itemBuilder: (_, i) => _VersionRow(version: versions[i]),
    );
  }
}

class _VersionRow extends StatelessWidget {
  final RecipeVersion version;
  const _VersionRow({required this.version});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d').format(version.createdAt.toLocal());
    final swapSummary = version.substitutions.isNotEmpty
        ? version.substitutions
            .map((s) => '${s.replacement} for ${s.original}')
            .join(', ')
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // v3 · Oct 23 · ★ 4
          Row(
            children: [
              Text(
                version.isOriginal ? 'Original' : 'v${version.number}',
                style: AppTypography.body(14, weight: FontWeight.w700),
              ),
              Text(' · $dateStr',
                  style: AppTypography.body(14, color: AppColors.muted)),
              if (version.rating != null) ...[
                Text(' · ',
                    style: AppTypography.body(14, color: AppColors.muted)),
                const Text('★',
                    style: TextStyle(color: AppColors.green, fontSize: 14)),
                Text(' ${version.rating}',
                    style: AppTypography.body(14,
                        weight: FontWeight.w700, color: AppColors.green)),
              ],
            ],
          ),
          if (swapSummary != null) ...[
            const SizedBox(height: 4),
            Text(swapSummary,
                style: AppTypography.body(14, color: AppColors.muted)),
          ],
          if (version.note != null && version.note!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(version.note!,
                style: AppTypography.body(14,
                    color: AppColors.muted,
                    height: 1.4)
                    .copyWith(fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}
