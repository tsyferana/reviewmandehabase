import 'package:review_app/utils/couleur.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/validators.dart';


import '../../controllers/auth_providers.dart';
import '../../routes/app_router.dart';
import '../../services/supabase_data_service.dart';

// Provider global pour gérer le mode du thème (Clair, Sombre ou Système)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

final userBusinessProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  return await SupabaseDataService().getUserBusiness();
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  static const routeName = '/profile';

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late String _fullName;
  String? _photoUrl;

  bool _notificationsEnabled = true;
  String _language = 'Français';

  DateTime _memberSince = DateTime.now();
  int _reviewsCount = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    _fullName = user?.userMetadata?['full_name'] ?? 'Utilisateur';
    _photoUrl = user?.userMetadata?['avatar_url'];
    if (user != null && user.createdAt.isNotEmpty) {
      _memberSince = DateTime.tryParse(user.createdAt) ?? DateTime.now();
    }
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final List<dynamic> data = await Supabase.instance.client.from('reviews').select('id').eq('user_id', user.id);
        if (mounted) {
          setState(() {
            _reviewsCount = data.length;
            _isLoadingStats = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  String _formatMemberSince(DateTime date) {
    return DateFormat.yMMMM('fr_FR').format(date);
  }

  void _editProfile() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: _fullName);
    File? localImageFile;
    bool isSaving = false;
    String? errorMessage;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Modifier le profil'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: isSaving ? null : () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setDialogState(() {
                            localImageFile = File(pickedFile.path);
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(50),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 46,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            backgroundImage: localImageFile != null
                                ? FileImage(localImageFile!) as ImageProvider
                                : (_photoUrl != null ? NetworkImage(_photoUrl!) : null),
                            child: localImageFile == null && _photoUrl == null
                                ? const Icon(Icons.person_rounded, size: 40)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: nameController,
                      enabled: !isSaving,
                      decoration: const InputDecoration(
                        labelText: 'Nom d\'affichage',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                        border: OutlineInputBorder(),
                      ),
                      validator: AppValidators.validateRequired,
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: isSaving ? null : () async {
                    if (!formKey.currentState!.validate()) return;
                    setDialogState(() {
                      isSaving = true;
                      errorMessage = null;
                    });
                    
                    try {
                      final success = await ref.read(authControllerProvider).updateProfile(
                        fullName: nameController.text.trim(),
                        imageFile: localImageFile,
                      );
                      
                      if (success) {
                        if (mounted) {
                          final user = Supabase.instance.client.auth.currentUser;
                          setState(() {
                            _fullName = user?.userMetadata?['full_name'] ?? _fullName;
                            _photoUrl = user?.userMetadata?['avatar_url'] ?? _photoUrl;
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profil mis à jour avec succès'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } else {
                        // Si succes est faux, c'est que l'authController a intercepté l'erreur
                        final err = ref.read(authControllerProvider).errorMessage;
                        setDialogState(() {
                          isSaving = false;
                          errorMessage = err ?? 'Erreur inconnue';
                        });
                      }
                    } catch (e) {
                      setDialogState(() {
                        isSaving = false;
                        errorMessage = e.toString();
                      });
                    }
                  },
                  child: isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                      : const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
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
            final themeMode = ref.watch(themeModeProvider);
            final isDark = themeMode == ThemeMode.dark;

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
                      value: isDark,
                      onChanged: (value) {
                        // Met à jour le provider global
                        ref.read(themeModeProvider.notifier).state = value
                            ? ThemeMode.dark
                            : ThemeMode.light;

                        // Rafraîchit l'interface du modal et de l'écran
                        setModalState(() {});
                        setState(() {});
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
      await Supabase.instance.client.auth.signOut();
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
    final themeMode = ref.watch(themeModeProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final userBusinessAsync = ref.watch(userBusinessProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
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
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // ── Gradient header banner ─────────────────────────────
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Gradient banner
                    Container(
                      height: 130,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primary,
                            colorScheme.primary.withValues(alpha: 0.75),
                            colorScheme.secondary.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                      // Decorative orb
                      child: Stack(
                        children: [
                          Positioned(
                            top: -30,
                            right: -20,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.12),
                                    Colors.white.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // AppBar back area
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: Row(
                              children: [
                                Text(
                                  'Mon Profil',
                                  style: textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Avatar overlapping banner
                    Positioned(
                      bottom: -52,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: colorScheme.primaryContainer,
                          backgroundImage: _photoUrl != null
                              ? NetworkImage(_photoUrl!)
                              : null,
                          child: _photoUrl == null
                              ? Text(
                                  _fullName
                                      .split(' ')
                                      .map((p) => p.isNotEmpty ? p[0] : '')
                                      .take(2)
                                      .join(),
                                  style: textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Name + email + edit ────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 64, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _fullName,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? '',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withValues(
                                  alpha: 0.6,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Text(
                                user?.userMetadata?['account_type'] ==
                                        'business_owner'
                                    ? '🏢 Propriétaire d\'entreprise'
                                    : '👤 Client',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _editProfile,
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Modifier'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 420.ms).slideY(begin: 0.04),
              ),

              // ── Stats ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: _isLoadingStats
                      ? const Center(child: CircularProgressIndicator())
                      : Row(
                          children: [
                            Expanded(
                              child: _ProfileStatCard(
                                icon: Icons.rate_review_rounded,
                                label: 'Avis publiés',
                                value: '$_reviewsCount',
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ProfileStatCard(
                                icon: Icons.calendar_month_rounded,
                                label: 'Membre depuis',
                                value: _formatMemberSince(_memberSince),
                                color: colorScheme.tertiary,
                              ),
                            ),
                          ],
                        ).animate(delay: 80.ms).fadeIn(duration: 400.ms),
                ),
              ),

              // ── Menu sections ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _ProfileSectionTile(
                          icon: Icons.history_rounded,
                          iconColor: colorScheme.primary,
                          title: 'Historique des avis',
                          subtitle: 'Voir vos avis publiés',
                          onTap: () => context.push('/user-reviews'),
                        ),
                        _SectionDivider(),
                        _ProfileSectionTile(
                          icon: Icons.favorite_rounded,
                          iconColor: Colors.red.shade400,
                          title: 'Mes favoris',
                          subtitle: 'Accéder à votre liste de favoris',
                          onTap: () => context.push('/favorites'),
                        ),
                        _SectionDivider(),
                        _ProfileSectionTile(
                          icon: Icons.settings_rounded,
                          iconColor: colorScheme.secondary,
                          title: 'Paramètres',
                          subtitle: 'Notifications, langue et thème',
                          onTap: _openSettingsSheet,
                        ),
                        _SectionDivider(),
                        userBusinessAsync.when(
                          data: (business) {
                            if (business != null) {
                              return _ProfileSectionTile(
                                icon: Icons.storefront_rounded,
                                iconColor: colorScheme.tertiary,
                                title: 'Mon entreprise',
                                subtitle: 'Gérer votre présence professionnelle',
                                onTap: () async {
                                  final status = business['status'];
                                  if (status == 'pending') {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('En attente'),
                                        content: const Text('Votre demande est en cours d\'examen par un administrateur.'),
                                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                                      ),
                                    );
                                  } else if (status == 'rejected') {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Demande rejetée'),
                                        content: const Text('Désolé, votre demande a été rejetée. Veuillez contacter le support.'),
                                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                                      ),
                                    );
                                  } else if (status == 'approved') {
                                    if (user?.userMetadata?['account_type'] != 'business_owner') {
                                      await SupabaseDataService().updateAccountType('business_owner');
                                    }
                                    if (context.mounted) context.push('/business/dashboard');
                                  }
                                },
                              );
                            } else {
                              return _ProfileSectionTile(
                                icon: Icons.add_business_rounded,
                                iconColor: colorScheme.tertiary,
                                title: 'Créer mon entreprise',
                                subtitle: 'Enregistrez votre établissement',
                                onTap: () => context.push('/business/create'),
                              );
                            }
                          },
                          loading: () => const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (error, stack) => _ProfileSectionTile(
                            icon: Icons.error_outline,
                            iconColor: colorScheme.error,
                            title: 'Erreur',
                            subtitle: error.toString(),
                            onTap: () {},
                          ),
                        ),
                        _SectionDivider(),
                        _ProfileSectionTile(
                          icon: Icons.headset_mic_rounded,
                          iconColor: Colors.teal,
                          title: 'Aide & Support',
                          subtitle: 'Contacter l\'assistance ReviewApp',
                          onTap: _showHelp,
                        ),
                        _SectionDivider(),
                        _ProfileSectionTile(
                          icon: Icons.info_outline_rounded,
                          iconColor: Colors.blueGrey,
                          title: 'À propos',
                          subtitle: 'Version et informations légales',
                          onTap: _showAbout,
                        ),
                        _SectionDivider(),
                        _ProfileSectionTile(
                          icon: Icons.logout_rounded,
                          iconColor: colorScheme.error,
                          title: 'Déconnexion',
                          subtitle: 'Se déconnecter de votre compte',
                          onTap: _confirmLogout,
                          foregroundColor: colorScheme.error,
                        ),
                      ],
                    ),
                  ).animate(delay: 140.ms).fadeIn(duration: 400.ms),
                ),
              ),
            ],
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
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 64,
      endIndent: 16,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
    );
  }
}

class _ProfileSectionTile extends StatelessWidget {
  const _ProfileSectionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.foregroundColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final effectiveColor = foregroundColor ?? colorScheme.onSurface;
    final effectiveIconColor = iconColor ?? colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: effectiveIconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: effectiveIconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.bodyMedium?.copyWith(
                        color: effectiveColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.labelSmall?.copyWith(
                        color: foregroundColor != null
                            ? effectiveColor.withValues(alpha: 0.7)
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
