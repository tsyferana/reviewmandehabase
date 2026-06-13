import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../repositories/user_repository.dart';
import '../../routes/app_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  static const routeName = '/profile';

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final MockUserRecord _currentUser = const MockUserRecord(
    id: 'user-business-001',
    fullName: 'Aina Rajaonarivelo',
    email: 'business@reviewapp.test',
    phone: '+261 34 12 34 567',
    accountType: MockAccountType.businessOwner,
  );

  bool _notificationsEnabled = true;
  bool _isDarkMode = false;
  String _language = 'Français';

  final DateTime _memberSince = DateTime(2023, 6, 15);
  final int _reviewsCount = 28;
  final int _favoritesCount = 14;
  final int _photosCount = 9;

  String _formatMemberSince(DateTime date) {
    return DateFormat.yMMMM('fr_FR').format(date);
  }

  void _openSettingsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Paramètres',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SwitchListTile(
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                        setModalState(() {});
                      },
                      title: const Text('Notifications'),
                      subtitle: const Text(
                        'Recevoir les alertes pour les avis et offres.',
                      ),
                    ),
                    SwitchListTile(
                      value: _isDarkMode,
                      onChanged: (value) {
                        setState(() => _isDarkMode = value);
                        setModalState(() {});
                      },
                      title: const Text('Thème sombre'),
                      subtitle: const Text(
                        'Activer le mode sombre de l’application.',
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Langue'),
                      subtitle: Text(_language),
                      trailing: const Icon(Icons.language_rounded),
                      onTap: () async {
                        final selected = await showDialog<String>(
                          context: context,
                          builder: (context) {
                            return SimpleDialog(
                              title: const Text('Choisir une langue'),
                              children: [
                                SimpleDialogOption(
                                  onPressed: () =>
                                      Navigator.pop(context, 'Français'),
                                  child: const Text('Français'),
                                ),
                                SimpleDialogOption(
                                  onPressed: () =>
                                      Navigator.pop(context, 'English'),
                                  child: const Text('English'),
                                ),
                                SimpleDialogOption(
                                  onPressed: () =>
                                      Navigator.pop(context, 'Español'),
                                  child: const Text('Español'),
                                ),
                              ],
                            );
                          },
                        );
                        if (selected != null) {
                          setState(() => _language = selected);
                          setModalState(() {});
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.logout_rounded),
          title: const Text('Se déconnecter ?'),
          content: const Text(
            'Voulez-vous vraiment quitter votre compte ReviewApp ?',
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

  void _showHelp() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Aide & Support',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              const Text(
                'Notre équipe est disponible 7j/7 pour répondre à vos questions.',
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.email_rounded),
                title: const Text('support@reviewapp.test'),
                subtitle: const Text('Support par email'),
              ),
              ListTile(
                leading: const Icon(Icons.headset_mic_rounded),
                title: const Text('Assistance vocale'),
                subtitle: const Text('Disponible entre 9h et 18h'),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'ReviewApp',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2026 ReviewApp',
      children: const [
        SizedBox(height: 12),
        Text(
          'ReviewApp vous aide à suivre vos avis, vos favoris et votre activité client.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final backgroundGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? [
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.14),
              colorScheme.surface,
            ]
          : [
              colorScheme.primaryContainer.withValues(alpha: 0.18),
              colorScheme.surface,
            ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Profil'), centerTitle: false),
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Text(
                              _currentUser.fullName
                                  .split(' ')
                                  .map((part) => part.isNotEmpty ? part[0] : '')
                                  .take(2)
                                  .join(),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentUser.fullName,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _currentUser.email,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Chip(
                                  label: Text(
                                    _currentUser.accountType ==
                                            MockAccountType.businessOwner
                                        ? 'Propriétaire d’entreprise'
                                        : 'Utilisateur',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text('Modifier'),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 420.ms)
                    .scale(
                      begin: const Offset(0.96, 0.96),
                      end: const Offset(1, 1),
                      duration: 420.ms,
                    ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _ProfileStatCard(
                      icon: Icons.rate_review_rounded,
                      label: 'Avis',
                      value: '$_reviewsCount',
                    ),
                    _ProfileStatCard(
                      icon: Icons.favorite_rounded,
                      label: 'Favoris',
                      value: '$_favoritesCount',
                    ),
                    _ProfileStatCard(
                      icon: Icons.camera_alt_rounded,
                      label: 'Photos',
                      value: '$_photosCount',
                    ),
                    _ProfileStatCard(
                      icon: Icons.calendar_month_rounded,
                      label: 'Membre depuis',
                      value: _formatMemberSince(_memberSince),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _ProfileSectionTile(
                        icon: Icons.history_rounded,
                        title: 'Historique des avis',
                        subtitle: 'Voir vos avis publiés',
                        onTap: () => context.go('/home/reviews/biz-001'),
                      ),
                      _ProfileSectionTile(
                        icon: Icons.favorite_outline_rounded,
                        title: 'Mes favoris',
                        subtitle: 'Accéder à votre liste de favoris',
                        onTap: () => context.go('/favorites'),
                      ),
                      _ProfileSectionTile(
                        icon: Icons.settings_outlined,
                        title: 'Paramètres',
                        subtitle: 'Notifications, langue et thème',
                        onTap: _openSettingsSheet,
                      ),
                      if (_currentUser.accountType ==
                          MockAccountType.businessOwner)
                        _ProfileSectionTile(
                          icon: Icons.storefront_rounded,
                          title: 'Mon entreprise',
                          subtitle: 'Gérer votre présence professionnelle',
                          onTap: () => context.go('/business/dashboard'),
                        ),
                      _ProfileSectionTile(
                        icon: Icons.headset_mic_rounded,
                        title: 'Aide & Support',
                        subtitle: 'Contacter l’assistance ReviewApp',
                        onTap: _showHelp,
                      ),
                      _ProfileSectionTile(
                        icon: Icons.info_outline_rounded,
                        title: 'À propos',
                        subtitle: 'Version et informations légales',
                        onTap: _showAbout,
                      ),
                      _ProfileSectionTile(
                        icon: Icons.logout_rounded,
                        title: 'Déconnexion',
                        subtitle: 'Se déconnecter de votre compte',
                        onTap: _confirmLogout,
                        foregroundColor: colorScheme.error,
                      ),
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

class _ProfileStatCard extends StatelessWidget {
  const _ProfileStatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 164,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSectionTile extends StatelessWidget {
  const _ProfileSectionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.foregroundColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = foregroundColor ?? colorScheme.onSurface;

    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      leading: CircleAvatar(
        backgroundColor: effectiveColor.withValues(alpha: 0.12),
        child: Icon(icon, color: effectiveColor),
      ),
      title: Text(title, style: TextStyle(color: effectiveColor)),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: foregroundColor != null
              ? effectiveColor.withValues(alpha: 0.85)
              : colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}
