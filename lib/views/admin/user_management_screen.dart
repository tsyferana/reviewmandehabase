import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

enum UserType { client, business }

enum UserStatus { active, suspended }

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  static const routeName = '/admin/users';

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late TextEditingController _searchController;
  UserType? _selectedType;
  UserStatus? _selectedStatus;
  int _currentPage = 0;

  late List<_UserModel> _allUsers;
  late List<_UserModel> _filteredUsers;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_filterUsers);
    _initializeMockUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initializeMockUsers() {
    _allUsers = [
      _UserModel(
        id: 'user-001',
        name: 'Aina Rajaonarivelo',
        email: 'aina.r@gmail.com',
        type: UserType.business,
        avatar: 'https://i.pravatar.cc/120?img=32',
        registeredAt: DateTime.now().subtract(const Duration(days: 180)),
        status: UserStatus.active,
        reviewsCount: 28,
        businessesCount: 1,
      ),
      _UserModel(
        id: 'user-002',
        name: 'Jean Ralibera',
        email: 'jean.ralibera@email.com',
        type: UserType.client,
        avatar: 'https://i.pravatar.cc/120?img=12',
        registeredAt: DateTime.now().subtract(const Duration(days: 120)),
        status: UserStatus.active,
        reviewsCount: 15,
        businessesCount: 0,
      ),
      _UserModel(
        id: 'user-003',
        name: 'Sarah Nomena',
        email: 'sarah.n@email.com',
        type: UserType.client,
        avatar: 'https://i.pravatar.cc/120?img=47',
        registeredAt: DateTime.now().subtract(const Duration(days: 90)),
        status: UserStatus.active,
        reviewsCount: 8,
        businessesCount: 0,
      ),
      _UserModel(
        id: 'user-004',
        name: 'Rakoto Jean',
        email: 'rakoto.jean@business.mg',
        type: UserType.business,
        avatar: 'https://i.pravatar.cc/120?img=5',
        registeredAt: DateTime.now().subtract(const Duration(days: 60)),
        status: UserStatus.suspended,
        reviewsCount: 0,
        businessesCount: 2,
      ),
      _UserModel(
        id: 'user-005',
        name: 'Miora Ramaholimihaso',
        email: 'miora.r@email.com',
        type: UserType.client,
        avatar: 'https://i.pravatar.cc/120?img=18',
        registeredAt: DateTime.now().subtract(const Duration(days: 45)),
        status: UserStatus.active,
        reviewsCount: 22,
        businessesCount: 0,
      ),
      _UserModel(
        id: 'user-006',
        name: 'Tojo Andrianampoinimerina',
        email: 'tojo.a@email.com',
        type: UserType.client,
        avatar: 'https://i.pravatar.cc/120?img=22',
        registeredAt: DateTime.now().subtract(const Duration(days: 30)),
        status: UserStatus.active,
        reviewsCount: 5,
        businessesCount: 0,
      ),
      _UserModel(
        id: 'user-007',
        name: 'Nicole Business Hub',
        email: 'contact@nicolebiz.mg',
        type: UserType.business,
        avatar: 'https://i.pravatar.cc/120?img=8',
        registeredAt: DateTime.now().subtract(const Duration(days: 25)),
        status: UserStatus.active,
        reviewsCount: 0,
        businessesCount: 3,
      ),
      _UserModel(
        id: 'user-008',
        name: 'Lanto Andrianampoinimerina',
        email: 'lanto.a@email.com',
        type: UserType.client,
        avatar: 'https://i.pravatar.cc/120?img=35',
        registeredAt: DateTime.now().subtract(const Duration(days: 20)),
        status: UserStatus.active,
        reviewsCount: 3,
        businessesCount: 0,
      ),
      _UserModel(
        id: 'user-009',
        name: 'Toile Café',
        email: 'hello@toilecafe.mg',
        type: UserType.business,
        avatar: 'https://i.pravatar.cc/120?img=42',
        registeredAt: DateTime.now().subtract(const Duration(days: 15)),
        status: UserStatus.suspended,
        reviewsCount: 0,
        businessesCount: 1,
      ),
      _UserModel(
        id: 'user-010',
        name: 'Vicky Ramaholimihaso',
        email: 'vicky.r@email.com',
        type: UserType.client,
        avatar: 'https://i.pravatar.cc/120?img=16',
        registeredAt: DateTime.now().subtract(const Duration(days: 10)),
        status: UserStatus.active,
        reviewsCount: 12,
        businessesCount: 0,
      ),
      _UserModel(
        id: 'user-011',
        name: 'Pierre Rakotonirina',
        email: 'pierre.r@email.com',
        type: UserType.client,
        avatar: 'https://i.pravatar.cc/120?img=28',
        registeredAt: DateTime.now().subtract(const Duration(days: 8)),
        status: UserStatus.active,
        reviewsCount: 7,
        businessesCount: 0,
      ),
      _UserModel(
        id: 'user-012',
        name: 'Madagascar Tours',
        email: 'booking@madtours.mg',
        type: UserType.business,
        avatar: 'https://i.pravatar.cc/120?img=10',
        registeredAt: DateTime.now().subtract(const Duration(days: 5)),
        status: UserStatus.active,
        reviewsCount: 0,
        businessesCount: 2,
      ),
      _UserModel(
        id: 'user-013',
        name: 'Emma Andrianampoinimerina',
        email: 'emma.a@email.com',
        type: UserType.client,
        avatar: 'https://i.pravatar.cc/120?img=55',
        registeredAt: DateTime.now().subtract(const Duration(days: 3)),
        status: UserStatus.active,
        reviewsCount: 2,
        businessesCount: 0,
      ),
      _UserModel(
        id: 'user-014',
        name: 'Hotel Paradise',
        email: 'info@hotelparadise.mg',
        type: UserType.business,
        avatar: 'https://i.pravatar.cc/120?img=14',
        registeredAt: DateTime.now().subtract(const Duration(days: 2)),
        status: UserStatus.active,
        reviewsCount: 0,
        businessesCount: 1,
      ),
      _UserModel(
        id: 'user-015',
        name: 'Sophia Ralibera',
        email: 'sophia.r@email.com',
        type: UserType.client,
        avatar: 'https://i.pravatar.cc/120?img=41',
        registeredAt: DateTime.now().subtract(const Duration(hours: 20)),
        status: UserStatus.active,
        reviewsCount: 1,
        businessesCount: 0,
      ),
      _UserModel(
        id: 'user-016',
        name: 'Boutique Chic',
        email: 'boutique@chic.mg',
        type: UserType.business,
        avatar: 'https://i.pravatar.cc/120?img=20',
        registeredAt: DateTime.now().subtract(const Duration(hours: 12)),
        status: UserStatus.active,
        reviewsCount: 0,
        businessesCount: 1,
      ),
      _UserModel(
        id: 'user-017',
        name: 'Marc Razafimandimby',
        email: 'marc.r@email.com',
        type: UserType.client,
        avatar: 'https://i.pravatar.cc/120?img=30',
        registeredAt: DateTime.now().subtract(const Duration(hours: 6)),
        status: UserStatus.suspended,
        reviewsCount: 0,
        businessesCount: 0,
      ),
      _UserModel(
        id: 'user-018',
        name: 'Restaurant Belle Vue',
        email: 'contact@bellevue.mg',
        type: UserType.business,
        avatar: 'https://i.pravatar.cc/120?img=9',
        registeredAt: DateTime.now().subtract(const Duration(hours: 3)),
        status: UserStatus.active,
        reviewsCount: 0,
        businessesCount: 1,
      ),
      _UserModel(
        id: 'user-019',
        name: 'Andrianampoinimerina Rado',
        email: 'rado.a@email.com',
        type: UserType.client,
        avatar: 'https://i.pravatar.cc/120?img=33',
        registeredAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: UserStatus.active,
        reviewsCount: 4,
        businessesCount: 0,
      ),
      _UserModel(
        id: 'user-020',
        name: 'Fitness Pro Gym',
        email: 'info@fitnessgym.mg',
        type: UserType.business,
        avatar: 'https://i.pravatar.cc/120?img=11',
        registeredAt: DateTime.now(),
        status: UserStatus.active,
        reviewsCount: 0,
        businessesCount: 1,
      ),
    ];

    _filterUsers();
  }

  void _filterUsers() {
    _filteredUsers = _allUsers.where((user) {
      final matchesSearch =
          user.name.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ) ||
          user.email.toLowerCase().contains(
            _searchController.text.toLowerCase(),
          );

      final matchesType = _selectedType == null || user.type == _selectedType;
      final matchesStatus =
          _selectedStatus == null || user.status == _selectedStatus;

      return matchesSearch && matchesType && matchesStatus;
    }).toList();

    _currentPage = 0;
    setState(() {});
  }

  Future<void> _toggleUserStatus(_UserModel user) async {
    final newStatus = user.status == UserStatus.active
        ? UserStatus.suspended
        : UserStatus.active;
    final action = newStatus == UserStatus.active ? 'activé' : 'suspendu';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmer l\'action'),
          content: Text(
            'Êtes-vous sûr de vouloir ${action.toLowerCase()} cet utilisateur?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                action.replaceFirst(action[0], action[0].toUpperCase()),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      user.status = newStatus;
      setState(() {});

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Utilisateur $action avec succès.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteUser(_UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer l\'utilisateur'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer ${user.name}? Cette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _allUsers.removeWhere((u) => u.id == user.id);
      _filterUsers();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Utilisateur supprimé avec succès.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showUserDetails(_UserModel user) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final registrationDate = DateFormat(
      'd MMM yyyy',
      'fr_FR',
    ).format(user.registeredAt);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(user.avatar),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            user.email,
                            style: textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: user.status == UserStatus.active
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        user.status == UserStatus.active ? 'Actif' : 'Suspendu',
                        style: textTheme.labelSmall?.copyWith(
                          color: user.status == UserStatus.active
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Details
                Text(
                  'Informations',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Type',
                  value: user.type == UserType.client ? 'Client' : 'Entreprise',
                ),
                _DetailRow(label: 'Email', value: user.email),
                _DetailRow(
                  label: 'Date d\'inscription',
                  value: registrationDate,
                ),
                const SizedBox(height: 20),

                // Statistics
                Text(
                  'Statistiques',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                if (user.type == UserType.client)
                  _DetailRow(
                    label: 'Nombre d\'avis',
                    value: '${user.reviewsCount}',
                  )
                else
                  _DetailRow(
                    label: 'Nombre d\'entreprises',
                    value: '${user.businessesCount}',
                  ),
                const SizedBox(height: 20),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _toggleUserStatus(user);
                        },
                        icon: Icon(
                          user.status == UserStatus.active
                              ? Icons.block_rounded
                              : Icons.check_circle_rounded,
                        ),
                        label: Text(
                          user.status == UserStatus.active
                              ? 'Suspendre'
                              : 'Activer',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteUser(user);
                        },
                        icon: const Icon(Icons.delete_rounded),
                        label: const Text('Supprimer'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final itemsPerPage = 10;
    final totalPages = (_filteredUsers.length / itemsPerPage).ceil();
    final start = _currentPage * itemsPerPage;
    final end = (start + itemsPerPage).clamp(0, _filteredUsers.length);
    final pageUsers = _filteredUsers.sublist(start, end);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des utilisateurs'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou email...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    selected: _selectedType == null,
                    onSelected: (_) => setState(() => _selectedType = null),
                    label: const Text('Tous les types'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: _selectedType == UserType.client,
                    onSelected: (_) =>
                        setState(() => _selectedType = UserType.client),
                    label: const Text('Clients'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: _selectedType == UserType.business,
                    onSelected: (_) =>
                        setState(() => _selectedType = UserType.business),
                    label: const Text('Entreprises'),
                  ),
                  const SizedBox(width: 16),
                  FilterChip(
                    selected: _selectedStatus == null,
                    onSelected: (_) => setState(() => _selectedStatus = null),
                    label: const Text('Tous les statuts'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: _selectedStatus == UserStatus.active,
                    onSelected: (_) =>
                        setState(() => _selectedStatus = UserStatus.active),
                    label: const Text('Actifs'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: _selectedStatus == UserStatus.suspended,
                    onSelected: (_) =>
                        setState(() => _selectedStatus = UserStatus.suspended),
                    label: const Text('Suspendus'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Results count
            Text(
              'Résultats: ${_filteredUsers.length} utilisateurs',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            // Users list
            if (pageUsers.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(
                        Icons.person_off_rounded,
                        size: 48,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aucun utilisateur trouvé',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pageUsers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final user = pageUsers[index];
                  final registrationDate = DateFormat(
                    'd MMM yyyy',
                    'fr_FR',
                  ).format(user.registeredAt);

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: InkWell(
                      onTap: () => _showUserDetails(user),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: NetworkImage(user.avatar),
                            ),
                            const SizedBox(width: 12),

                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user.email,
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme.secondary
                                              .withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          user.type == UserType.client
                                              ? 'Client'
                                              : 'Entreprise',
                                          style: textTheme.labelSmall?.copyWith(
                                            color: colorScheme.secondary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              user.status == UserStatus.active
                                              ? Colors.green.withValues(
                                                  alpha: 0.2,
                                                )
                                              : Colors.red.withValues(
                                                  alpha: 0.2,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          user.status == UserStatus.active
                                              ? 'Actif'
                                              : 'Suspendu',
                                          style: textTheme.labelSmall?.copyWith(
                                            color:
                                                user.status == UserStatus.active
                                                ? Colors.green
                                                : Colors.red,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        registrationDate,
                                        style: textTheme.labelSmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Actions
                            PopupMenuButton<String>(
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'details',
                                  child: Row(
                                    children: const [
                                      Icon(Icons.visibility_rounded, size: 18),
                                      SizedBox(width: 8),
                                      Text('Voir détails'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'toggle',
                                  child: Row(
                                    children: [
                                      Icon(
                                        user.status == UserStatus.active
                                            ? Icons.block_rounded
                                            : Icons.check_circle_rounded,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        user.status == UserStatus.active
                                            ? 'Suspendre'
                                            : 'Activer',
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: const [
                                      Icon(
                                        Icons.delete_rounded,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Supprimer',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'details') {
                                  _showUserDetails(user);
                                } else if (value == 'toggle') {
                                  _toggleUserStatus(user);
                                } else if (value == 'delete') {
                                  _deleteUser(user);
                                }
                              },
                              child: Icon(
                                Icons.more_vert_rounded,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.04);
                },
              ),
            const SizedBox(height: 20),

            // Pagination
            if (totalPages > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage--)
                        : null,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  ...List.generate(totalPages, (i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilledButton(
                        onPressed: () => setState(() => _currentPage = i),
                        style: FilledButton.styleFrom(
                          backgroundColor: _currentPage == i
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: _currentPage == i
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }),
                  IconButton(
                    onPressed: _currentPage < totalPages - 1
                        ? () => setState(() => _currentPage++)
                        : null,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _UserModel {
  final String id;
  final String name;
  final String email;
  final UserType type;
  final String avatar;
  final DateTime registeredAt;
  UserStatus status;
  final int reviewsCount;
  final int businessesCount;

  _UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
    required this.avatar,
    required this.registeredAt,
    required this.status,
    required this.reviewsCount,
    required this.businessesCount,
  });
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
