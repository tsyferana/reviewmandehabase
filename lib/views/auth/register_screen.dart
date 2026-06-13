import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/auth_controller.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import '../../routes/app_router.dart';

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
  late final AuthController _authController;

  MockAccountType _accountType = MockAccountType.client;
  bool _acceptTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _authController = AuthController(AuthRepository());
    _authController.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _authController
      ..removeListener(_onAuthStateChanged)
      ..dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (mounted) {
      setState(() {});
    }
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

    final isRegistered = await _authController.register(
      fullName: _fullNameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      password: _passwordController.text,
      accountType: _accountType,
    );

    if (!mounted) return;

    if (isRegistered) {
      if (_accountType == MockAccountType.businessOwner) {
        ref.read(authStateProvider.notifier).loginAsBusiness('new-biz-001');
      } else {
        ref.read(authStateProvider.notifier).loginAsClient('new-user-001');
      }
      context.go('/home');
      return;
    }

    final message =
        _authController.errorMessage ?? 'Impossible de creer le compte.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _authController.isLoading
              ? null
              : () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Creer un compte',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rejoignez ReviewApp pour decouvrir, noter et sauvegarder vos lieux favoris.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SegmentedButton<MockAccountType>(
                      segments: const [
                        ButtonSegment(
                          value: MockAccountType.client,
                          icon: Icon(Icons.person_outline_rounded),
                          label: Text('Client'),
                        ),
                        ButtonSegment(
                          value: MockAccountType.businessOwner,
                          icon: Icon(Icons.storefront_rounded),
                          label: Text('Proprietaire'),
                        ),
                      ],
                      selected: {_accountType},
                      onSelectionChanged: _authController.isLoading
                          ? null
                          : (selection) {
                              setState(() => _accountType = selection.first);
                            },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _fullNameController,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(
                        labelText: 'Nom complet',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: _validateRequired,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                        border: OutlineInputBorder(),
                      ),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      decoration: const InputDecoration(
                        labelText: 'Telephone',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Afficher le mot de passe'
                              : 'Masquer le mot de passe',
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                        ),
                      ),
                      validator: _validatePassword,
                    ),
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
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _obscureConfirmPassword
                              ? 'Afficher la confirmation'
                              : 'Masquer la confirmation',
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                        ),
                      ),
                      validator: _validatePasswordConfirmation,
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      value: _acceptTerms,
                      onChanged: _authController.isLoading
                          ? null
                          : (value) {
                              setState(() => _acceptTerms = value ?? false);
                            },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'J’accepte les conditions d’utilisation',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _authController.isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                      ),
                      child: AnimatedSwitcher(
                        duration: 180.ms,
                        child: _authController.isLoading
                            ? const SizedBox(
                                key: ValueKey('register-loading'),
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                ),
                              )
                            : const Text(
                                'S’inscrire',
                                key: ValueKey('register-label'),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Deja inscrit ?', style: textTheme.bodyMedium),
                        TextButton(
                          onPressed: _authController.isLoading
                              ? null
                              : () => context.go('/login'),
                          child: const Text('Se connecter'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 420.ms, curve: Curves.easeOutCubic);
  }

  String? _validateRequired(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Ce champ est requis.';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Veuillez saisir votre email.';
    }

    final isEmailValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!isEmailValid) {
      return 'Veuillez saisir un email valide.';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';

    if (phone.isEmpty) {
      return 'Veuillez saisir votre telephone.';
    }

    final isPhoneValid = RegExp(r'^\+?[0-9\s().-]{8,}$').hasMatch(phone);
    if (!isPhoneValid) {
      return 'Veuillez saisir un numero de telephone valide.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Veuillez saisir votre mot de passe.';
    }

    if (password.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caracteres.';
    }

    return null;
  }

  String? _validatePasswordConfirmation(String? value) {
    final confirmation = value ?? '';

    if (confirmation.isEmpty) {
      return 'Veuillez confirmer votre mot de passe.';
    }

    if (confirmation != _passwordController.text) {
      return 'Les mots de passe ne correspondent pas.';
    }

    return null;
  }
}
