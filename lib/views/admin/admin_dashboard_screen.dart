import 'package:review_app/utils/couleur.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../services/supabase_data_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  static const routeName = '/admin/dashboard';

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _totalUsers = 0;
  int _totalBusinesses = 0;
  int _totalReviews = 0;
  int _pendingReports = 0;
  int _pendingApprovals = 0;
  bool _isLoading = true;

  final List<int> _usersGrowthData = [285, 320, 298, 342];
  final List<String> _growthLabels = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'];

  Map<String, int> _businessByCategory = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await SupabaseDataService().getAdminDashboardStats();
      if (mounted) {
        setState(() {
          _totalUsers = stats['users'] ?? 0;
          _totalBusinesses = stats['businesses'] ?? 0;
          _totalReviews = stats['reviews'] ?? 0;
          _pendingReports = stats['pendingReports'] ?? 0;
          _pendingApprovals = stats['pendingApprovals'] ?? 0;
          
          if (stats['businessByCategory'] != null) {
            _businessByCategory = Map<String, int>.from(stats['businessByCategory']);
          } else {
            _businessByCategory = {};
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Premium SliverAppBar ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 80,
            collapsedHeight: 60,
            toolbarHeight: 60,
            pinned: true,
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 8),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Administration',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Vue d\'ensemble de la plateforme',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.07),
                      colorScheme.surface,
                    ],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            actions: [
              IconButton(
                tooltip: 'Actualiser',
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadStats();
                },
                icon: const Icon(Icons.refresh_rounded),
              ),
              const SizedBox(width: 8),
            ],
          ),

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Section: KPI stat cards ──────────────────────
                  Text(
                    'Statistiques globales',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ).animate().fadeIn(duration: 350.ms),
                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount:
                        MediaQuery.sizeOf(context).width >= 900 ? 5 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.2,
                    children: [
                      _StatCard(
                        label: 'Utilisateurs',
                        value: _totalUsers,
                        icon: Icons.people_rounded,
                        color: const Color(0xFF3B82F6),
                        index: 0,
                      ),
                      _StatCard(
                        label: 'Établissements',
                        value: _totalBusinesses,
                        icon: Icons.storefront_rounded,
                        color: const Color(0xFF8B5CF6),
                        index: 1,
                      ),
                      _StatCard(
                        label: 'Avis',
                        value: _totalReviews,
                        icon: Icons.star_rounded,
                        color: AppColors.warning,
                        index: 2,
                      ),
                      _StatCard(
                        label: 'Signalements',
                        value: _pendingReports,
                        icon: Icons.flag_rounded,
                        color: AppColors.error,
                        index: 3,
                      ),
                      _StatCard(
                        label: 'En attente',
                        value: _pendingApprovals,
                        icon: Icons.hourglass_top_rounded,
                        color: AppColors.starRating,
                        index: 4,
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 24),

                  // ── Section: Charts ─────────────────────────────
                  Text(
                    'Tendances',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ).animate(delay: 100.ms).fadeIn(),
                  const SizedBox(height: 12),

                  LayoutBuilder(builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 600;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _ChartCard(
                              title: 'Croissance utilisateurs',
                              subtitle: '4 dernières semaines',
                              icon: Icons.show_chart_rounded,
                              iconColor: const Color(0xFF3B82F6),
                              child: _LineChartWidget(
                                data: _usersGrowthData,
                                labels: _growthLabels,
                                color: const Color(0xFF3B82F6),
                                legend: 'Nouveaux utilisateurs',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _ChartCard(
                              title: 'Par catégorie',
                              subtitle: 'Établissements',
                              icon: Icons.bar_chart_rounded,
                              iconColor: const Color(0xFF8B5CF6),
                              child: _CategoryBarsWidget(
                                  data: _businessByCategory),
                            ),
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _ChartCard(
                          title: 'Croissance utilisateurs',
                          subtitle: '4 dernières semaines',
                          icon: Icons.show_chart_rounded,
                          iconColor: const Color(0xFF3B82F6),
                          child: _LineChartWidget(
                            data: _usersGrowthData,
                            labels: _growthLabels,
                            color: const Color(0xFF3B82F6),
                            legend: 'Nouveaux utilisateurs',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ChartCard(
                          title: 'Par catégorie',
                          subtitle: 'Établissements',
                          icon: Icons.bar_chart_rounded,
                          iconColor: const Color(0xFF8B5CF6),
                          child:
                              _CategoryBarsWidget(data: _businessByCategory),
                        ),
                      ],
                    );
                  }).animate(delay: 150.ms).fadeIn(duration: 400.ms).slideY(begin: 0.04),
                  const SizedBox(height: 24),

                  // ── Section: Quick Actions ──────────────────────
                  Text(
                    'Actions rapides',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ).animate(delay: 200.ms).fadeIn(),
                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount:
                        MediaQuery.sizeOf(context).width >= 600 ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.5,
                    children: [
                      _QuickActionCard(
                        icon: Icons.people_rounded,
                        label: 'Utilisateurs',
                        color: const Color(0xFF3B82F6),
                        onTap: () => context.push('/admin/users'),
                        index: 0,
                      ),
                      _QuickActionCard(
                        icon: Icons.storefront_rounded,
                        label: 'Approbations',
                        color: const Color(0xFF8B5CF6),
                        onTap: () => context.push('/admin/approvals'),
                        index: 1,
                      ),
                      _QuickActionCard(
                        icon: Icons.category_rounded,
                        label: 'Catégories',
                        color: AppColors.success,
                        onTap: () => context.push('/admin/categories'),
                        index: 2,
                      ),
                      _QuickActionCard(
                        icon: Icons.flag_rounded,
                        label: 'Signalements',
                        color: AppColors.error,
                        badge: _pendingReports,
                        onTap: () => context.push('/admin/reports'),
                        index: 3,
                      ),
                    ],
                  ).animate(delay: 250.ms).fadeIn(duration: 400.ms).slideY(begin: 0.04),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat Card
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.index,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$value',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Text(
                    label,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 60)).fadeIn(duration: 350.ms).slideY(begin: 0.05);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chart Card wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(height: 160, child: child),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Action Card
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.index,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int badge;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.12),
                color.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$badge',
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: 250 + index * 60))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.05);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Line Chart
// ─────────────────────────────────────────────────────────────────────────────

class _LineChartWidget extends StatelessWidget {
  const _LineChartWidget({
    required this.data,
    required this.labels,
    required this.color,
    this.legend,
  });

  final List<int> data;
  final List<String> labels;
  final Color color;
  final String? legend;

  @override
  Widget build(BuildContext context) {
    final chart = CustomPaint(
      painter: _LineChartPainter(
        data: data,
        labels: labels,
        color: color,
        backgroundColor:
            Theme.of(context).colorScheme.surfaceContainerHighest,
        labelColor: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      child: const SizedBox.expand(),
    );

    if (legend == null) return chart;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 16.0),
          child: Row(
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
        ),
        Expanded(child: chart),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.data,
    required this.labels,
    required this.color,
    required this.backgroundColor,
    required this.labelColor,
  });

  final List<int> data;
  final List<String> labels;
  final Color color;
  final Color backgroundColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.reduce((a, b) => a > b ? a : b).toDouble();
    const padding = 30.0;
    final width = size.width - padding * 2;
    final height = size.height - padding * 2;

    // Grid
    final gridPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = padding + (i / 4) * height;
      canvas.drawLine(Offset(padding, y), Offset(size.width - padding, y), gridPaint);
    }

    // Fill
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = padding + (i / (data.length - 1)) * width;
      final y = size.height - padding - (data[i] / maxValue) * height;
      points.add(Offset(x, y));
    }

    // Draw fill
    if (points.isNotEmpty) {
      final path = Path()..moveTo(points.first.dx, size.height - padding);
      for (final p in points) { path.lineTo(p.dx, p.dy); }
      path.lineTo(points.last.dx, size.height - padding);
      path.close();
      canvas.drawPath(path, fillPaint);
    }

    // Draw line
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], linePaint);
    }

    // Dots
    for (final p in points) {
      canvas.drawCircle(p, 5, Paint()..color = color);
      canvas.drawCircle(p, 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Bars
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryBarsWidget extends StatelessWidget {
  const _CategoryBarsWidget({required this.data});

  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final maxValue = data.values.reduce((a, b) => a > b ? a : b).toDouble();

    const barColors = [
      Color(0xFF3B82F6),
      Color(0xFF8B5CF6),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: data.entries.toList().asMap().entries.map((entry) {
        final i = entry.key;
        final label = entry.value.key;
        final value = entry.value.value;
        final pct = value / maxValue;
        final barColor = barColors[i % barColors.length];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                child: Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 10,
                    backgroundColor: barColor.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(barColor),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$value',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: barColor,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

