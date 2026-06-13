enum MockAccountType {
  client,
  businessOwner,
}

class MockUserRecord {
  const MockUserRecord({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.accountType,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final MockAccountType accountType;
}

class UserRepository {
  static final List<MockUserRecord> _users = [
    const MockUserRecord(
      id: 'user-client-001',
      fullName: 'Client Demo',
      email: 'client@reviewapp.test',
      phone: '+33123456789',
      accountType: MockAccountType.client,
    ),
    const MockUserRecord(
      id: 'user-business-001',
      fullName: 'Business Owner Demo',
      email: 'business@reviewapp.test',
      phone: '+33123456780',
      accountType: MockAccountType.businessOwner,
    ),
    const MockUserRecord(
      id: 'user-admin-001',
      fullName: 'Admin Demo',
      email: 'admin@reviewapp.test',
      phone: '+33123456781',
      accountType: MockAccountType.client,
    ),
  ];

  Future<bool> emailExists(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));

    final normalizedEmail = email.trim().toLowerCase();
    return _users.any((user) => user.email.toLowerCase() == normalizedEmail);
  }

  Future<MockUserRecord> addUser({
    required String fullName,
    required String email,
    required String phone,
    required MockAccountType accountType,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final user = MockUserRecord(
      id: 'user-${_users.length + 1}',
      fullName: fullName.trim(),
      email: email.trim().toLowerCase(),
      phone: phone.trim(),
      accountType: accountType,
    );

    _users.add(user);
    return user;
  }
}
