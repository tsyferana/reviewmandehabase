import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_data_service.dart';

enum ReportType { falseReview, spam, offensive, incorrectInfo }

enum ReportStatus { pending, handled }

class ReportsManagementScreen extends StatefulWidget {
  const ReportsManagementScreen({super.key});

  static const routeName = '/admin/reports';

  @override
  State<ReportsManagementScreen> createState() =>
      _ReportsManagementScreenState();
}

class _ReportsManagementScreenState extends State<ReportsManagementScreen> {
  ReportType? _selectedType;
  ReportStatus? _selectedStatus;

  late List<_ReportModel> _reports = [];
  late List<_ReportModel> _filteredReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final reportsData = await SupabaseDataService().getAllReportsAdmin();
      if (mounted) {
        setState(() {
          _reports = reportsData.map((r) {
            ReportType pType;
            switch(r['report_type']) {
              case 'false_review': pType = ReportType.falseReview; break;
              case 'spam': pType = ReportType.spam; break;
              case 'offensive': pType = ReportType.offensive; break;
              case 'incorrect_info': pType = ReportType.incorrectInfo; break;
              default: pType = ReportType.spam;
            }
            return _ReportModel(
              id: r['id'] ?? '',
              reviewId: r['review_id'] ?? '',
              reviewerId: r['reviews']?['user_id'] ?? '',
              reviewerName: r['reviews']?['profiles']?['full_name'] ?? 'Inconnu',
              reviewerAvatar: r['reviews']?['profiles']?['avatar_url'] ?? 'https://i.pravatar.cc/120',
              businessName: r['reviews']?['businesses']?['name'] ?? 'Inconnu',
              businessLogo: r['reviews']?['businesses']?['image_url'] ?? 'https://picsum.photos/600/420',
              reviewText: r['reviews']?['comment'] ?? '',
              reviewRating: (r['reviews']?['rating'] ?? 0).toDouble(),
              reviewDate: r['reviews']?['created_at'] != null ? DateTime.parse(r['reviews']['created_at']) : DateTime.now(),
              reporterName: r['profiles']?['full_name'] ?? 'Inconnu',
              reporterAvatar: r['profiles']?['avatar_url'] ?? 'https://i.pravatar.cc/120',
              reporterEmail: r['profiles']?['email'] ?? '',
              reportType: pType,
              reason: r['reason'] ?? '',
              reportedAt: r['created_at'] != null ? DateTime.parse(r['created_at']) : DateTime.now(),
              status: r['status'] == 'handled' ? ReportStatus.handled : ReportStatus.pending,
              reporterHistory: [],
            );
          }).toList();
          _filterReports();
          _isLoading = false;
        });
      }
    } catch (e, st) {
      debugPrint('Error loading reports: $e');
      debugPrint('Stack trace: $st');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterReports() {
    _filteredReports = _reports.where((report) {
      final matchesType =
          _selectedType == null || report.reportType == _selectedType;
      final matchesStatus =
          _selectedStatus == null || report.status == _selectedStatus;

      return matchesType && matchesStatus;
    }).toList();

    _filteredReports.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
    setState(() {});
  }

  String _getReportTypeLabel(ReportType type) {
    switch (type) {
      case ReportType.falseReview:
        return 'Faux avis';
      case ReportType.spam:
        return 'Spam';
      case ReportType.offensive:
        return 'Offensant';
      case ReportType.incorrectInfo:
        return 'Info incorrecte';
    }
  }

  Color _getReportTypeColor(ReportType type) {
    switch (type) {
      case ReportType.falseReview:
        return Colors.red;
      case ReportType.spam:
        return Colors.orange;
      case ReportType.offensive:
        return Colors.deepOrange;
      case ReportType.incorrectInfo:
        return Colors.amber;
    }
  }

  Future<void> _deleteReview(_ReportModel report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer l\'avis'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer cet avis de "${report.reviewerName}"? Cette action est irréversible.',
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
      setState(() => _isLoading = true);
      try {
        if (report.reviewerId.isNotEmpty) {
          await SupabaseDataService().createAdminNotification(
            userId: report.reviewerId,
            title: 'Avis supprimé',
            message: 'Votre avis sur "${report.businessName}" a été supprimé par l\'équipe de modération suite à un signalement. Merci de respecter nos conditions d\'utilisation.',
            type: 'report',
          );
        }
        await SupabaseDataService().deleteReviewAdmin(report.reviewId);
        await SupabaseDataService().updateReportStatusAdmin(report.id, 'handled');
        await _loadReports();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avis supprimé avec succès.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _ignoreReport(_ReportModel report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ignorer le signalement'),
          content: const Text(
            'Êtes-vous sûr de vouloir ignorer ce signalement? L\'avis ne sera pas supprimé.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ignorer'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await SupabaseDataService().updateReportStatusAdmin(report.id, 'handled');
        await _loadReports();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Signalement marqué comme traité.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _warnUser(_ReportModel report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Avertir l\'utilisateur'),
          content: Text(
            'Envoyer un avertissement à "${report.reviewerName}"? Un email sera envoyé.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Avertir'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        if (report.reviewerId.isNotEmpty) {
          await SupabaseDataService().createAdminNotification(
            userId: report.reviewerId,
            title: 'Avertissement de modération',
            message: 'Votre avis sur "${report.businessName}" a été signalé. Nous avons décidé de le conserver pour l\'instant, mais merci de veiller à respecter nos règles.',
            type: 'report',
          );
        }
        await SupabaseDataService().updateReportStatusAdmin(report.id, 'handled');
        await _loadReports();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Avertissement envoyé à ${report.reviewerName}.'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showReportDetails(_ReportModel report) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final reviewDate = DateFormat(
      'd MMM yyyy',
      'fr_FR',
    ).format(report.reviewDate);
    final reportDate = DateFormat(
      'd MMM yyyy à HH:mm',
      'fr_FR',
    ).format(report.reportedAt);

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
                  // Report info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getReportTypeColor(
                        report.reportType,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getReportTypeColor(
                          report.reportType,
                        ).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.flag_rounded,
                              size: 18,
                              color: _getReportTypeColor(report.reportType),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getReportTypeLabel(report.reportType),
                              style: textTheme.labelMedium?.copyWith(
                                color: _getReportTypeColor(report.reportType),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: report.status == ReportStatus.pending
                                    ? Colors.orange.withValues(alpha: 0.2)
                                    : Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                report.status == ReportStatus.pending
                                    ? 'En attente'
                                    : 'Traité',
                                style: textTheme.labelSmall?.copyWith(
                                  color: report.status == ReportStatus.pending
                                      ? Colors.orange
                                      : Colors.green,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Raison: ${report.reason}',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Reviewed business
                  Text(
                    'Entreprise concernée',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          report.businessLogo,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.businessName,
                              style: textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Signalé le: $reportDate',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Review details
                  Text(
                    'Avis signalé',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundImage: NetworkImage(
                                  report.reviewerAvatar,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      report.reviewerName,
                                      style: textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      reviewDate,
                                      style: textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  ...List.generate(
                                    5,
                                    (i) => Icon(
                                      i < report.reviewRating.toInt()
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      size: 14,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(report.reviewText, style: textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Reporter info
                  Text(
                    'Signalé par',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(report.reporterAvatar),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.reporterName,
                              style: textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              report.reporterEmail,
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Historique: ${report.reporterHistory.length} signalement${report.reporterHistory.length != 1 ? 's' : ''}',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Actions
                  if (report.status == ReportStatus.pending)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteReview(report);
                          },
                          icon: const Icon(Icons.delete_rounded),
                          label: const Text('Supprimer l\'avis'),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _warnUser(report);
                          },
                          icon: const Icon(Icons.warning_rounded),
                          label: const Text('Avertir l\'utilisateur'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _ignoreReport(report);
                          },
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Ignorer le signalement'),
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
    final isTablet = MediaQuery.of(context).size.width >= 900;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final pendingCount = _reports
        .where((r) => r.status == ReportStatus.pending)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des signalements'),
        centerTitle: false,
        actions: [
          if (pendingCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Badge(
                  label: Text('$pendingCount'),
                  child: const Icon(Icons.flag_rounded),
                ),
              ),
            )
          else
            const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    selected: _selectedType == ReportType.falseReview,
                    onSelected: (_) =>
                        setState(() => _selectedType = ReportType.falseReview),
                    label: const Text('Faux avis'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: _selectedType == ReportType.spam,
                    onSelected: (_) =>
                        setState(() => _selectedType = ReportType.spam),
                    label: const Text('Spam'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: _selectedType == ReportType.offensive,
                    onSelected: (_) =>
                        setState(() => _selectedType = ReportType.offensive),
                    label: const Text('Offensant'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: _selectedType == ReportType.incorrectInfo,
                    onSelected: (_) => setState(
                      () => _selectedType = ReportType.incorrectInfo,
                    ),
                    label: const Text('Info incorrecte'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    selected: _selectedStatus == null,
                    onSelected: (_) => setState(() => _selectedStatus = null),
                    label: const Text('Tous les statuts'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: _selectedStatus == ReportStatus.pending,
                    onSelected: (_) =>
                        setState(() => _selectedStatus = ReportStatus.pending),
                    label: const Text('En attente'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: _selectedStatus == ReportStatus.handled,
                    onSelected: (_) =>
                        setState(() => _selectedStatus = ReportStatus.handled),
                    label: const Text('Traités'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Results count
            Text(
              'Résultats: ${_filteredReports.length} signalement${_filteredReports.length != 1 ? 's' : ''}',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            // Reports list
            if (_filteredReports.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        size: 48,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aucun signalement',
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
                itemCount: _filteredReports.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final report = _filteredReports[index];
                  final reportDate = DateFormat(
                    'd MMM',
                    'fr_FR',
                  ).format(report.reportedAt);

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: report.status == ReportStatus.pending
                            ? _getReportTypeColor(
                                report.reportType,
                              ).withValues(alpha: 0.5)
                            : colorScheme.outlineVariant,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => _showReportDetails(report),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _getReportTypeColor(
                                      report.reportType,
                                    ).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.flag_rounded,
                                    color: _getReportTypeColor(
                                      report.reportType,
                                    ),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Avis de "${report.reviewerName}" - ${report.businessName}',
                                        style: textTheme.labelLarge?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _getReportTypeLabel(report.reportType),
                                        style: textTheme.labelSmall?.copyWith(
                                          color: _getReportTypeColor(
                                            report.reportType,
                                          ),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: report.status == ReportStatus.pending
                                        ? Colors.orange.withValues(alpha: 0.2)
                                        : Colors.green.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    report.status == ReportStatus.pending
                                        ? 'En attente'
                                        : 'Traité',
                                    style: textTheme.labelSmall?.copyWith(
                                      color:
                                          report.status == ReportStatus.pending
                                          ? Colors.orange
                                          : Colors.green,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Review excerpt
                            Text(
                              report.reviewText,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),

                            // Footer
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundImage: NetworkImage(
                                        report.reporterAvatar,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      report.reporterName,
                                      style: textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  reportDate,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
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
      ),
    );
  }
}

class _ReportModel {
  final String id;
  final String reviewId;
  final String reviewerId;
  final String reviewerName;
  final String reviewerAvatar;
  final String businessName;
  final String businessLogo;
  final String reviewText;
  final double reviewRating;
  final DateTime reviewDate;
  final String reporterName;
  final String reporterAvatar;
  final String reporterEmail;
  final ReportType reportType;
  final String reason;
  final DateTime reportedAt;
  ReportStatus status;
  final List<String> reporterHistory;

  _ReportModel({
    required this.id,
    required this.reviewId,
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewerAvatar,
    required this.businessName,
    required this.businessLogo,
    required this.reviewText,
    required this.reviewRating,
    required this.reviewDate,
    required this.reporterName,
    required this.reporterAvatar,
    required this.reporterEmail,
    required this.reportType,
    required this.reason,
    required this.reportedAt,
    required this.status,
    required this.reporterHistory,
  });
}
