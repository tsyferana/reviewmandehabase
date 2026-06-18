import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_data_service.dart';

enum BusinessApprovalStatus { pending, approved, rejected }

class BusinessApprovalScreen extends StatefulWidget {
  const BusinessApprovalScreen({super.key});

  static const routeName = '/admin/businesses';

  @override
  State<BusinessApprovalScreen> createState() => _BusinessApprovalScreenState();
}

class _BusinessApprovalScreenState extends State<BusinessApprovalScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late List<_BusinessModel> _businesses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBusinesses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinesses() async {
    try {
      final businessesData = await SupabaseDataService().getAllBusinessesAdmin();
      if (mounted) {
        setState(() {
          _businesses = businessesData.map((b) {
            BusinessApprovalStatus parsedStatus;
            switch(b['status']) {
              case 'approved': parsedStatus = BusinessApprovalStatus.approved; break;
              case 'rejected': parsedStatus = BusinessApprovalStatus.rejected; break;
              default: parsedStatus = BusinessApprovalStatus.pending; break;
            }
            
            return _BusinessModel(
              id: b['id'] ?? '',
              name: b['name'] ?? 'Sans Nom',
              category: b['categories']?['name'] ?? 'Non classé',
              ownerName: b['profiles']?['full_name'] ?? 'Inconnu',
              ownerEmail: b['profiles']?['email'] ?? '',
              logo: b['image_url'] ?? 'https://picsum.photos/seed/reviewapp-restaurant/600/420',
              description: b['description'] ?? '',
              address: b['address'] ?? '',
              phone: b['phone'] ?? '',
              email: b['email'] ?? '',
              website: '',
              openingHours: (b['opening_hours'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v.toString())) ?? {},
              photos: (b['gallery_urls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
              submittedAt: b['created_at'] != null ? DateTime.parse(b['created_at']) : DateTime.now(),
              status: parsedStatus,
              rejectionReason: '',
            );
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<_BusinessModel> _getBusinessesByStatus(BusinessApprovalStatus status) {
    return _businesses.where((b) => b.status == status).toList();
  }

  Future<void> _approveBusiness(_BusinessModel business) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Approuver l\'entreprise'),
          content: Text(
            'Approuver "${business.name}"? Elle sera visible publiquement.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Approuver'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await SupabaseDataService().updateBusinessStatusAdmin(business.id, 'approved');
        await _loadBusinesses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${business.name} a été approuvée.'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _rejectBusiness(_BusinessModel business) async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rejeter l\'entreprise'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rejeter "${business.name}"?'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Motif du rejet...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
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
              onPressed: () =>
                  Navigator.pop(context, controller.text.isNotEmpty),
              child: const Text('Rejeter'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && controller.text.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        await SupabaseDataService().updateBusinessStatusAdmin(business.id, 'rejected'); // NOTE: backend currently doesn't store reason
        await _loadBusinesses();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${business.name} a été rejetée.'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showBusinessDetails(_BusinessModel business) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final submissionDate = DateFormat(
      'd MMM yyyy à HH:mm',
      'fr_FR',
    ).format(business.submittedAt);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          business.logo,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              business.name,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              business.category,
                              style: textTheme.labelMedium?.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    business.status ==
                                        BusinessApprovalStatus.pending
                                    ? Colors.orange.withValues(alpha: 0.2)
                                    : business.status ==
                                          BusinessApprovalStatus.approved
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.red.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                business.status ==
                                        BusinessApprovalStatus.pending
                                    ? 'En attente'
                                    : business.status ==
                                          BusinessApprovalStatus.approved
                                    ? 'Approuvée'
                                    : 'Rejetée',
                                style: textTheme.labelSmall?.copyWith(
                                  color:
                                      business.status ==
                                          BusinessApprovalStatus.pending
                                      ? Colors.orange
                                      : business.status ==
                                            BusinessApprovalStatus.approved
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Submission info
                  Text(
                    'Soumis le: $submissionDate',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  Text(
                    'Description',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(business.description, style: textTheme.bodySmall),
                  const SizedBox(height: 20),

                  // Owner info
                  Text(
                    'Propriétaire',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(label: 'Nom', value: business.ownerName),
                  _DetailRow(label: 'Email', value: business.ownerEmail),
                  const SizedBox(height: 20),

                  // Contact info
                  Text(
                    'Coordonnées',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(label: 'Adresse', value: business.address),
                  _DetailRow(label: 'Téléphone', value: business.phone),
                  _DetailRow(label: 'Email', value: business.email),
                  _DetailRow(label: 'Site web', value: business.website),
                  const SizedBox(height: 20),

                  // Opening hours
                  Text(
                    'Horaires d\'ouverture',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...business.openingHours.entries.map((e) {
                    return _DetailRow(label: e.key, value: e.value);
                  }),
                  const SizedBox(height: 20),

                  // Gallery
                  if (business.photos.isNotEmpty) ...[
                    Text(
                      'Galerie',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: business.photos.map((url) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(url, fit: BoxFit.cover),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Rejection reason (if rejected)
                  if (business.status == BusinessApprovalStatus.rejected &&
                      business.rejectionReason.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_rounded,
                                size: 18,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Motif du rejet',
                                style: textTheme.labelMedium?.copyWith(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            business.rejectionReason,
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Actions
                  if (business.status == BusinessApprovalStatus.pending)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _rejectBusiness(business);
                            },
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Rejeter'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.error,
                              side: BorderSide(
                                color: colorScheme.error.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _approveBusiness(business);
                            },
                            icon: const Icon(Icons.check_circle_rounded),
                            label: const Text('Approuver'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Approbation des entreprises'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'En attente', icon: Icon(Icons.hourglass_bottom_rounded)),
            Tab(text: 'Approuvées', icon: Icon(Icons.check_circle_rounded)),
            Tab(text: 'Rejetées', icon: Icon(Icons.cancel_rounded)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildBusinessList(BusinessApprovalStatus.pending),
          _buildBusinessList(BusinessApprovalStatus.approved),
          _buildBusinessList(BusinessApprovalStatus.rejected),
        ],
      ),
    );
  }

  Widget _buildBusinessList(BusinessApprovalStatus status) {
    final businesses = _getBusinessesByStatus(status);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (businesses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == BusinessApprovalStatus.pending
                  ? Icons.inbox_rounded
                  : status == BusinessApprovalStatus.approved
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              status == BusinessApprovalStatus.pending
                  ? 'Aucune entreprise en attente'
                  : status == BusinessApprovalStatus.approved
                  ? 'Aucune entreprise approuvée'
                  : 'Aucune entreprise rejetée',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${businesses.length} entreprise${businesses.length > 1 ? 's' : ''}',
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: businesses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final business = businesses[index];
              final submissionDate = DateFormat(
                'd MMM yyyy',
                'fr_FR',
              ).format(business.submittedAt);

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: InkWell(
                  onTap: () => _showBusinessDetails(business),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            business.logo,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                business.name,
                                style: textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.secondary.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      business.category,
                                      style: textTheme.labelSmall?.copyWith(
                                        color: colorScheme.secondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    submissionDate,
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Propriétaire: ${business.ownerName}',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.04);
            },
          ),
        ],
      ),
    );
  }
}

class _BusinessModel {
  final String id;
  final String name;
  final String category;
  final String ownerName;
  final String ownerEmail;
  final String logo;
  final String description;
  final String address;
  final String phone;
  final String email;
  final String website;
  final Map<String, String> openingHours;
  final List<String> photos;
  final DateTime submittedAt;
  BusinessApprovalStatus status;
  String rejectionReason;

  _BusinessModel({
    required this.id,
    required this.name,
    required this.category,
    required this.ownerName,
    required this.ownerEmail,
    required this.logo,
    required this.description,
    required this.address,
    required this.phone,
    required this.email,
    required this.website,
    required this.openingHours,
    required this.photos,
    required this.submittedAt,
    required this.status,
    required this.rejectionReason,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
