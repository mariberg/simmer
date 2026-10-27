import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/recipe.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/page_shell.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  late Future<List<Recipe>> _future;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = ApiService().listRecipes();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() => _future = ApiService().listRecipes());

  List<Recipe> _filter(List<Recipe> all) {
    if (_query.isEmpty) return all;
    return all
        .where((r) => r.title.toLowerCase().contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: FutureBuilder<List<Recipe>>(
          future: _future,
          builder: (context, snapshot) {
            final recipes = _filter(snapshot.data ?? []);
            final loading = snapshot.connectionState == ConnectionState.waiting;

            return Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        56 + MediaQuery.of(context).padding.top,
                        20,
                        // space for FAB + tab bar
                        120,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Title + subtitle
                          Text('Simmer', style: AppTypography.display(30)),
                          const SizedBox(height: 4),
                          Text(
                            'Recipes, to taste.',
                            style: AppTypography.body(15, color: AppColors.muted),
                          ),
                          const SizedBox(height: 20),

                          // Search field
                          SizedBox(
                            height: 48,
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search your recipes',
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: AppColors.muted,
                                  size: 20,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.line),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.line),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.green, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Recipe list
                          if (loading)
                            const Padding(
                              padding: EdgeInsets.only(top: 60),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (snapshot.hasError)
                            _ErrorView(
                              message: snapshot.error.toString(),
                              onRetry: _refresh,
                            )
                          else if (recipes.isEmpty && _query.isEmpty)
                            _EmptyView(
                              onAdd: () async {
                                await context.push('/recipes/add');
                                _refresh();
                              },
                            )
                          else if (recipes.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Center(
                                child: Text(
                                  'No recipes match "$_query"',
                                  style: AppTypography.body(15, color: AppColors.muted),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: recipes.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (_, i) => _RecipeCard(recipe: recipes[i]),
                            ),
                        ]),
                      ),
                    ),
                  ],
                ),

                // Floating "+ Add recipe" button
                Positioned(
                  right: 20,
                  bottom: 92,
                  child: _AddRecipeButton(
                    onTap: () async {
                      await context.push('/recipes/add');
                      _refresh();
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Recipe card ───────────────────────────────────────────────────────────────

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/recipes/${recipe.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: title + rating
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    recipe.title,
                    style: AppTypography.heading(20),
                  ),
                ),
                if (recipe.avgRating != null) ...[
                  const SizedBox(width: 8),
                  _RatingBadge(rating: recipe.avgRating!),
                ],
              ],
            ),
            const SizedBox(height: 6),

            // Row 2: versions · last cooked
            Text(
              _meta(),
              style: AppTypography.body(14, color: AppColors.muted),
            ),
            const SizedBox(height: 6),

            // Row 3: latest swap or "Original recipe"
            Text(
              recipe.latestSwap != null
                  ? 'Latest swap: ${recipe.latestSwap}'
                  : 'Original recipe',
              style: AppTypography.body(14),
            ),
          ],
        ),
      ),
    );
  }

  String _meta() {
    final versionStr =
        '${recipe.versionCount} version${recipe.versionCount == 1 ? '' : 's'}';
    if (recipe.lastCookedAt == null) return versionStr;
    final formatted = _formatDate(recipe.lastCookedAt!);
    return '$versionStr · last cooked $formatted';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'yesterday';
    return DateFormat('MMM d').format(dt.toLocal());
  }
}

class _RatingBadge extends StatelessWidget {
  final double rating;
  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('★', style: TextStyle(color: AppColors.green, fontSize: 15)),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: AppTypography.body(15,
              weight: FontWeight.w700, color: AppColors.green),
        ),
      ],
    );
  }
}

// ── Floating add button ───────────────────────────────────────────────────────

class _AddRecipeButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddRecipeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.accentEdge),
        ),
        alignment: Alignment.center,
        child: Text(
          '+ Add recipe',
          style: AppTypography.body(16,
              weight: FontWeight.w700, color: AppColors.ink),
        ),
      ),
    );
  }
}

// ── Empty / error states ──────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyView({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Text('No recipes yet',
              style: AppTypography.heading(20), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Tap "+ Add recipe" to paste one in.',
            style: AppTypography.body(15, color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 40),
          const SizedBox(height: 12),
          Text('Something went wrong', style: AppTypography.heading(18)),
          const SizedBox(height: 8),
          Text(message,
              style: AppTypography.body(14, color: AppColors.muted),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
