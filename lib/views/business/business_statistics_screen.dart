import 'package:flutter/material.dart';

class BusinessStatisticsScreen extends StatefulWidget {
  const BusinessStatisticsScreen({super.key});

  static const routeName = '/business/statistics';

  @override
  State<BusinessStatisticsScreen> createState() =>
      _BusinessStatisticsScreenState();
}

class _BusinessStatisticsScreenState extends State<BusinessStatisticsScreen> {
  int _selectedPeriod = 7; // 7, 30, 90, 365 days

  // Mock data structures
  late Map<int, List<int>> _viewsData;
  late Map<int, List<int>> _reviewsData;
  late Map<int, List<String>> _daysLabels;
  late Map<int, Map<String, int>> _trafficSources;
  late Map<int, Map<int, int>> _ratingDistribution;

  // Summary stats
  late Map<int, _SummaryStats> _summaryStats;

  @override
  void initState() {
    super.initState();
    _initializeMockData();
  }

  void _initializeMockData() {
    _viewsData = {
      7: [120, 180, 150, 220, 280, 350, 280],
      30: [
        850,
        920,
        780,
        1050,
        1100,
        950,
        1200,
        880,
        1050,
        1100,
        950,
        1200,
        880,
        1050,
        1100,
        950,
        1200,
        880,
        1050,
        1100,
        950,
        1200,
        880,
        1050,
        1100,
        950,
        1200,
        880,
        1050,
        1100,
        950,
      ],
      90: [
        5200,
        5800,
        5100,
        6200,
        6500,
        5800,
        6200,
        5100,
        6200,
        6500,
        5800,
        6200,
        5100,
      ],
      365: [
        18200,
        19500,
        17800,
        21500,
        22100,
        19800,
        21500,
        20200,
        19800,
        21500,
        22100,
        19800,
      ],
    };

    _reviewsData = {
      7: [8, 12, 10, 15, 18, 22, 19],
      30: [
        55,
        62,
        48,
        70,
        75,
        64,
        82,
        58,
        70,
        75,
        64,
        82,
        58,
        70,
        75,
        64,
        82,
        58,
        70,
        75,
        64,
        82,
        58,
        70,
        75,
        64,
        82,
        58,
        70,
        75,
      ],
      90: [285, 325, 275, 350, 385, 325, 360, 285, 325, 275, 350, 385, 325],
      365: [
        1250,
        1380,
        1180,
        1520,
        1650,
        1420,
        1580,
        1320,
        1450,
        1280,
        1520,
        1680,
      ],
    };

    _daysLabels = {
      7: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'],
      30: List.generate(30, (i) => '${i + 1}'),
      90: List.generate(13, (i) => 'S${i + 1}'),
      365: [
        'Jan',
        'Fev',
        'Mar',
        'Avr',
        'Mai',
        'Jui',
        'Juil',
        'Aou',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ],
    };

    _trafficSources = {
      7: {'Recherche': 45, 'Carte': 30, 'Recommandations': 20, 'Direct': 5},
      30: {'Recherche': 48, 'Carte': 28, 'Recommandations': 18, 'Direct': 6},
      90: {'Recherche': 50, 'Carte': 25, 'Recommandations': 20, 'Direct': 5},
      365: {'Recherche': 52, 'Carte': 23, 'Recommandations': 19, 'Direct': 6},
    };

    _ratingDistribution = {
      7: {1: 1, 2: 2, 3: 8, 4: 18, 5: 15},
      30: {1: 4, 2: 8, 3: 24, 4: 52, 5: 40},
      90: {1: 8, 2: 18, 3: 65, 4: 145, 5: 149},
      365: {1: 28, 2: 62, 3: 250, 4: 580, 5: 630},
    };

    _summaryStats = {
      7: _SummaryStats(
        totalViews: 1580,
        totalReviews: 84,
        averageRating: 4.7,
        conversionRate: 5.3,
      ),
      30: _SummaryStats(
        totalViews: 7460,
        totalReviews: 423,
        averageRating: 4.6,
        conversionRate: 5.7,
      ),
      90: _SummaryStats(
        totalViews: 23450,
        totalReviews: 1385,
        averageRating: 4.65,
        conversionRate: 5.9,
      ),
      365: _SummaryStats(
        totalViews: 95200,
        totalReviews: 5880,
        averageRating: 4.68,
        conversionRate: 6.2,
      ),
    };
  }

  Future<void> _exportPDF() async {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.file_download_rounded),
          title: const Text('Exporter en PDF'),
          content: const Text(
            'Téléchargement du rapport détaillé des statistiques en cours...',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PDF exporté avec succès !'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Télécharger'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final stats = _summaryStats[_selectedPeriod]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques détaillées'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Exporter en PDF',
            onPressed: _exportPDF,
            icon: const Icon(Icons.file_download_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            SegmentedButton<int>(
              selected: {_selectedPeriod},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                setState(() => _selectedPeriod = selection.first);
              },
              segments: const [
                ButtonSegment(value: 7, label: Text('7 jours')),
                ButtonSegment(value: 30, label: Text('30 jours')),
                ButtonSegment(value: 90, label: Text('3 mois')),
                ButtonSegment(value: 365, label: Text('1 an')),
              ],
            ),
            const SizedBox(height: 20),

            // Summary Cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _SummaryCard(
                  icon: Icons.visibility_rounded,
                  label: 'Vues totales',
                  value: '${stats.totalViews}',
                  color: Colors.blue,
                ),
                _SummaryCard(
                  icon: Icons.rate_review_rounded,
                  label: 'Avis totaux',
                  value: '${stats.totalReviews}',
                  color: Colors.orange,
                ),
                _SummaryCard(
                  icon: Icons.star_rounded,
                  label: 'Note moyenne',
                  value: stats.averageRating.toStringAsFixed(2),
                  color: Colors.amber,
                ),
                _SummaryCard(
                  icon: Icons.trending_up_rounded,
                  label: 'Conversion favoris',
                  value: '${stats.conversionRate.toStringAsFixed(1)}%',
                  color: Colors.green,
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
                    Text(
                      'Évolution des vues',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SimpleLineChart(
                      data: _viewsData[_selectedPeriod]!,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 24,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _daysLabels[_selectedPeriod]!
                            .asMap()
                            .entries
                            .map((entry) {
                              return SizedBox(
                                width: 60,
                                child: Text(
                                  entry.value,
                                  textAlign: TextAlign.center,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Reviews Evolution Chart
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
                      'Évolution des avis',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SimpleLineChart(
                      data: _reviewsData[_selectedPeriod]!,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 24,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _daysLabels[_selectedPeriod]!
                            .asMap()
                            .entries
                            .map((entry) {
                              return SizedBox(
                                width: 60,
                                child: Text(
                                  entry.value,
                                  textAlign: TextAlign.center,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Traffic Sources Bar Chart
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
                      'Répartition par source de trafic',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ..._trafficSources[_selectedPeriod]!.entries.map((entry) {
                      final percentage = entry.value;
                      final label = entry.key;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(label, style: textTheme.labelMedium),
                                Text(
                                  '$percentage%',
                                  style: textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                minHeight: 10,
                                backgroundColor:
                                    colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation(
                                  _getTrafficSourceColor(label),
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
                      final count =
                          _ratingDistribution[_selectedPeriod]![rating] ?? 0;
                      final total = _ratingDistribution[_selectedPeriod]!.values
                          .fold<int>(0, (a, b) => a + b);
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
                              width: 60,
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

            // Key Insights
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
                      children: [
                        Icon(
                          Icons.insights_rounded,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Points clés',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _InsightItem(
                      icon: Icons.trending_up_rounded,
                      text:
                          'Croissance des vues : +${(stats.totalViews * 0.15).toStringAsFixed(0)} par rapport à la période précédente',
                    ),
                    const SizedBox(height: 10),
                    _InsightItem(
                      icon: Icons.star_rounded,
                      text:
                          'Votre note moyenne (${stats.averageRating}) reste stable au-dessus de 4.5 étoiles',
                    ),
                    const SizedBox(height: 10),
                    _InsightItem(
                      icon: Icons.search_rounded,
                      text:
                          'La recherche est votre principal source de trafic (${_trafficSources[_selectedPeriod]!['Recherche']}%)',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTrafficSourceColor(String source) {
    switch (source) {
      case 'Recherche':
        return Colors.blue;
      case 'Carte':
        return Colors.green;
      case 'Recommandations':
        return Colors.orange;
      case 'Direct':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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

class _SimpleLineChart extends StatelessWidget {
  const _SimpleLineChart({required this.data, required this.color});

  final List<int> data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const chartHeight = 120.0;

    return CustomPaint(
      painter: _LineChartPainter(
        data: data,
        color: color,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      size: Size(double.infinity, chartHeight),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.data,
    required this.color,
    required this.backgroundColor,
  });

  final List<int> data;
  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.reduce((a, b) => a > b ? a : b).toDouble();
    if (maxValue == 0) return;

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

class _InsightItem extends StatelessWidget {
  const _InsightItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryStats {
  final int totalViews;
  final int totalReviews;
  final double averageRating;
  final double conversionRate;

  _SummaryStats({
    required this.totalViews,
    required this.totalReviews,
    required this.averageRating,
    required this.conversionRate,
  });
}
