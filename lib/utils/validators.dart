class AppValidators {
  static String? validateRequired(String? value, {String message = 'Ce champ est requis'}) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez saisir votre email.';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Veuillez saisir un email valide.';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez saisir un numéro de téléphone.';
    }
    final phoneRegex = RegExp(r'^\d{10}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Le numéro doit contenir exactement 10 chiffres.';
    }
    return null;
  }

  static String? validatePassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir un mot de passe.';
    }
    if (value.length < minLength) {
      return 'Au moins $minLength caractères requis.';
    }
    return null;
  }

  static String? validateMatch(String? value, String? matchValue, {String message = 'Les mots de passe ne correspondent pas.'}) {
    if (value != matchValue) {
      return message;
    }
    return null;
  }
}
