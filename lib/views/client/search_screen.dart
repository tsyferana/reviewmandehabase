import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';

import '../../models/business_model.dart';
import '../../models/category_model.dart';
import '../../services/location_sim_service.dart';
import '../../services/maps_sim_service.dart';
import '../../services/supabase_data_service.dart';

enum _SearchViewMode { list, map }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  static const routeName = '/search';

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _pageSize = 5;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _dataService = SupabaseDataService();
  final _locationService = LocationSimService();
  final _mapsService = MapsSimService();

  List<CategoryModel> _categories = [];
  List<BusinessModel> _businesses = [];
  List<BusinessModel> _visibleResults = [];

  String? _selectedCategoryId;
  String _selectedCity = 'Antananarivo';
  double _minimumRating = 0;
  double _maximumDistance = 10;
  bool _openNow = false;
  bool _isLoading = true;
  bool _isLocating = false;
  int _loadedCount = _pageSize;
  _SearchViewMode _viewMode = _SearchViewMode.list;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
    _scrollController.addListener(_handleScroll);
    unawaited(_loadSearchData());
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_applyFilters)
      ..dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadSearchData() async {
    final results = await Future.wait([
      _dataService.getCategories(),
      _dataService.getBusinesses(),
    ]);

    if (!mounted) return;

    setState(() {
      _categories = results[0] as List<CategoryModel>;
      _businesses = results[1] as List<BusinessModel>;
      _isLoading = false;
    });
    _applyFilters();
  }

  Future<void> _locateAroundMe() async {
    setState(() => _isLocating = true);
    final location = await _locationService.getCurrentLocation();

    if (!mounted) return;

    setState(() {
      _selectedCity = location.city;
      _maximumDistance = 5;
      _loadedCount = _pageSize;
      _isLocating = false;
    });
    _applyFilters();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Recherche autour de ${location.city}.')),
    );
  }

  void _handleScroll() {
    if (_scrollController.position.extentAfter > 220) {
      return;
    }

    if (_loadedCount >= _filteredResults.length) {
      return;
    }

    setState(() {
      _loadedCount += _pageSize;
      _visibleResults = _filteredResults.take(_loadedCount).toList();
    });
  }

  List<BusinessModel> get _filteredResults {
    final query = _searchController.text.trim().toLowerCase();

    final results = _businesses.where((business) {
      final matchesQuery =
          query.isEmpty ||
          business.name.toLowerCase().contains(query) ||
          business.categoryName.toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategoryId == null ||
          business.categoryId == _selectedCategoryId;
      final matchesCity = business.city == _selectedCity;
      final matchesRating = business.rating >= _minimumRating;
      final matchesDistance = business.distanceKm <= _maximumDistance;
      final matchesOpenStatus = !_openNow || business.isOpen;

      return matchesQuery &&
          matchesCategory &&
          matchesCity &&
          matchesRating &&
          matchesDistance &&
          matchesOpenStatus;
    }).toList()..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return results;
  }

  void _applyFilters() {
    if (!mounted) return;

    setState(() {
      _loadedCount = _pageSize;
      _visibleResults = _filteredResults.take(_loadedCount).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredResults = _filteredResults;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _SearchField(controller: _searchController),
      ),
      body: Column(
        children: [
          _FiltersBar(
            categories: _categories,
            selectedCategoryId: _selectedCategoryId,
            selectedCity: _selectedCity,
            minimumRating: _minimumRating,
            maximumDistance: _maximumDistance,
            openNow: _openNow,
            isLocating: _isLocating,
            onCategoryChanged: (value) {
              setState(() => _selectedCategoryId = value);
              _applyFilters();
            },
            onMinimumRatingChanged: (value) {
              setState(() => _minimumRating = value);
              _applyFilters();
            },
            onMaximumDistanceChanged: (value) {
              setState(() => _maximumDistance = value);
              _applyFilters();
            },
            onOpenNowChanged: (value) {
              setState(() => _openNow = value);
              _applyFilters();
            },
            onAroundMe: _locateAroundMe,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${filteredResults.length} resultats',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SegmentedButton<_SearchViewMode>(
                  segments: const [
                    ButtonSegment(
                      value: _SearchViewMode.list,
                      icon: Icon(Icons.view_list_rounded),
                      label: Text('Liste'),
                    ),
                    ButtonSegment(
                      value: _SearchViewMode.map,
                      icon: Icon(Icons.map_rounded),
                      label: Text('Carte'),
                    ),
                  ],
                  selected: {_viewMode},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) {
                    setState(() => _viewMode = selection.first);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const _SearchLoading()
                : filteredResults.isEmpty
                ? const _EmptySearchState()
                : _viewMode == _SearchViewMode.map
                ? _BusinessMap(
                    businesses: filteredResults,
                    mapsService: _mapsService,
                  )
                : _ResultsList(
                    scrollController: _scrollController,
                    results: _visibleResults,
                    hasMore: _visibleResults.length < filteredResults.length,
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: TextField(
        controller: controller,
        autofocus: true,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Rechercher un service',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Effacer',
                  onPressed: controller.clear,
                  icon: const Icon(Icons.close_rounded),
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          filled: true,
        ),
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.categories,
    required this.selectedCategoryId,
    required this.selectedCity,
    required this.minimumRating,
    required this.maximumDistance,
    required this.openNow,
    required this.isLocating,
    required this.onCategoryChanged,
    required this.onMinimumRatingChanged,
    required this.onMaximumDistanceChanged,
    required this.onOpenNowChanged,
    required this.onAroundMe,
  });

  final List<CategoryModel> categories;
  final String? selectedCategoryId;
  final String selectedCity;
  final double minimumRating;
  final double maximumDistance;
  final bool openNow;
  final bool isLocating;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<double> onMinimumRatingChanged;
  final ValueChanged<double> onMaximumDistanceChanged;
  final ValueChanged<bool> onOpenNowChanged;
  final VoidCallback onAroundMe;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          ActionChip(
            avatar: isLocating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
            label: const Text('Autour de moi'),
            onPressed: isLocating ? null : onAroundMe,
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String?>(
            tooltip: 'Categorie',
            onSelected: onCategoryChanged,
            itemBuilder: (context) {
              return [
                const PopupMenuItem<String?>(
                  child: Text('Toutes les categories'),
                ),
                ...categories.map(
                  (category) => PopupMenuItem<String?>(
                    value: category.id,
                    child: Text(category.name),
                  ),
                ),
              ];
            },
            child: _FilterChipShell(
              icon: Icons.category_outlined,
              label: selectedCategoryId == null
                  ? 'Categorie'
                  : categories
                        .firstWhere(
                          (category) => category.id == selectedCategoryId,
                        )
                        .name,
            ),
          ),
          const SizedBox(width: 8),
          _FilterChipShell(
            icon: Icons.location_city_rounded,
            label: selectedCity,
          ),
          const SizedBox(width: 8),
          PopupMenuButton<double>(
            tooltip: 'Note minimale',
            onSelected: onMinimumRatingChanged,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 0, child: Text('Toutes les notes')),
              PopupMenuItem(value: 4, child: Text('4.0+')),
              PopupMenuItem(value: 4.5, child: Text('4.5+')),
              PopupMenuItem(value: 4.8, child: Text('4.8+')),
            ],
            child: _FilterChipShell(
              icon: Icons.star_rounded,
              label: minimumRating == 0
                  ? 'Note'
                  : '${minimumRating.toStringAsFixed(1)}+',
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<double>(
            tooltip: 'Distance',
            onSelected: onMaximumDistanceChanged,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 2, child: Text('Moins de 2 km')),
              PopupMenuItem(value: 5, child: Text('Moins de 5 km')),
              PopupMenuItem(value: 10, child: Text('Moins de 10 km')),
            ],
            child: _FilterChipShell(
              icon: Icons.route_rounded,
              label: '< ${maximumDistance.toStringAsFixed(0)} km',
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            selected: openNow,
            label: const Text('Ouvert maintenant'),
            avatar: const Icon(Icons.schedule_rounded),
            onSelected: onOpenNowChanged,
          ),
        ],
      ),
    );
  }
}

class _FilterChipShell extends StatelessWidget {
  const _FilterChipShell({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon),
      label: Text(label),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({
    required this.scrollController,
    required this.results,
    required this.hasMore,
  });

  final ScrollController scrollController;
  final List<BusinessModel> results;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: results.length + (hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= results.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return _SearchResultCard(business: results[index]);
      },
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.business});

  final BusinessModel business;

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
              child: SizedBox(
                width: 112,
                height: 132,
                child: Image.network(
                  business.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return ColoredBox(
                      color: colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.storefront_rounded),
                    );
                  },
                ),
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
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: colorScheme.tertiary,
                          size: 19,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          business.rating.toStringAsFixed(1),
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${business.reviewCount} avis',
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          '${business.distanceKm.toStringAsFixed(1)} km',
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _OpenStatusPill(isOpen: business.isOpen),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenStatusPill extends StatelessWidget {
  const _OpenStatusPill({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isOpen
            ? colorScheme.primaryContainer
            : colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isOpen ? 'Ouvert' : 'Ferme',
        style: TextStyle(
          color: isOpen
              ? colorScheme.onPrimaryContainer
              : colorScheme.onErrorContainer,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _BusinessMap extends StatelessWidget {
  const _BusinessMap({required this.businesses, required this.mapsService});

  final List<BusinessModel> businesses;
  final MapsSimService mapsService;

  @override
  Widget build(BuildContext context) {
    final initialPosition = businesses.isEmpty
        ? MapsSimService.antananarivoCenter
        : LatLng(businesses.first.latitude, businesses.first.longitude);

    return FlutterMap(
      key: const ValueKey('search_results_map'),
      options: MapOptions(
        initialCenter: initialPosition,
        initialZoom: 13,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.reviewapp',
        ),
        MarkerLayer(
          markers: mapsService.buildBusinessMarkers(
            businesses,
            onTap: (business) => context.go('/home/business/${business.id}'),
          ),
        ),
      ],
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 54,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Aucun resultat',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez de modifier la categorie, la distance ou la note minimale.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchLoading extends StatelessWidget {
  const _SearchLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
