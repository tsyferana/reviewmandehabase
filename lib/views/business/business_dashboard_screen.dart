import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/review_model.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  static const routeName = '/business-dashboard';

  @override
  State<BusinessDashboardScreen> createState() =>
      _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  int _selectedTimePeriod = 7; // 7 or 30 days

  // Mock data
  final String _businessName = 'La Varangue';
  final String _businessLogo =
      'https://picsum.photos/seed/reviewapp-restaurant/600/420';
  final bool _isActive = true;

  final int _totalViews = 2847;
  final int _totalReviews = 128;
  final int _totalFavorites = 456;
  final double _averageRating = 4.8;
  final int _visitorsThisMonth = 1023;
  final double _growthPercentage = 12.5; // Positive = up

  // Mock chart data (views evolution over 7/30 days)
  late List<int> _viewsData;
  late List<String> _daysLabels;

  // Mock review distribution (1-5 stars)
  final Map<int, int> _ratingDistribution = {1: 4, 2: 8, 3: 24, 4: 52, 5: 40};

  // Mock recent reviews
  late List<ReviewModel> _recentReviews;

  @override
  void initState() {
    super.initState();
    _initializeMockData();
  }

  void _initializeMockData() {
    if (_selectedTimePeriod == 7) {
      _daysLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      _viewsData = [120, 180, 150, 220, 280, 350, 280];
    } else {
      _daysLabels = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4', 'Sem 5'];
      _viewsData = [840, 920, 1050, 1100, 950];
    }

    _recentReviews = [
      ReviewModel(
        id: 'review-rc-1',
        businessId: 'biz-001',
        userName: 'Miora R.',
        userPhotoUrl: 'https://i.pravatar.cc/120?img=32',
        rating: 5,
        comment:
            'Service impeccable, plats tres bien presentes et equipe vraiment attentive.',
        photoUrls: const ['https://picsum.photos/seed/review-recent-1/320/240'],
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ReviewModel(
        id: 'review-rc-2',
        businessId: 'biz-001',
        userName: 'Tojo A.',
        userPhotoUrl: 'https://i.pravatar.cc/120?img=12',
        rating: 4.5,
        comment: 'Tres belle adresse pour un diner calme.',
        photoUrls: const [],
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      ReviewModel(
        id: 'review-rc-3',
        businessId: 'biz-001',
        userName: 'Sarah N.',
        userPhotoUrl: 'https://i.pravatar.cc/120?img=47',
        rating: 5,
        comment:
            'Reservation facile, accueil chaleureux et excellente recommandation de menu.',
        photoUrls: const [],
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Paramètres',
            onPressed: () {},
            icon: const Icon(Icons.settings_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with business info
            Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _businessLogo,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _businessName,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _isActive
                                        ? colorScheme.tertiary
                                        : colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isActive
                                      ? 'Actif'
                                      : 'En attente d\'approbation',
                                  style: textTheme.labelMedium?.copyWith(
                                    color: _isActive
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
            const SizedBox(height: 24),

            // Statistics Grid (2 columns)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
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
                  color: Colors.orange,
                ),
                _StatCard(
                  icon: Icons.favorite_rounded,
                  label: 'Favoris',
                  value: '$_totalFavorites',
                  color: Colors.red,
                ),
                _StatCard(
                  icon: Icons.star_rounded,
                  label: 'Note moyenne',
                  value: '$_averageRating',
                  color: Colors.amber,
                ),
                _StatCard(
                  icon: Icons.person_rounded,
                  label: 'Visiteurs ce mois',
                  value: '$_visitorsThisMonth',
                  color: Colors.green,
                ),
                _GrowthCard(
                  percentage: _growthPercentage,
                  isPositive: _growthPercentage >= 0,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Views Evolution Chart
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Évolution des vues',
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
                              _initializeMockData();
                            });
                          },
                          segments: const [
                            ButtonSegment(value: 7, label: Text('7j')),
                            ButtonSegment(value: 30, label: Text('30j')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
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
            const SizedBox(height: 24),

            // Rating Distribution Chart
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Répartition des notes',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
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
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 32,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('$rating', style: textTheme.labelSmall),
                                  Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
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
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 48,
                              child: Text(
                                '$count ($percentage%)',
                                textAlign: TextAlign.right,
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Recent Reviews
            Text(
              'Avis récents',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ..._recentReviews.map((review) {
              final date = DateFormat(
                'd MMM',
                'fr_FR',
              ).format(review.createdAt);
              return _ReviewCard(review: review, date: date);
            }),
            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Actions rapides',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _ActionCard(
                  icon: Icons.edit_rounded,
                  label: 'Modifier profil',
                  onTap: () => context.go('/business/edit'),
                ),
                _ActionCard(
                  icon: Icons.comment_rounded,
                  label: 'Gérer les avis',
                  onTap: () => context.go('/business/reviews'),
                ),
                _ActionCard(
                  icon: Icons.bar_chart_rounded,
                  label: 'Statistiques détaillées',
                  onTap: () => context.go('/business/statistics'),
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

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
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
    final color = isPositive ? Colors.green : Colors.red;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
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
              'Croissance',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${percentage.abs().toStringAsFixed(1)}%',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
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

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(review.userPhotoUrl),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: textTheme.titleSmall?.copyWith(
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
                              color: Colors.amber,
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
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review.comment,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
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

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
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
    );
  }
}
