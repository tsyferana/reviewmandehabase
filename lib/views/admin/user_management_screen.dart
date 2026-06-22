import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_data_service.dart';
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
  bool _isLoading = true;

  List<_UserModel> _allUsers = [];
  List<_UserModel> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_filterUsers);
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final usersData = await SupabaseDataService().getAllUsersAdmin();
      if (mounted) {
        setState(() {
          _allUsers = usersData.map((u) => _UserModel(
            id: u['id'] ?? '',
            name: u['full_name'] ?? 'Sans Nom',
            email: u['email'] ?? '',
            type: u['account_type'] == 'business_owner' ? UserType.business : UserType.client,
            avatar: u['avatar_url'],
            registeredAt: u['created_at'] != null ? DateTime.parse(u['created_at']) : DateTime.now(),
            status: UserStatus.active,
            reviewsCount: 0,
            businessesCount: 0,
          )).toList();
          _filterUsers();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                      backgroundImage: user.avatar != null && user.avatar!.isNotEmpty ? NetworkImage(user.avatar!) : null,
                      child: user.avatar == null || user.avatar!.isEmpty ? const Icon(Icons.person) : null,
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
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                              backgroundImage: user.avatar != null && user.avatar!.isNotEmpty ? NetworkImage(user.avatar!) : null,
                              child: user.avatar == null || user.avatar!.isEmpty ? const Icon(Icons.person) : null,
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
  final String? avatar;
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
