import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/favorite_controller.dart';
import '../../models/business_model.dart';
import '../../repositories/favorite_repository.dart';

enum _FavoriteViewMode { list, grid }

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  static const routeName = '/favorites';

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late final FavoriteController _favoriteController;
  _FavoriteViewMode _viewMode = _FavoriteViewMode.list;

  @override
  void initState() {
    super.initState();
    _favoriteController = FavoriteController(FavoriteRepository());
    _favoriteController.addListener(_onFavoritesChanged);
    unawaited(_favoriteController.loadFavorites());
  }

  @override
  void dispose() {
    _favoriteController
      ..removeListener(_onFavoritesChanged)
      ..dispose();
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _removeFavorite(BusinessModel business) async {
    await _favoriteController.removeFavorite(business.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${business.name} retire des favoris.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = _favoriteController.favorites;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoris'),
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
        onRefresh: _favoriteController.refresh,
        child: _favoriteController.isLoading
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
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
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
          child:
              _FavoriteGridCard(
                    business: business,
                    onRemove: () => onRemove(business),
                  )
                  .animate()
                  .fadeIn(duration: 260.ms)
                  .scale(
                    begin: const Offset(0.96, 0.96),
                    end: const Offset(1, 1),
                  ),
        );
      },
    );
  }
}

class _FavoriteListCard extends StatelessWidget {
  const _FavoriteListCard({required this.business, required this.onRemove});

  final BusinessModel business;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => context.go('/home/business/${business.id}'),
        child: Row(
          children: [
            Hero(
              tag: 'business-cover-${business.id}',
              child: Image.network(
                business.imageUrl,
                width: 112,
                height: 118,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      business.categoryName,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _RatingLine(business: business),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: 'Retirer des favoris',
              onPressed: onRemove,
              icon: const Icon(Icons.favorite_rounded),
              color: colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteGridCard extends StatelessWidget {
  const _FavoriteGridCard({required this.business, required this.onRemove});

  final BusinessModel business;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => context.go('/business/${business.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'business-cover-${business.id}',
                    child: Image.network(business.imageUrl, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: IconButton.filledTonal(
                      tooltip: 'Retirer des favoris',
                      onPressed: onRemove,
                      icon: const Icon(Icons.favorite_rounded),
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
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    business.categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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
        Icon(Icons.star_rounded, color: colorScheme.tertiary, size: 19),
        const SizedBox(width: 3),
        Text(
          business.rating.toStringAsFixed(1),
          style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${business.reviewCount} avis',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
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
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.delete_rounded, color: colorScheme.onErrorContainer),
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
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 96),
        Container(
          width: 118,
          height: 118,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.favorite_border_rounded,
            size: 56,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Aucun favori',
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Gardez vos lieux preferes a portee de main en les ajoutant a vos favoris.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: FilledButton.icon(
            onPressed: () => context.go('/search'),
            icon: const Icon(Icons.explore_rounded),
            label: const Text('Explorer'),
          ),
        ),
      ],
    );
  }
}

class _FavoritesLoading extends StatelessWidget {
  const _FavoritesLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
