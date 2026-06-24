import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:review_app/utils/validators.dart';
import '../../controllers/auth_providers.dart';
import '../../routes/app_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _emailFocused = false;
  bool _passwordFocused = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final authController = ref.read(authControllerProvider);
    final success = await authController.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    _onLoginFinished(success, authController);
  }

  Future<void> _handleGoogleLogin() async {
    final authController = ref.read(authControllerProvider);
    final success = await authController.loginWithGoogle();
    _onLoginFinished(success, authController);
  }

  void _onLoginFinished(bool success, dynamic authController) {
    if (!mounted) return;
    if (success) {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user != null) {
        final role = user.userMetadata?['account_type'] ?? 'client';
        final authNotifier = ref.read(authStateProvider.notifier);
        if (role == 'admin') {
          authNotifier.loginAsAdmin(user.id);
        } else if (role == 'business_owner') {
          authNotifier.loginAsBusiness(user.id);
        } else {
          authNotifier.loginAsClient(user.id);
        }
      }
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authController.errorMessage ?? 'Erreur de connexion'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
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

          // ── Scrollable content ───────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),

                    // ── Logo + header ──────────────────────────────
                    Column(
                      children: [
                        // Logo badge
                        Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.30,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Image.asset(
                                  'assets/logo/logored.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(
                              duration: 500.ms,
                              curve: Curves.easeOutCubic,
                            )
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1.0, 1.0),
                              duration: 600.ms,
                              curve: Curves.easeOutBack,
                            ),

                        const SizedBox(height: 28),

                        Text(
                              'Bon retour !',
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                                letterSpacing: -0.3,
                                height: 1.1,
                              ),
                              textAlign: TextAlign.center,
                            )
                            .animate(delay: 80.ms)
                            .fadeIn(duration: 450.ms)
                            .slideY(
                              begin: 0.12,
                              end: 0,
                              duration: 450.ms,
                              curve: Curves.easeOutCubic,
                            ),

                        const SizedBox(height: 8),

                        Text(
                              'Connectez-vous pour accéder à vos avis.',
                              style: textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            )
                            .animate(delay: 140.ms)
                            .fadeIn(duration: 450.ms)
                            .slideY(
                              begin: 0.10,
                              end: 0,
                              duration: 450.ms,
                              curve: Curves.easeOutCubic,
                            ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // ── Form card ──────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.45,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: 0.05),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Email field
                          _AnimatedField(
                                label: 'Adresse email',
                                hint: 'vous@exemple.com',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.mail_outline_rounded,
                                isFocused: _emailFocused,
                                onFocusChange: (v) =>
                                    setState(() => _emailFocused = v),
                                colorScheme: colorScheme,
                                textTheme: textTheme,
                                validator: AppValidators.validateEmail,
                              )
                              .animate(delay: 200.ms)
                              .fadeIn(duration: 400.ms)
                              .slideY(
                                begin: 0.08,
                                end: 0,
                                duration: 400.ms,
                                curve: Curves.easeOutCubic,
                              ),

                          const SizedBox(height: 16),

                          // Password field
                          _AnimatedField(
                                label: 'Mot de passe',
                                hint: '••••••••',
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                prefixIcon: Icons.lock_outline_rounded,
                                isFocused: _passwordFocused,
                                onFocusChange: (v) =>
                                    setState(() => _passwordFocused = v),
                                colorScheme: colorScheme,
                                textTheme: textTheme,
                                validator: AppValidators.validatePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              )
                              .animate(delay: 260.ms)
                              .fadeIn(duration: 400.ms)
                              .slideY(
                                begin: 0.08,
                                end: 0,
                                duration: 400.ms,
                                curve: Curves.easeOutCubic,
                              ),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              style: TextButton.styleFrom(
                                foregroundColor: colorScheme.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 8,
                                ),
                                textStyle: textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('Mot de passe oublié ?'),
                            ),
                          ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
                        ],
                      ),
                    ).animate(delay: 180.ms).fadeIn(duration: 500.ms),

                    const SizedBox(height: 20),

                    // ── Primary CTA ────────────────────────────────
                    _PrimaryButton(
                          onPressed: isLoading ? null : _handleLogin,
                          isLoading: isLoading,
                          colorScheme: colorScheme,
                          textTheme: textTheme,
                          label: 'Se connecter',
                        )
                        .animate(delay: 340.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(
                          begin: 0.08,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOutCubic,
                        ),

                    const SizedBox(height: 16),

                    // ── Divider ────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: colorScheme.outline.withValues(alpha: 0.25),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'ou',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: colorScheme.outline.withValues(alpha: 0.25),
                          ),
                        ),
                      ],
                    ).animate(delay: 380.ms).fadeIn(duration: 400.ms),

                    const SizedBox(height: 16),

                    // ── Google button ──────────────────────────────
                    _GoogleButton(
                          onPressed: isLoading ? null : _handleGoogleLogin,
                          isLoading: isLoading,
                          colorScheme: colorScheme,
                          textTheme: textTheme,
                        )
                        .animate(delay: 420.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(
                          begin: 0.08,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOutCubic,
                        ),

                    const SizedBox(height: 32),

                    // ── Register link ──────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Pas encore de compte ?',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/register'),
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            textStyle: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text("S'inscrire"),
                        ),
                      ],
                    ).animate(delay: 460.ms).fadeIn(duration: 400.ms),

                    const SizedBox(height: 24),
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
// Animated form field with focus highlight
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedField extends StatefulWidget {
  const _AnimatedField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.prefixIcon,
    required this.isFocused,
    required this.onFocusChange,
    required this.colorScheme,
    required this.textTheme,
    required this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData prefixIcon;
  final bool isFocused;
  final ValueChanged<bool> onFocusChange;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final FormFieldValidator<String> validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  State<_AnimatedField> createState() => _AnimatedFieldState();
}

class _AnimatedFieldState extends State<_AnimatedField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()
      ..addListener(() => widget.onFocusChange(_focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: widget.isFocused
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
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscureText,
        validator: widget.validator,
        style: widget.textTheme.bodyLarge?.copyWith(color: cs.onSurface),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(
            widget.prefixIcon,
            size: 20,
            color: widget.isFocused ? cs.primary : cs.onSurfaceVariant,
          ),
          suffixIcon: widget.suffixIcon,
          filled: true,
          fillColor: widget.isFocused
              ? cs.primaryContainer.withValues(alpha: 0.20)
              : cs.surfaceContainerHighest.withValues(alpha: 0.50),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: cs.outline.withValues(alpha: 0.15),
              width: 1,
            ),
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
          labelStyle: TextStyle(
            color: widget.isFocused ? cs.primary : cs.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Primary button with loading state
// ─────────────────────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.onPressed,
    required this.isLoading,
    required this.colorScheme,
    required this.textTheme,
    required this.label,
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
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
                    color: colorScheme.onPrimary,
                  ),
                )
              : Text(
                  key: const ValueKey('label'),
                  label,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onPrimary,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Google sign-in button
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({
    required this.onPressed,
    required this.isLoading,
    required this.colorScheme,
    required this.textTheme,
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final cs = colorScheme;
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(
            color: cs.outline.withValues(alpha: 0.30),
            width: 1.5,
          ),
          backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google "G" logo drawn manually to avoid svg asset dependency
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: CustomPaint(painter: _GoogleLogoPainter()),
            ),
            const SizedBox(width: 12),
            Text(
              'Continuer avec Google',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Google "G" logo — four-color arc painter
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Quadrant arcs: Red, Yellow, Green, Blue
    const colors = [
      Color(0xFFEA4335), // top-right → bottom-right (red)
      Color(0xFFFBBC05), // bottom-right → bottom-left (yellow)
      Color(0xFF34A853), // bottom-left → top-left (green)
      Color(0xFF4285F4), // top-left → top-right (blue)
    ];

    const startAngles = [-1.05, 0.52, 2.09, 3.67];
    const sweeps = [1.57, 1.57, 1.57, 1.57];

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    for (var i = 0; i < 4; i++) {
      canvas.drawArc(
        rect,
        startAngles[i],
        sweeps[i],
        false,
        Paint()
          ..color = colors[i]
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt,
      );
    }
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter _) => false;
}
