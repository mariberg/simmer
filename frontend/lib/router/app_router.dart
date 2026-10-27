import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/recipe.dart';
import '../models/session.dart';
import '../screens/recipes_screen.dart';
import '../screens/recipe_detail_screen.dart';
import '../screens/add_recipe_screen.dart';
import '../screens/cooking_screen.dart';
import '../screens/finish_rate_screen.dart';
import '../screens/ask_screen.dart';
import '../theme/app_theme.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => _TabShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: RecipesScreen()),
        ),
        GoRoute(
          path: '/ask',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: AskScreen()),
        ),
      ],
    ),
    GoRoute(
      path: '/recipes/add',
      builder: (context, state) => const AddRecipeScreen(),
    ),
    GoRoute(
      path: '/recipes/:id',
      builder: (context, state) =>
          RecipeDetailScreen(recipeId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/cook/:recipeId',
      builder: (context, state) {
        final recipe = state.extra as Recipe?;
        return CookingScreen(
          recipeId: state.pathParameters['recipeId']!,
          recipe: recipe,
        );
      },
    ),
    GoRoute(
      path: '/finish/:sessionId',
      builder: (context, state) {
        final session = state.extra as CookingSession?;
        return FinishRateScreen(
          sessionId: state.pathParameters['sessionId']!,
          session: session,
        );
      },
    ),
  ],
);

/// Shell with the two-tab bottom bar (Recipes + Ask).
class _TabShell extends StatelessWidget {
  final Widget child;
  const _TabShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = location.startsWith('/ask') ? 1 : 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: child,
      bottomNavigationBar: _SimmerTabBar(selectedIndex: selectedIndex),
    );
  }
}

class _SimmerTabBar extends StatelessWidget {
  final int selectedIndex;
  const _SimmerTabBar({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76 + MediaQuery.of(context).padding.bottom,
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'Recipes',
            icon: Icons.menu_book_outlined,
            activeIcon: Icons.menu_book,
            isActive: selectedIndex == 0,
            onTap: () => context.go('/'),
          ),
          _Tab(
            label: 'Ask',
            icon: Icons.auto_awesome_outlined,
            activeIcon: Icons.auto_awesome,
            isActive: selectedIndex == 1,
            onTap: () => context.go('/ask'),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // 3 px green line at the top when active
            Container(
              height: 3,
              color: isActive ? AppColors.green : Colors.transparent,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isActive ? activeIcon : icon,
                    color: isActive ? AppColors.green : AppColors.muted,
                    size: 22,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: AppTypography.body(
                      15,
                      weight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? AppColors.green : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
