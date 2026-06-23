import 'package:review_app/utils/couleur.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    final initials = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // ── Gradient header ───────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              left: 24,
              right: 24,
              bottom: 28,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.8),
                  colorScheme.secondary.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: userAvatar != null
                        ? NetworkImage(userAvatar!)
                        : null,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    child: userAvatar == null
                        ? Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  userName,
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.08),

                const SizedBox(height: 4),

                Text(
                  userEmail,
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ).animate(delay: 60.ms).fadeIn(duration: 400.ms).slideX(begin: -0.08),

                const SizedBox(height: 10),

                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    _roleLabel(userRole),
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Menu items ────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                ...menuItems.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  return _DrawerTile(
                    icon: item['icon'] as IconData,
                    label: item['label'] as String,
                    onTap: () {
                      Navigator.pop(context);
                      context.go(item['route'] as String);
                    },
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ).animate(delay: (40 + i * 35).ms).fadeIn(duration: 300.ms).slideX(begin: -0.06);
                }),

                Divider(
                  height: 24,
                  indent: 16,
                  endIndent: 16,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),

                _DrawerTile(
                  icon: Icons.logout_rounded,
                  label: 'Déconnexion',
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmLogout(context, ref);
                  },
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Administrateur';
      case 'business':
        return 'Propriétaire';
      default:
        return 'Client';
    }
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

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colorScheme,
    required this.textTheme,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        borderRadius: BorderRadius.circular(14),
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    color: isDestructive ? AppColors.error : colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
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
