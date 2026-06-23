import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/auth_providers.dart';
import '../../routes/app_router.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  static const routeName = '/reset-password';

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _passwordFocused = false;
  bool _confirmFocused = false;
  bool _done = false;

  // Strength: 0–4
  int get _strength {
    final v = _passwordController.text;
    if (v.isEmpty) return 0;
    int s = 0;
    if (v.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(v)) s++;
    if (RegExp(r'[0-9]').hasMatch(v)) s++;
    if (RegExp(r'[!@#\$&*~%^()_\-+=\[\]{}|;:,.<>?]').hasMatch(v)) s++;
    return s;
  }

  @override
  void initState() {
    super.initState();
    _passwordFocus.addListener(
      () => setState(() => _passwordFocused = _passwordFocus.hasFocus),
    );
    _confirmFocus.addListener(
      () => setState(() => _confirmFocused = _confirmFocus.hasFocus),
    );
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final authController = ref.read(authControllerProvider);
    final success = await authController.updatePassword(
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      setState(() => _done = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authController.errorMessage ??
                'Impossible de mettre à jour le mot de passe.',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    }
  }

  void _cancel() {
    ref.read(authStateProvider.notifier).logout();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
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
            top: -size.width * 0.28,
            right: -size.width * 0.18,
            child: Container(
              width: size.width * 0.6,
              height: size.width * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.13),
                    colorScheme.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.06),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _done
                        ? _SuccessView(
                            key: const ValueKey('success'),
                            onContinue: () => context.go('/login'),
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          )
                        : _FormView(
                            key: const ValueKey('form'),
                            formKey: _formKey,
                            passwordController: _passwordController,
                            confirmController: _confirmController,
                            passwordFocus: _passwordFocus,
                            confirmFocus: _confirmFocus,
                            passwordFocused: _passwordFocused,
                            confirmFocused: _confirmFocused,
                            obscurePassword: _obscurePassword,
                            obscureConfirm: _obscureConfirm,
                            strength: _strength,
                            isLoading: isLoading,
                            onTogglePassword: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            onToggleConfirm: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                            onSubmit: _handleReset,
                            onCancel: _cancel,
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form view
// ─────────────────────────────────────────────────────────────────────────────

class _FormView extends StatelessWidget {
  const _FormView({
    super.key,
    required this.formKey,
    required this.passwordController,
    required this.confirmController,
    required this.passwordFocus,
    required this.confirmFocus,
    required this.passwordFocused,
    required this.confirmFocused,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.strength,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onSubmit,
    required this.onCancel,
    required this.colorScheme,
    required this.textTheme,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final FocusNode passwordFocus;
  final FocusNode confirmFocus;
  final bool passwordFocused;
  final bool confirmFocused;
  final bool obscurePassword;
  final bool obscureConfirm;
  final int strength;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final cs = colorScheme;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),

          // Icon badge
          Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.20),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.vpn_key_rounded,
                    color: cs.onPrimaryContainer,
                    size: 34,
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 500.ms, curve: Curves.easeOutCubic)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                duration: 600.ms,
                curve: Curves.easeOutBack,
              ),

          const SizedBox(height: 28),

          Text(
                'Nouveau\nmot de passe',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  letterSpacing: -0.3,
                  height: 1.15,
                ),
              )
              .animate(delay: 80.ms)
              .fadeIn(duration: 450.ms)
              .slideY(
                begin: 0.12,
                end: 0,
                duration: 450.ms,
                curve: Curves.easeOutCubic,
              ),

          const SizedBox(height: 12),

          Text(
                'Choisissez un mot de passe fort pour sécuriser votre compte.',
                style: textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
              )
              .animate(delay: 140.ms)
              .fadeIn(duration: 450.ms)
              .slideY(
                begin: 0.10,
                end: 0,
                duration: 450.ms,
                curve: Curves.easeOutCubic,
              ),

          const SizedBox(height: 36),

          // ── Form card ──────────────────────────────────────────
          Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.10)),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Password field
                    _FieldLabel(
                      icon: Icons.lock_outline_rounded,
                      label: 'NOUVEAU MOT DE PASSE',
                      cs: cs,
                      textTheme: textTheme,
                    ),
                    const SizedBox(height: 10),
                    _StyledField(
                      controller: passwordController,
                      focusNode: passwordFocus,
                      isFocused: passwordFocused,
                      obscureText: obscurePassword,
                      enabled: !isLoading,
                      hint: '••••••••',
                      cs: cs,
                      textTheme: textTheme,
                      prefixIcon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: cs.onSurfaceVariant,
                        ),
                        onPressed: onTogglePassword,
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Au moins 6 caractères requis.'
                          : null,
                    ),

                    // Strength meter
                    if (passwordController.text.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _StrengthMeter(
                        strength: strength,
                        cs: cs,
                        textTheme: textTheme,
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Confirm field
                    _FieldLabel(
                      icon: Icons.lock_reset_rounded,
                      label: 'CONFIRMER LE MOT DE PASSE',
                      cs: cs,
                      textTheme: textTheme,
                    ),
                    const SizedBox(height: 10),
                    _StyledField(
                      controller: confirmController,
                      focusNode: confirmFocus,
                      isFocused: confirmFocused,
                      obscureText: obscureConfirm,
                      enabled: !isLoading,
                      hint: '••••••••',
                      cs: cs,
                      textTheme: textTheme,
                      prefixIcon: Icons.lock_reset_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: cs.onSurfaceVariant,
                        ),
                        onPressed: onToggleConfirm,
                      ),
                      validator: (v) => v != passwordController.text
                          ? 'Les mots de passe ne correspondent pas.'
                          : null,
                    ),
                  ],
                ),
              )
              .animate(delay: 200.ms)
              .fadeIn(duration: 450.ms)
              .slideY(
                begin: 0.08,
                end: 0,
                duration: 450.ms,
                curve: Curves.easeOutCubic,
              ),

          const SizedBox(height: 24),

          // Submit button
          SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: isLoading ? null : onSubmit,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isLoading
                        ? SizedBox(
                            key: const ValueKey('loader'),
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: cs.onPrimary,
                            ),
                          )
                        : Text(
                            key: const ValueKey('label'),
                            'Enregistrer le mot de passe',
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onPrimary,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              )
              .animate(delay: 280.ms)
              .fadeIn(duration: 400.ms)
              .slideY(
                begin: 0.08,
                end: 0,
                duration: 400.ms,
                curve: Curves.easeOutCubic,
              ),

          const SizedBox(height: 14),

          // Cancel link
          Center(
            child: TextButton.icon(
              onPressed: isLoading ? null : onCancel,
              icon: Icon(
                Icons.close_rounded,
                size: 16,
                color: cs.onSurfaceVariant,
              ),
              label: Text(
                'Annuler et retourner à la connexion',
                style: textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ).animate(delay: 340.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Success view
// ─────────────────────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    super.key,
    required this.onContinue,
    required this.colorScheme,
    required this.textTheme,
  });

  final VoidCallback onContinue;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final cs = colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 60),

        // Badge with rings
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.primaryContainer.withValues(alpha: 0.25),
                ),
              ).animate().scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.0, 1.0),
                duration: 700.ms,
                curve: Curves.easeOutBack,
              ),
              Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primaryContainer.withValues(alpha: 0.45),
                    ),
                  )
                  .animate(delay: 80.ms)
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1.0, 1.0),
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  ),
              Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primaryContainer,
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.28),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: cs.onPrimaryContainer,
                      size: 36,
                    ),
                  )
                  .animate(delay: 160.ms)
                  .fadeIn(duration: 400.ms)
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1.0, 1.0),
                    duration: 500.ms,
                    curve: Curves.easeOutBack,
                  ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        Text(
              'Mot de passe\nmis à jour !',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                letterSpacing: -0.3,
                height: 1.15,
              ),
              textAlign: TextAlign.center,
            )
            .animate(delay: 260.ms)
            .fadeIn(duration: 450.ms)
            .slideY(
              begin: 0.12,
              end: 0,
              duration: 450.ms,
              curve: Curves.easeOutCubic,
            ),

        const SizedBox(height: 14),

        Text(
              'Votre compte est sécurisé. Connectez-vous avec votre nouveau mot de passe.',
              style: textTheme.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            )
            .animate(delay: 320.ms)
            .fadeIn(duration: 450.ms)
            .slideY(
              begin: 0.10,
              end: 0,
              duration: 450.ms,
              curve: Curves.easeOutCubic,
            ),

        const SizedBox(height: 18),

        // Security tip card
        Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.50),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outline.withValues(alpha: 0.10)),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, size: 18, color: cs.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ne partagez jamais votre mot de passe avec personne.',
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )
            .animate(delay: 400.ms)
            .fadeIn(duration: 400.ms)
            .slideY(
              begin: 0.08,
              end: 0,
              duration: 400.ms,
              curve: Curves.easeOutCubic,
            ),

        const SizedBox(height: 40),

        SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.login_rounded, size: 18),
                label: Text(
                  'Se connecter',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            )
            .animate(delay: 480.ms)
            .fadeIn(duration: 400.ms)
            .slideY(
              begin: 0.08,
              end: 0,
              duration: 400.ms,
              curve: Curves.easeOutCubic,
            ),

        const SizedBox(height: 40),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Password strength meter
// ─────────────────────────────────────────────────────────────────────────────

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({
    required this.strength,
    required this.cs,
    required this.textTheme,
  });

  final int strength;
  final ColorScheme cs;
  final TextTheme textTheme;

  static const _labels = ['Très faible', 'Faible', 'Moyen', 'Fort'];
  static const _colors = [
    Color(0xFFEF5350), // red
    Color(0xFFFF9800), // orange
    Color(0xFFFDD835), // yellow
    Color(0xFF66BB6A), // green
  ];

  @override
  Widget build(BuildContext context) {
    final idx = (strength - 1).clamp(0, 3);
    final color = strength == 0 ? cs.outline : _colors[idx];
    final label = strength == 0 ? '' : _labels[idx];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            final filled = i < strength;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: filled ? color : cs.onSurface.withValues(alpha: 0.12),
                ),
              ),
            );
          }),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared field label row
// ─────────────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.icon,
    required this.label,
    required this.cs,
    required this.textTheme,
  });

  final IconData icon;
  final String label;
  final ColorScheme cs;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: cs.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Styled text field (reusable)
// ─────────────────────────────────────────────────────────────────────────────

class _StyledField extends StatelessWidget {
  const _StyledField({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.obscureText,
    required this.enabled,
    required this.hint,
    required this.cs,
    required this.textTheme,
    required this.prefixIcon,
    required this.validator,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final bool obscureText;
  final bool enabled;
  final String hint;
  final ColorScheme cs;
  final TextTheme textTheme;
  final IconData prefixIcon;
  final FormFieldValidator<String> validator;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        enabled: enabled,
        style: textTheme.bodyLarge?.copyWith(color: cs.onSurface),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(
            prefixIcon,
            size: 20,
            color: isFocused ? cs.primary : cs.onSurfaceVariant,
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: isFocused
              ? cs.primaryContainer.withValues(alpha: 0.20)
              : cs.surfaceContainerHighest.withValues(alpha: 0.50),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: cs.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: cs.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: cs.error, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
