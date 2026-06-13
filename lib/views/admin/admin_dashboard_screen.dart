import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui' as ui;

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  static const routeName = '/admin/dashboard';

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  final int _totalUsers = 1245;
  final int _totalBusinesses = 328;
  final int _totalReviews = 5847;
  final int _pendingReports = 12;
  final int _pendingApprovals = 18;

  late List<int> _usersGrowthData;
  late List<String> _growthLabels;

  final Map<String, int> _businessByCategory = {
    'Restaurants': 95,
    'Hôtels': 52,
    'Boutiques': 68,
    'Services': 73,
    'Autres': 40,
  };

  late List<_ActivityItem> _recentActivity;

  @override
  void initState() {
    super.initState();
    _growthLabels = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'];
    _usersGrowthData = [285, 320, 298, 342];

    _recentActivity = [
      _ActivityItem(
        type: 'user',
        title: 'Nouvel utilisateur',
        subtitle: 'Aina Rajaonarivelo',
        icon: Icons.person_add,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      _ActivityItem(
        type: 'report',
        title: 'Signalement reçu',
        subtitle: 'Avis problématique',
        icon: Icons.flag,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 900;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: isTablet
          ? Row(
              children: [
                SizedBox(width: 280, child: _sidebar(context)),
                Expanded(child: _content(context)),
              ],
            )
          : _content(context),
      drawer: isTablet ? null : _drawer(context),
    );
  }

  Widget _sidebar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: _menu(context),
    );
  }

  Widget _drawer(BuildContext context) {
    return Drawer(child: _menu(context));
  }

  Widget _menu(BuildContext context) {
    final items = [
      ('Dashboard', Icons.dashboard, '/admin/dashboard'),
      ('Users', Icons.people, '/admin/users'),
      ('Approbations', Icons.check_circle_rounded, '/admin/approvals'),
      ('Signalements', Icons.flag_rounded, '/admin/reports'),
      ('Catégories', Icons.category_rounded, '/admin/categories'),
    ];

    return ListView(
      children: items
          .map(
            (e) => ListTile(
              leading: Icon(e.$2),
              title: Text(e.$1),
              onTap: () => context.go(e.$3),
            ),
          )
          .toList(),
    );
  }

  Widget _content(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width >= 900 ? 5 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _stat("Users", _totalUsers, Icons.people, Colors.blue),
              _stat(
                "Businesses",
                _totalBusinesses,
                Icons.business,
                Colors.purple,
              ),
              _stat("Reviews", _totalReviews, Icons.star, Colors.orange),
              _stat("Reports", _pendingReports, Icons.flag, Colors.red),
              _stat(
                "Pending",
                _pendingApprovals,
                Icons.hourglass_bottom,
                Colors.amber,
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: Card(
                  child: SizedBox(
                    height: 220,
                    child: _LineChartWidget(
                      data: _usersGrowthData,
                      labels: _growthLabels,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: SizedBox(
                    height: 220,
                    child: _CategoryBarsWidget(data: _businessByCategory),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              "$value",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _LineChartWidget extends StatelessWidget {
  const _LineChartWidget({
    required this.data,
    required this.labels,
    required this.color,
  });

  final List<int> data;
  final List<String> labels;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(
        data: data,
        labels: labels,
        color: color,
        textTheme: Theme.of(context).textTheme,
        colorScheme: Theme.of(context).colorScheme,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.data,
    required this.labels,
    required this.color,
    required this.textTheme,
    required this.colorScheme,
  });

  final List<int> data;
  final List<String> labels;
  final Color color;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.reduce((a, b) => a > b ? a : b).toDouble();
    final padding = 30.0;
    final width = size.width - padding * 2;
    final height = size.height - padding * 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = padding + (i / (data.length - 1)) * width;
      final y = size.height - padding - (data[i] / maxValue) * height;

      points.add(Offset(x, y));
    }

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    for (final p in points) {
      canvas.drawCircle(p, 4, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CategoryBarsWidget extends StatelessWidget {
  const _CategoryBarsWidget({required this.data});

  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CategoryBarsPainter(
        data: data,
        textTheme: Theme.of(context).textTheme,
        colorScheme: Theme.of(context).colorScheme,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _CategoryBarsPainter extends CustomPainter {
  _CategoryBarsPainter({
    required this.data,
    required this.textTheme,
    required this.colorScheme,
  });

  final Map<String, int> data;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.values.reduce((a, b) => a > b ? a : b).toDouble();
    final width = size.width / data.length;
    final height = size.height;

    int i = 0;

    data.forEach((label, value) {
      final barHeight = (value / maxValue) * (height - 20);

      final paint = Paint()
        ..color = Colors.primaries[i % Colors.primaries.length];

      final rect = Rect.fromLTWH(
        i * width + 10,
        height - barHeight,
        width - 20,
        barHeight,
      );

      canvas.drawRect(rect, paint);

      i++;
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ActivityItem {
  _ActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.timestamp,
  });

  final String type;
  final String title;
  final String subtitle;
  final IconData icon;
  final DateTime timestamp;
}
