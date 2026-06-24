import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/auth_providers.dart';
import '../../routes/app_router.dart';
import '../../utils/validators.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  static const routeName = '/register';

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _accountType = 'client';
  bool _acceptTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez accepter les conditions d’utilisation.'),
        ),
      );
      return;
    }

    final authController = ref.read(authControllerProvider);

    final isRegistered = await authController.register(
      fullName: _fullNameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      password: _passwordController.text,
      accountType: _accountType,
    );

    if (!mounted) return;

    if (isRegistered) {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user != null) {
        final role = user.userMetadata?['account_type'] ?? 'client';
        final authNotifier = ref.read(authStateProvider.notifier);

        if (role == 'business_owner') {
          authNotifier.loginAsBusiness(user.id);
        } else {
          authNotifier.loginAsClient(user.id);
        }
      }

      context.go('/home');
      return;
    }

    final message =
        authController.errorMessage ?? 'Impossible de creer le compte.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authController = ref.watch(authControllerProvider);

    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          children: [
          // ── Fond identique au login ──────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.5, 1.0],
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.07),
                    colorScheme.surface,
                    colorScheme.secondary.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
          ),

          // Orbe haut-droit
          Positioned(
            top: -MediaQuery.sizeOf(context).width * 0.3,
            right: -MediaQuery.sizeOf(context).width * 0.2,
            child: Container(
              width: MediaQuery.sizeOf(context).width * 0.7,
              height: MediaQuery.sizeOf(context).width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.10),
                    colorScheme.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // ── Contenu ─────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Back button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: authController.isLoading
                                  ? null
                                  : () {
                                      if (context.canPop()) {
                                        context.pop();
                                      } else {
                                        context.go('/login');
                                      }
                                    },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colorScheme.outlineVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  color: colorScheme.onSurface,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05),

                        const SizedBox(height: 24),

                        Text(
                          'Créer un compte',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ).animate(delay: 40.ms).fadeIn(duration: 420.ms).slideY(begin: 0.05),

                        const SizedBox(height: 8),

                        Text(
                          'Rejoignez ReviewApp pour découvrir, noter et sauvegarder vos lieux favoris.',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ).animate(delay: 80.ms).fadeIn(duration: 400.ms),

                        const SizedBox(height: 28),

                        // ── Account type selector (card-based) ──
                        Text(
                          'Type de compte',
                          style: textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ).animate(delay: 100.ms).fadeIn(duration: 400.ms),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: _AccountTypeCard(
                                icon: Icons.person_rounded,
                                label: 'Client',
                                subtitle: 'Découvrir & noter',
                                isSelected: _accountType == 'client',
                                onTap: authController.isLoading
                                    ? null
                                    : () => setState(() => _accountType = 'client'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _AccountTypeCard(
                                icon: Icons.storefront_rounded,
                                label: 'Propriétaire',
                                subtitle: 'Gérer mon établissement',
                                isSelected: _accountType == 'business_owner',
                                onTap: authController.isLoading
                                    ? null
                                    : () => setState(() => _accountType = 'business_owner'),
                              ),
                            ),
                          ],
                        ).animate(delay: 120.ms).fadeIn(duration: 400.ms),

                        const SizedBox(height: 22),

                        // ── Form fields ────────────────────────────
                        TextFormField(
                          controller: _fullNameController,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          decoration: const InputDecoration(
                            labelText: 'Nom complet',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: AppValidators.validateRequired,
                        ).animate(delay: 140.ms).fadeIn(duration: 400.ms).slideY(begin: 0.04),

                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline_rounded),
                          ),
                          validator: AppValidators.validateEmail,
                        ).animate(delay: 170.ms).fadeIn(duration: 400.ms).slideY(begin: 0.04),

                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          decoration: const InputDecoration(
                            labelText: 'Telephone',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: AppValidators.validatePhone,
                        ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.04),

                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Afficher le mot de passe'
                                  : 'Masquer le mot de passe',
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                              ),
                            ),
                          ),
                          validator: AppValidators.validatePassword,
                        ).animate(delay: 230.ms).fadeIn(duration: 400.ms).slideY(begin: 0.04),

                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Confirmer le mot de passe',
                            prefixIcon: const Icon(Icons.lock_reset_rounded),
                            suffixIcon: IconButton(
                              tooltip: _obscureConfirmPassword
                                  ? 'Afficher la confirmation'
                                  : 'Masquer la confirmation',
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                              ),
                            ),
                          ),
                          validator: (v) => AppValidators.validateMatch(v, _passwordController.text),
                        ).animate(delay: 260.ms).fadeIn(duration: 400.ms).slideY(begin: 0.04),

                        const SizedBox(height: 10),

                        // Terms & conditions
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: colorScheme.outlineVariant
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: CheckboxListTile(
                            value: _acceptTerms,
                            onChanged: authController.isLoading
                                ? null
                                : (value) {
                                    setState(() => _acceptTerms = value ?? false);
                                  },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            title: Text(
                              'J\'accepte les conditions d\'utilisation',
                              style: textTheme.bodyMedium,
                            ),
                          ),
                        ).animate(delay: 290.ms).fadeIn(duration: 400.ms),

                        const SizedBox(height: 20),

                        // Submit button
                        FilledButton(
                          onPressed: authController.isLoading ? null : _submit,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: 180.ms,
                            child: authController.isLoading
                                ? const SizedBox(
                                    key: ValueKey('register-loading'),
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'S\'inscrire',
                                    key: ValueKey('register-label'),
                                  ),
                          ),
                        ).animate(delay: 310.ms).fadeIn(duration: 400.ms),

                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Déjà inscrit ?', style: textTheme.bodyMedium),
                            TextButton(
                              onPressed: authController.isLoading
                                  ? null
                                  : () {
                                      if (context.canPop()) {
                                        context.pop();
                                      } else {
                                        context.go('/login');
                                      }
                                    },
                              child: const Text('Se connecter'),
                            ),
                          ],
                        ).animate(delay: 340.ms).fadeIn(duration: 400.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Account type selector card
// ─────────────────────────────────────────────────────────────────────────────

class _AccountTypeCard extends StatelessWidget {
  const _AccountTypeCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary.withValues(alpha: 0.15)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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

