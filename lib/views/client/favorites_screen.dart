import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/favorite_providers.dart';
import '../../models/business_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _FavoriteViewMode { list, grid }

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  static const routeName = '/favorites';

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  _FavoriteViewMode _viewMode = _FavoriteViewMode.list;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(favoriteControllerProvider).loadFavorites();
      }
    });
  }

  Future<void> _removeFavorite(BusinessModel business) async {
    try {
      await ref.read(favoriteControllerProvider).removeFavorite(business.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${business.name} retiré des favoris.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final favoriteController = ref.watch(favoriteControllerProvider);
    final favorites = favoriteController.favorites;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mes Favoris'),
            if (favorites.isNotEmpty)
              Text(
                '${favorites.length} établissement${favorites.length > 1 ? 's' : ''}',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SegmentedButton<_FavoriteViewMode>(
              selected: {_viewMode},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                setState(() => _viewMode = selection.first);
              },
              segments: const [
                ButtonSegment(
                  value: _FavoriteViewMode.list,
                  icon: Icon(Icons.view_list_rounded),
                ),
                ButtonSegment(
                  value: _FavoriteViewMode.grid,
                  icon: Icon(Icons.grid_view_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: favoriteController.refresh,
        child: favoriteController.isLoading
            ? const _FavoritesLoading()
            : favorites.isEmpty
            ? const _EmptyFavoritesState()
            : _viewMode == _FavoriteViewMode.list
            ? _FavoritesList(favorites: favorites, onRemove: _removeFavorite)
            : _FavoritesGrid(favorites: favorites, onRemove: _removeFavorite),
      ),
    );
  }
}

class _FavoritesList extends StatelessWidget {
  const _FavoritesList({required this.favorites, required this.onRemove});

  final List<BusinessModel> favorites;
  final ValueChanged<BusinessModel> onRemove;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: favorites.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final business = favorites[index];

        return Dismissible(
          key: ValueKey(business.id),
          direction: DismissDirection.endToStart,
          background: const _DismissBackground(),
          onDismissed: (_) => onRemove(business),
          child: _FavoriteListCard(
            business: business,
            onRemove: () => onRemove(business),
          ).animate().fadeIn(duration: 260.ms).slideX(begin: 0.04),
        );
      },
    );
  }
}

class _FavoritesGrid extends StatelessWidget {
  const _FavoritesGrid({required this.favorites, required this.onRemove});

  final List<BusinessModel> favorites;
  final ValueChanged<BusinessModel> onRemove;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final business = favorites[index];

        return Dismissible(
          key: ValueKey('grid-${business.id}'),
          direction: DismissDirection.up,
          background: const _DismissBackground(),
          onDismissed: (_) => onRemove(business),
          child: _FavoriteGridCard(
                business: business,
                onRemove: () => onRemove(business),
              )
              .animate()
              .fadeIn(duration: 260.ms)
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1, 1),
              ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// List card
// ─────────────────────────────────────────────────────────────────────────────

class _FavoriteListCard extends StatelessWidget {
  const _FavoriteListCard({required this.business, required this.onRemove});

  final BusinessModel business;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.go('/home/business/${business.id}'),
            child: Row(
              children: [
                // Image
                Hero(
                  tag: 'business-cover-${business.id}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                    child: Image.network(
                      business.imageUrl,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 110,
                        height: 110,
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.storefront_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),

                // Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          business.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 11,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                business.categoryName,
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _RatingLine(business: business),
                      ],
                    ),
                  ),
                ),

                // Remove btn
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: IconButton(
                    tooltip: 'Retirer des favoris',
                    onPressed: onRemove,
                    icon: const Icon(Icons.favorite_rounded),
                    color: colorScheme.error,
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.errorContainer.withValues(
                        alpha: 0.3,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grid card
// ─────────────────────────────────────────────────────────────────────────────

class _FavoriteGridCard extends StatelessWidget {
  const _FavoriteGridCard({required this.business, required this.onRemove});

  final BusinessModel business;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: colorScheme.surface,
          child: InkWell(
            onTap: () => context.go('/home/business/${business.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'business-cover-${business.id}',
                        child: Image.network(
                          business.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.storefront_rounded,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      // Gradient overlay
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.5, 1.0],
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.25),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: GestureDetector(
                          onTap: onRemove,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.favorite_rounded,
                              color: colorScheme.error,
                              size: 17,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        business.categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _RatingLine(business: business),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RatingLine extends StatelessWidget {
  const _RatingLine({required this.business});

  final BusinessModel business;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(Icons.star_rounded, color: const Color(0xFFFFC107), size: 15),
        const SizedBox(width: 3),
        Text(
          business.rating.toStringAsFixed(1),
          style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            '${business.reviewCount} avis',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.heart_broken_rounded, color: colorScheme.onErrorContainer),
          const SizedBox(height: 4),
          Text(
            'Retirer',
            style: TextStyle(
              color: colorScheme.onErrorContainer,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFavoritesState extends StatelessWidget {
  const _EmptyFavoritesState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_border_rounded,
                  size: 48,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ).animate().scale(
            begin: const Offset(0.7, 0.7),
            end: const Offset(1, 1),
            duration: 500.ms,
            curve: Curves.easeOutBack,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Aucun favori',
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ).animate(delay: 150.ms).fadeIn(duration: 400.ms),
        const SizedBox(height: 10),
        Text(
          'Gardez vos lieux préférés à portée de main en les ajoutant à vos favoris.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ).animate(delay: 220.ms).fadeIn(duration: 400.ms),
        const SizedBox(height: 28),
        Center(
          child: FilledButton.icon(
            onPressed: () => context.go('/search'),
            icon: const Icon(Icons.explore_rounded),
            label: const Text('Explorer'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
        ),
      ],
    );
  }
}

class _FavoritesLoading extends StatelessWidget {
  const _FavoritesLoading();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
              height: 110,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fade(begin: 0.4, end: 1, duration: 800.ms);
      },
    );
  }
}
