import 'package:review_app/utils/couleur.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../routes/app_router.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({
    super.key,
    required this.userRole,
    this.userName = 'Utilisateur',
    this.userEmail = 'user@email.com',
    this.userAvatar,
  });

  final String userRole; // 'admin', 'business', 'client'
  final String userName;
  final String userEmail;
  final String? userAvatar;

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.logout_rounded),
          title: const Text('Se déconnecter ?'),
          content: const Text('Voulez-vous vraiment quitter votre session ?'),
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
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final menuItems = _getMenuItems();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          DrawerHeader(
            decoration: BoxDecoration(color: colorScheme.primaryContainer),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: userAvatar != null
                      ? NetworkImage(userAvatar!)
                      : null,
                  child: userAvatar == null
                      ? Icon(
                          Icons.person_rounded,
                          size: 32,
                          color: colorScheme.onPrimaryContainer,
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  userName,
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userEmail,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Menu items
          ...menuItems.map((item) {
            return ListTile(
              leading: Icon(item['icon'] as IconData),
              title: Text(item['label'] as String),
              onTap: () {
                Navigator.pop(context);
                context.go(item['route'] as String);
              },
            );
          }),

          const Divider(),

          // Settings and Logout
          ListTile(
            leading: const Icon(Icons.settings_rounded),
            title: const Text('Paramètres'),
            onTap: () {
              Navigator.pop(context);
              context.go('/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: const Text('Déconnexion'),
            onTap: () {
              Navigator.pop(context); // Ferme le drawer
              _confirmLogout(context, ref);
            },
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getMenuItems() {
    switch (userRole) {
      case 'admin':
        return [
          {
            'icon': Icons.dashboard_rounded,
            'label': 'Dashboard',
            'route': '/admin/dashboard',
          },
          {
            'icon': Icons.people_rounded,
            'label': 'Utilisateurs',
            'route': '/admin/users',
          },
          {
            'icon': Icons.business_rounded,
            'label': 'Entreprises',
            'route': '/admin/businesses',
          },
          {
            'icon': Icons.rate_review_rounded,
            'label': 'Avis',
            'route': '/admin/reviews',
          },
          {
            'icon': Icons.flag_rounded,
            'label': 'Signalements',
            'route': '/admin/reports',
          },
          {
            'icon': Icons.category_rounded,
            'label': 'Catégories',
            'route': '/admin/categories',
          },
        ];
      case 'business':
        return [
          {'icon': Icons.home_rounded, 'label': 'Accueil', 'route': '/home'},
          {
            'icon': Icons.dashboard_rounded,
            'label': 'Tableau de bord',
            'route': '/business-dashboard',
          },
          {
            'icon': Icons.rate_review_rounded,
            'label': 'Avis',
            'route': '/business/reviews-management',
          },
          {
            'icon': Icons.bar_chart_rounded,
            'label': 'Statistiques',
            'route': '/business/statistics',
          },
          {
            'icon': Icons.person_rounded,
            'label': 'Profil',
            'route': '/profile',
          },
        ];
      case 'client':
      default:
        return [
          {'icon': Icons.home_rounded, 'label': 'Accueil', 'route': '/home'},
          {
            'icon': Icons.favorite_rounded,
            'label': 'Favoris',
            'route': '/favorites',
          },
          {
            'icon': Icons.history_rounded,
            'label': 'Historique',
            'route': '/history',
          },
          {
            'icon': Icons.person_rounded,
            'label': 'Mon profil',
            'route': '/profile',
          },
        ];
    }
  }
}
