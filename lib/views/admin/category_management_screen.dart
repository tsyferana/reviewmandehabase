import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_router.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  static const routeName = '/admin/categories';

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen> {
  late List<_CategoryModel> _categories;

  static final List<IconData> _availableIcons = [
    Icons.restaurant_rounded,
    Icons.hotel_rounded,
    Icons.shopping_bag_rounded,
    Icons.spa_rounded,
    Icons.directions_car_rounded,
    Icons.fitness_center_rounded,
    Icons.local_bar_rounded,
    Icons.coffee_rounded,
    Icons.local_parking_rounded,
    Icons.build_rounded,
    Icons.school_rounded,
    Icons.local_hospital_rounded,
    Icons.local_florist_rounded,
    Icons.local_pizza_rounded,
    Icons.local_see_rounded,
    Icons.business_rounded,
    Icons.construction_rounded,
    Icons.cleaning_services_rounded,
    Icons.pets_rounded,
    Icons.sports_bar_rounded,
  ];

  static const List<Color> _availableColors = [
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFFFFE66D),
    Color(0xFF95E1D3),
    Color(0xFFC7CEEA),
    Color(0xFFFF8B94),
    Color(0xFFFFBF61),
    Color(0xFF6BCB77),
    Color(0xFF4D96FF),
    Color(0xFFBD69FF),
  ];

  @override
  void initState() {
    super.initState();
    _initializeMockCategories();
  }

  void _initializeMockCategories() {
    _categories = [
      _CategoryModel(
        id: 'cat-001',
        name: 'Restaurants',
        icon: Icons.restaurant_rounded,
        color: const Color(0xFFFF6B6B),
        businessCount: 95,
      ),
      _CategoryModel(
        id: 'cat-002',
        name: 'Hôtels',
        icon: Icons.hotel_rounded,
        color: const Color(0xFF4ECDC4),
        businessCount: 52,
      ),
      _CategoryModel(
        id: 'cat-003',
        name: 'Boutiques',
        icon: Icons.shopping_bag_rounded,
        color: const Color(0xFFFFE66D),
        businessCount: 68,
      ),
      _CategoryModel(
        id: 'cat-004',
        name: 'Spas & Beauté',
        icon: Icons.spa_rounded,
        color: const Color(0xFF95E1D3),
        businessCount: 34,
      ),
      _CategoryModel(
        id: 'cat-005',
        name: 'Transports',
        icon: Icons.directions_car_rounded,
        color: const Color(0xFFC7CEEA),
        businessCount: 28,
      ),
      _CategoryModel(
        id: 'cat-006',
        name: 'Cafés',
        icon: Icons.coffee_rounded,
        color: const Color(0xFFFF8B94),
        businessCount: 0,
      ),
    ];
  }

  Future<void> _showAddCategoryDialog() async {
    final controller = TextEditingController();
    IconData selectedIcon = Icons.restaurant_rounded;
    Color selectedColor = _availableColors[0];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Ajouter une catégorie'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'Nom de la catégorie',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sélectionner une icône',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 5,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: _availableIcons.map((icon) {
                        final isSelected = icon == selectedIcon;
                        return InkWell(
                          onTap: () => setState(() => selectedIcon = icon),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Icon(
                              icon,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sélectionner une couleur',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 5,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: _availableColors.map((color) {
                        final isSelected = color == selectedColor;
                        return InkWell(
                          onTap: () => setState(() => selectedColor = color),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(color: Colors.black, width: 3)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () {
                    if (controller.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Veuillez entrer un nom')),
                      );
                      return;
                    }
                    _addCategory(controller.text, selectedIcon, selectedColor);
                    Navigator.pop(context);
                  },
                  child: const Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addCategory(String name, IconData icon, Color color) {
    final newCategory = _CategoryModel(
      id: 'cat-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      icon: icon,
      color: color,
      businessCount: 0,
    );
    setState(() => _categories.add(newCategory));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Catégorie "$name" ajoutée.')));
  }

  Future<void> _showEditCategoryDialog(_CategoryModel category) async {
    final controller = TextEditingController(text: category.name);
    IconData selectedIcon = category.icon;
    Color selectedColor = category.color;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Éditer une catégorie'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'Nom de la catégorie',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sélectionner une icône',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 5,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: _availableIcons.map((icon) {
                        final isSelected = icon == selectedIcon;
                        return InkWell(
                          onTap: () => setState(() => selectedIcon = icon),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Icon(
                              icon,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sélectionner une couleur',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 5,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: _availableColors.map((color) {
                        final isSelected = color == selectedColor;
                        return InkWell(
                          onTap: () => setState(() => selectedColor = color),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(color: Colors.black, width: 3)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () {
                    if (controller.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Veuillez entrer un nom')),
                      );
                      return;
                    }
                    _editCategory(
                      category,
                      controller.text,
                      selectedIcon,
                      selectedColor,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editCategory(
    _CategoryModel category,
    String name,
    IconData icon,
    Color color,
  ) {
    setState(() {
      category.name = name;
      category.icon = icon;
      category.color = color;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Catégorie "$name" mise à jour.')));
  }

  Future<void> _deleteCategory(_CategoryModel category) async {
    if (category.businessCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de supprimer "${category.name}". ${category.businessCount} entreprise${category.businessCount > 1 ? 's' : ''} ${category.businessCount > 1 ? 'sont' : 'est'} associée${category.businessCount > 1 ? 's' : ''}.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer la catégorie'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer "${category.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() => _categories.removeWhere((c) => c.id == category.id));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Catégorie "${category.name}" supprimée.')),
      );
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.logout_rounded),
          title: const Text('Se déconnecter ?'),
          content: const Text(
            'Voulez-vous vraiment quitter votre session admin ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Déconnexion'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      ref.read(authStateProvider.notifier).logout();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 900;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des catégories'),
        centerTitle: false,
        leading: isTablet
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        child: const Icon(Icons.add_rounded),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_categories.length} catégorie${_categories.length != 1 ? 's' : ''}',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = _categories.removeAt(oldIndex);
                  _categories.insert(newIndex, item);
                });
              },
              children: _categories.asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value;

                return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Drag handle
                            ReorderableDragStartListener(
                              index: index,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Icon(
                                  Icons.drag_handle_rounded,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),

                            // Icon
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: category.color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                category.icon,
                                color: category.color,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Name and count
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.name,
                                    style: textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${category.businessCount} entreprise${category.businessCount != 1 ? 's' : ''}',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Actions
                            PopupMenuButton<String>(
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: const [
                                      Icon(Icons.edit_rounded, size: 18),
                                      SizedBox(width: 8),
                                      Text('Éditer'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: const [
                                      Icon(
                                        Icons.delete_rounded,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Supprimer',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditCategoryDialog(category);
                                } else if (value == 'delete') {
                                  _deleteCategory(category);
                                }
                              },
                              child: Icon(
                                Icons.more_vert_rounded,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate(key: ValueKey(category.id))
                    .fadeIn(duration: 260.ms)
                    .slideY(begin: 0.04);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryModel {
  final String id;
  String name;
  IconData icon;
  Color color;
  final int businessCount;

  _CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.businessCount,
  });
}
