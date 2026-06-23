import 'package:review_app/utils/couleur.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/review_model.dart';
import '../../services/supabase_data_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  static const routeName = '/business-dashboard';

  @override
  State<BusinessDashboardScreen> createState() =>
      _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  int _selectedTimePeriod = 7; // 7 or 30 days

  bool _isLoading = true;
  Map<String, dynamic>? _business;

  int _totalViews = 0;
  int _totalReviews = 0;
  int _totalFavorites = 0;
  double _averageRating = 0.0;
  int _visitorsThisMonth = 0;
  double _growthPercentage = 0.0; 

  // Mock chart data (views evolution over 7/30 days)
  late List<int> _viewsData;
  late List<String> _daysLabels;

  // Real review distribution (1-5 stars)
  Map<int, int> _ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

  // Recent reviews
  List<ReviewModel> _recentReviews = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _updateChartData(); // Keep mock chart for now
  }

  void _updateChartData() {
    if (_selectedTimePeriod == 7) {
      _daysLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      _viewsData = [120, 180, 150, 220, 280, 350, 280];
    } else {
      _daysLabels = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4', 'Sem 5'];
      _viewsData = [840, 920, 1050, 1100, 950];
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final biz = await SupabaseDataService().getUserBusiness();
      if (biz != null) {
        _business = biz;
        final reviews = await SupabaseDataService().getBusinessReviews(biz['id']);
        
        final favoritesResponse = await Supabase.instance.client
            .from('favorites')
            .select('id')
            .eq('business_id', biz['id']);
            
        _totalFavorites = favoritesResponse.length;
        
        final viewsResponse = await Supabase.instance.client
            .from('business_views')
            .select('id')
            .eq('business_id', biz['id']);
            
        _totalViews = viewsResponse.length;
        
        _totalReviews = reviews.length;
        if (reviews.isNotEmpty) {
          double sum = 0;
          _ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
          
          for (var r in reviews) {
            final rating = r['rating'] as num;
            sum += rating;
            final intRating = rating.round();
            if (_ratingDistribution.containsKey(intRating)) {
              _ratingDistribution[intRating] = _ratingDistribution[intRating]! + 1;
            }
          }
          _averageRating = sum / reviews.length;
          
          _recentReviews = reviews.take(5).map((r) => ReviewModel(
            id: r['id'],
            businessId: r['business_id'],
            userId: r['user_id'],
            rating: (r['rating'] as num).toDouble(),
            comment: r['comment'] ?? '',
            createdAt: DateTime.parse(r['created_at']),
            userName: r['profiles']?['full_name'] ?? 'Utilisateur',
            userPhotoUrl: r['profiles']?['avatar_url'],
            photoUrls: const [],
          )).toList();
        }
      }
    } catch (e) {
      debugPrint('Error loading business: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    if (_business == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: const Center(child: Text('Impossible de charger votre entreprise.')),
      );
    }

    final String businessName = _business!['name'] ?? 'Mon entreprise';
    final String businessLogo = _business!['image_url'] ?? 'https://picsum.photos/seed/reviewapp-restaurant/600/420';
    final bool isActive = _business!['status'] == 'approved';

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/profile');
              }
            },
            tooltip: 'Retour au profil',
          ),
          title: const Text('Mon Entreprise'),
          centerTitle: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Aperçu', icon: Icon(Icons.analytics_outlined)),
              Tab(text: 'Avis', icon: Icon(Icons.star_outline_rounded)),
              Tab(text: 'Gestion', icon: Icon(Icons.inventory_2_outlined)),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: 'Options',
              onSelected: (value) async {
                if (value == 'switch_client') {
                  // Revenir en mode client
                  await SupabaseDataService().updateAccountType('client');
                  if (context.mounted) {
                    context.go('/home');
                  }
                } else if (value == 'settings') {
                  context.push('/business/edit');
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'settings',
                  child: ListTile(
                    leading: Icon(Icons.settings_rounded),
                    title: Text('Paramètres'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'switch_client',
                  child: ListTile(
                    leading: Icon(Icons.person_rounded),
                    title: Text('Passer en mode client'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: TabBarView(
          children: [
            // TAB 1: OVERVIEW
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                businessLogo,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 80,
                                  height: 80,
                                  color: colorScheme.surfaceContainerHighest,
                                  child: const Icon(Icons.store),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    businessName,
                                    style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? colorScheme.tertiary
                                              : colorScheme.errorContainer,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isActive
                                            ? 'Actif'
                                            : 'En attente d\'approbation',
                                        style: textTheme.labelMedium?.copyWith(
                                          color: isActive
                                              ? colorScheme.onTertiary
                                              : colorScheme.onErrorContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        size: 18,
                                        color: colorScheme.secondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$_averageRating ($_totalReviews avis)',
                                        style: textTheme.labelMedium,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 420.ms)
                      .scale(
                        begin: const Offset(0.96, 0.96),
                        end: const Offset(1, 1),
                        duration: 420.ms,
                      ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.9,
                    children: [
                      _StatCard(
                        icon: Icons.visibility_rounded,
                        label: 'Vues totales',
                        value: '$_totalViews',
                        color: Colors.blue,
                      ),
                      _StatCard(
                        icon: Icons.rate_review_rounded,
                        label: 'Avis',
                        value: '$_totalReviews',
                        color: AppColors.warning,
                      ),
                      _StatCard(
                        icon: Icons.favorite_rounded,
                        label: 'Favoris',
                        value: '$_totalFavorites',
                        color: AppColors.error,
                      ),
                      _StatCard(
                        icon: Icons.star_rounded,
                        label: 'Note moyenne',
                        value: '$_averageRating',
                        color: AppColors.starRating,
                      ),
                      _StatCard(
                        icon: Icons.person_rounded,
                        label: 'Visiteurs ce mois',
                        value: '$_visitorsThisMonth',
                        color: AppColors.success,
                      ),
                      _GrowthCard(
                        percentage: _growthPercentage,
                        isPositive: _growthPercentage >= 0,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Fréquentation',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SegmentedButton<int>(
                                selected: {_selectedTimePeriod},
                                showSelectedIcon: false,
                                onSelectionChanged: (selection) {
                                  setState(() {
                                    _selectedTimePeriod = selection.first;
                                    _updateChartData();
                                  });
                                },
                                segments: const [
                                  ButtonSegment(value: 7, label: Text('7J')),
                                  ButtonSegment(value: 30, label: Text('30J')),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _SimpleLineChart(data: _viewsData),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: _daysLabels.asMap().entries.map((entry) {
                              return Flexible(
                                child: Text(
                                  entry.value,
                                  textAlign: TextAlign.center,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // TAB 2: REVIEWS
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Répartition des notes',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...[5, 4, 3, 2, 1].map((rating) {
                            final count = _ratingDistribution[rating] ?? 0;
                            final total = _ratingDistribution.values.fold<int>(
                              0,
                              (a, b) => a + b,
                            );
                            final percentage = total > 0
                                ? (count / total * 100).toStringAsFixed(0)
                                : '0';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 32,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          '$rating',
                                          style: textTheme.labelSmall,
                                        ),
                                        const Icon(
                                          Icons.star_rounded,
                                          size: 14,
                                          color: AppColors.starRating,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: total > 0 ? count / total : 0,
                                        minHeight: 8,
                                        backgroundColor:
                                            colorScheme.surfaceContainerHighest,
                                        valueColor: AlwaysStoppedAnimation(
                                          Color.lerp(
                                            colorScheme.error,
                                            colorScheme.tertiary,
                                            rating / 5,
                                          )!,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$percentage%',
                                    style: textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._recentReviews.map((review) {
                    final date = DateFormat(
                      'd MMM',
                      'fr_FR',
                    ).format(review.createdAt);
                    return _ReviewCard(review: review, date: date);
                  }),
                ],
              ),
            ),

            // TAB 3: ACTIONS & MANAGEMENT
            GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _ActionCard(
                  icon: Icons.edit_rounded,
                  label: 'Modifier profil',
                  onTap: () => context.push('/business/edit'),
                ),
                _ActionCard(
                  icon: Icons.comment_rounded,
                  label: 'Gérer les avis',
                  onTap: () => context.push('/business/reviews'),
                ),
                _ActionCard(
                  icon: Icons.bar_chart_rounded,
                  label: 'Statistiques',
                  onTap: () => context.push('/business/statistics'),
                ),
                _ActionCard(
                  icon: Icons.settings_rounded,
                  label: 'Paramètres',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: 0.10),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.18),
                    color.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            FittedBox(
              child: Text(
                value,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrowthCard extends StatelessWidget {
  const _GrowthCard({required this.percentage, required this.isPositive});

  final double percentage;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = isPositive ? AppColors.success : AppColors.error;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.18),
                    color.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isPositive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${percentage.abs().toStringAsFixed(1)}%',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Croissance',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleLineChart extends StatelessWidget {
  const _SimpleLineChart({required this.data});

  final List<int> data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxValue = data.reduce((a, b) => a > b ? a : b).toDouble();
    const chartHeight = 120.0;

    return CustomPaint(
      painter: _LineChartPainter(
        data: data,
        maxValue: maxValue,
        color: colorScheme.primary,
        backgroundColor: colorScheme.surfaceContainerHighest,
      ),
      size: Size(double.infinity, chartHeight),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.data,
    required this.maxValue,
    required this.color,
    required this.backgroundColor,
  });

  final List<int> data;
  final double maxValue;
  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 1;

    // Draw grid lines
    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Calculate points
    final points = <Offset>[];
    final width = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = width * i;
      final y = size.height - (data[i] / maxValue * size.height);
      points.add(Offset(x, y));
    }

    // Draw filled area under line
    if (points.isNotEmpty) {
      final path = Path()..moveTo(points.first.dx, size.height);
      for (final point in points) {
        path.lineTo(point.dx, point.dy);
      }
      path.lineTo(points.last.dx, size.height);
      path.close();
      canvas.drawPath(path, fillPaint);
    }

    // Draw line
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    // Draw dots
    for (final point in points) {
      canvas.drawCircle(point, 4, paint);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) => false;
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, required this.date});

  final ReviewModel review;
  final String date;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(review.userPhotoUrl),
                    backgroundColor: colorScheme.primaryContainer,
                    onBackgroundImageError: (_, __) {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < review.rating.toInt()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 14,
                              color: AppColors.starRating,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            date,
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.reply_rounded, size: 16),
                  label: const Text('Répondre'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  child: Text(
                    '"',
                    style: TextStyle(
                      fontSize: 32,
                      height: 0.8,
                      color: colorScheme.primary.withValues(alpha: 0.10),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    review.comment,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.secondaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: colorScheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
