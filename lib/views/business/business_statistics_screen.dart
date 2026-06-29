import 'package:review_app/utils/couleur.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/supabase_data_service.dart';

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
  late Map<int, Map<int, int>> _ratingDistribution;

  // Summary stats
  late Map<int, _SummaryStats> _summaryStats;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMockData();
    _loadRealData();
  }

  void _initializeMockData() {
    _daysLabels = {
      7: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'],
      30: List.generate(30, (i) => '${i + 1}'),
      90: List.generate(13, (i) => 'S${i + 1}'),
      365: ['Jan', 'Fev', 'Mar', 'Avr', 'Mai', 'Jui', 'Juil', 'Aou', 'Sep', 'Oct', 'Nov', 'Dec'],
    };

    _viewsData = { 7: List.filled(7, 0), 30: List.filled(30, 0), 90: List.filled(13, 0), 365: List.filled(12, 0) };
    _reviewsData = { 7: List.filled(7, 0), 30: List.filled(30, 0), 90: List.filled(13, 0), 365: List.filled(12, 0) };
    
    _ratingDistribution = { 
      7: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}, 
      30: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}, 
      90: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}, 
      365: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0} 
    };

    final zeroStats = _SummaryStats(totalViews: 0, totalReviews: 0, averageRating: 0.0, conversionRate: 0.0);
    _summaryStats = { 7: zeroStats, 30: zeroStats, 90: zeroStats, 365: zeroStats };
  }

  Future<void> _loadRealData() async {
    try {
      final biz = await SupabaseDataService().getUserBusiness();
      if (biz == null) return;
      
      final reviews = await SupabaseDataService().getBusinessReviews(biz['id']);
      final views = await SupabaseDataService().getBusinessViews(biz['id']);
      
      int totalReviews = reviews.length;
      int totalViews = views.length;
      double conversionRate = totalViews > 0 ? (totalReviews / totalViews) * 100 : 0.0;
      
      double sum = 0;
      Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      
      for (var r in reviews) {
        final rating = (r['rating'] as num).toInt();
        sum += rating;
        if (distribution.containsKey(rating)) {
          distribution[rating] = distribution[rating]! + 1;
        }
      }
      
      double avg = totalReviews > 0 ? sum / totalReviews : 0;
      final now = DateTime.now();
      
      // Update data for all periods
      setState(() {
        for (var period in [7, 30, 90, 365]) {
          _ratingDistribution[period] = Map.from(distribution);
          _summaryStats[period] = _SummaryStats(
            totalViews: totalViews,
            totalReviews: totalReviews,
            averageRating: avg,
            conversionRate: conversionRate,
          );
          
          // Zero out mock charts
          _viewsData[period] = List.filled(_viewsData[period]!.length, 0);
          _reviewsData[period] = List.filled(_reviewsData[period]!.length, 0);
          
          // Populate charts for views
          int viewDays = _viewsData[period]!.length;
          for (var v in views) {
            final date = DateTime.tryParse(v['created_at'].toString());
            if (date != null) {
              final diff = now.difference(date).inDays;
              if (period == 7 || period == 30) {
                 if (diff < period && diff >= 0) {
                    final index = viewDays - 1 - diff;
                    if (index >= 0 && index < viewDays) {
                      _viewsData[period]![index]++;
                    }
                 }
              }
            }
          }
          
          // Populate charts for reviews
          int reviewDays = _reviewsData[period]!.length;
          for (var r in reviews) {
            final date = DateTime.tryParse(r['created_at'].toString());
            if (date != null) {
              final diff = now.difference(date).inDays;
              if (period == 7 || period == 30) {
                 if (diff < period && diff >= 0) {
                    final index = reviewDays - 1 - diff;
                    if (index >= 0 && index < reviewDays) {
                      _reviewsData[period]![index]++;
                    }
                 }
              }
            }
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading stats: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportPDF() async {
    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(content: Text('Préparation du PDF...')),
    // );

    final pdf = pw.Document();
    final stats = _summaryStats[_selectedPeriod]!;
    
    String periodText = '';
    switch (_selectedPeriod) {
      case 7: periodText = '7 jours'; break;
      case 30: periodText = '30 jours'; break;
      case 90: periodText = '3 mois'; break;
      case 365: periodText = '1 an'; break;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Rapport Statistique de l\'Entreprise', 
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Période analysée : $periodText', style: const pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 30),
              
              pw.Text('Résumé', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.SizedBox(height: 10),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Avis Totaux : ${stats.totalReviews}'),
                  pw.Text('Note Moyenne : ${stats.averageRating.toStringAsFixed(2)} / 5'),
                ]
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Vues Totales : ${stats.totalViews}'),
                  pw.Text('Conversion Favoris : ${stats.conversionRate.toStringAsFixed(1)}%'),
                ]
              ),
              pw.SizedBox(height: 30),
              
              pw.Text('Répartition des notes', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.SizedBox(height: 10),
              
              ...[5,4,3,2,1].map((rating) {
                final count = _ratingDistribution[_selectedPeriod]![rating] ?? 0;
                final total = _ratingDistribution[_selectedPeriod]!.values.fold<int>(0, (a, b) => a + b);
                final percentage = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';
                
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Row(
                    children: [
                      pw.Text('$rating étoiles : ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('$count avis ($percentage%)'),
                    ]
                  )
                );
              }),
              
              pw.SizedBox(height: 30),
              pw.Text('Généré par ReviewApp', style: const pw.TextStyle(color: PdfColors.grey)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'rapport_statistiques.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                  color: AppColors.warning,
                ),
                _SummaryCard(
                  icon: Icons.star_rounded,
                  label: 'Note moyenne',
                  value: stats.averageRating.toStringAsFixed(2),
                  color: AppColors.starRating,
                ),
                _SummaryCard(
                  icon: Icons.trending_up_rounded,
                  label: 'Conversion favoris',
                  value: '${stats.conversionRate.toStringAsFixed(1)}%',
                  color: AppColors.success,
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
                      legend: 'Nombre de vues',
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
                      color: AppColors.warning,
                      legend: 'Nombre d\'avis',
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
                                    color: AppColors.starRating,
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
  const _SimpleLineChart({required this.data, required this.color, this.legend});

  final List<int> data;
  final Color color;
  final String? legend;

  @override
  Widget build(BuildContext context) {
    const chartHeight = 120.0;

    final chart = CustomPaint(
      painter: _LineChartPainter(
        data: data,
        color: color,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      size: const Size(double.infinity, chartHeight),
    );

    if (legend == null) return chart;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              legend!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        chart,
      ],
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
