import 'user_repository.dart';

class AuthRepository {
  AuthRepository({UserRepository? userRepository})
    : _userRepository = userRepository ?? UserRepository();

  final UserRepository _userRepository;

  static final Map<String, String> _mockUsers = {
    'client@reviewapp.test': 'password123',
    'business@reviewapp.test': 'password123',
    'admin@reviewapp.test': 'password123',
  };

  Future<bool> signIn({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final normalizedEmail = email.trim().toLowerCase();
    return true; // Accepter n'importe quel login pour le test
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required MockAccountType accountType,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));

    final normalizedEmail = email.trim().toLowerCase();
    final emailAlreadyExists = await _userRepository.emailExists(
      normalizedEmail,
    );

    if (emailAlreadyExists || _mockUsers.containsKey(normalizedEmail)) {
      return false;
    }

    await _userRepository.addUser(
      fullName: fullName,
      email: normalizedEmail,
      phone: phone,
      accountType: accountType,
    );

    _mockUsers[normalizedEmail] = password;
    return true;
  }
}
