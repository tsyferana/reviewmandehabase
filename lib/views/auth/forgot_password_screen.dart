import 'package:review_app/utils/couleur.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/validators.dart';
import '../../controllers/auth_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  static const routeName = '/forgot-password';

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authController = ref.read(authControllerProvider);
    final success = await authController.sendPasswordResetEmail(
      _emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lien de réinitialisation envoyé à ${_emailController.text.trim()}.',
          ),
        ),
      );

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            icon: const Icon(Icons.mark_email_read_outlined),
            title: const Text('Email envoyé'),
            content: const Text(
              'Si un compte existe avec cette adresse, vous recevrez un lien '
              'pour réinitialiser votre mot de passe.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/login');
                },
                child: const Text('Compris'),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authController.errorMessage ?? 'Une erreur est survenue.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: isLoading
              ? null
              : () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/login');
                  }
                },
        ),
      ),
      body: SizedBox.expand(
        child: Stack(
          children: [
            // ── Ambient background ───────────────────────────────────
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
            // Top-right decorative orb
            Positioned(
              top: -size.width * 0.3,
              right: -size.width * 0.2,
              child: Container(
                width: size.width * 0.65,
                height: size.width * 0.65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.14),
                      colorScheme.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Icon(
                        Icons.lock_reset_rounded,
                        color: colorScheme.onPrimaryContainer,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Mot de passe oublié',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Saisissez votre email. Nous allons vous envoyer un lien '
                      'de réinitialisation pour récupérer votre compte.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      enabled: !isLoading,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      onFieldSubmitted: (_) => _sendResetLink(),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                        border: OutlineInputBorder(),
                      ),
                      validator: AppValidators.validateEmail,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: isLoading ? null : _sendResetLink,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                      ),
                      child: AnimatedSwitcher(
                        duration: 180.ms,
                        child: isLoading
                            ? const SizedBox(
                                key: ValueKey('forgot-loading'),
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: AppColors.white,
                                ),
                              )
                            : const Text(
                                'Envoyer le lien de réinitialisation',
                                key: ValueKey('forgot-label'),
                                textAlign: TextAlign.center,
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/login');
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Retour à la connexion'),
                    ),
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
    ).animate().fadeIn(duration: 420.ms, curve: Curves.easeOutCubic);
  }

}
