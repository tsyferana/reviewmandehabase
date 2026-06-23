import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingPage {
  const _OnboardingPage({
    required this.illustration,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.accentIcon,
  });

  final Widget illustration;
  final String eyebrow;
  final String title;
  final String body;
  final IconData accentIcon;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const routeName = '/onboarding';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _hasSeenOnboardingKey = 'hasSeenOnboarding';

  List<_OnboardingPage> _buildPages(ColorScheme cs) => [
    _OnboardingPage(
      eyebrow: 'Bienvenue',
      title: 'Découvrez\nprès de chez vous',
      body:
          'Services locaux, restaurants, artisans — trouvez ce dont vous avez besoin, là où vous êtes.',
      accentIcon: Icons.location_on_rounded,
      illustration: _IllustrationMap(colorScheme: cs),
    ),
    _OnboardingPage(
      eyebrow: 'Fiabilité',
      title: 'Des avis\nque vous pouvez croire',
      body:
          'Chaque avis est vérifié après une vraie expérience. Aucun faux commentaire, aucune manipulation.',
      accentIcon: Icons.verified_rounded,
      illustration: _IllustrationReview(colorScheme: cs),
    ),
    _OnboardingPage(
      eyebrow: 'Communauté',
      title: 'Partagez votre\nexpérience',
      body:
          'Votre avis aide des milliers de personnes à faire le bon choix. Rejoignez la communauté.',
      accentIcon: Icons.people_alt_rounded,
      illustration: _IllustrationCommunity(colorScheme: cs),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingKey, true);
    if (!mounted) return;
    context.go('/login');
  }

  void _next() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pages = _buildPages(colorScheme);
    final isLast = _currentPage == pages.length - 1;

    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        children: [
          // ── Ambient background (identique au login) ──────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.5, 1.0],
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.07 + _currentPage * 0.03),
                    colorScheme.surface,
                    colorScheme.secondary.withValues(alpha: 0.05 + _currentPage * 0.02),
                  ],
                ),
              ),
            ),
          ),

          // ── Orbe décoratif haut-droit ────────────────────────────
          Positioned(
            top: -size.width * 0.3,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.12 + _currentPage * 0.03),
                    colorScheme.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // ── Orbe décoratif bas-gauche ────────────────────────────
          Positioned(
            bottom: -size.width * 0.2,
            left: -size.width * 0.15,
            child: Container(
              width: size.width * 0.55,
              height: size.width * 0.55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.secondary.withValues(alpha: 0.08),
                    colorScheme.secondary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Top bar ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Step counter
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          '${_currentPage + 1} / ${pages.length}',
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // Skip button — hidden on last page
                      AnimatedOpacity(
                        opacity: isLast ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: TextButton(
                          onPressed: isLast ? null : _finish,
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.onSurfaceVariant,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          child: const Text('Passer'),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Illustrations (PageView) ───────────────────────
                Expanded(
                  flex: 5,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: pages.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: pages[i].illustration,
                    ),
                  ),
                ),

                // ── Text content ───────────────────────────────────
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: _PageTextContent(
                      key: ValueKey(_currentPage),
                      page: pages[_currentPage],
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                  ),
                ),

                // ── Bottom bar ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
                  child: Row(
                    children: [
                      // Dots
                      _PaginationDots(
                        count: pages.length,
                        current: _currentPage,
                        colorScheme: colorScheme,
                      ),

                      const Spacer(),

                      // CTA button
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: isLast
                            ? FilledButton.icon(
                                key: const ValueKey('start'),
                                onPressed: _next,
                                icon: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                                label: const Text("C'est parti"),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              )
                            : FilledButton(
                                key: const ValueKey('next'),
                                onPressed: _next,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text('Suivant'),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Text content block (animated on page change)
// ─────────────────────────────────────────────────────────────────────────────

class _PageTextContent extends StatelessWidget {
  const _PageTextContent({
    super.key,
    required this.page,
    required this.colorScheme,
    required this.textTheme,
  });

  final _OnboardingPage page;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // Eyebrow + icon
        Row(
              children: [
                Icon(page.accentIcon, size: 14, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  page.eyebrow.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            )
            .animate()
            .fadeIn(duration: 400.ms, curve: Curves.easeOut)
            .slideX(begin: -0.08, end: 0, duration: 400.ms),

        const SizedBox(height: 14),

        // Title
        Text(
              page.title,
              style: textTheme.headlineMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                height: 1.15,
                letterSpacing: -0.3,
              ),
            )
            .animate(delay: 80.ms)
            .fadeIn(duration: 450.ms, curve: Curves.easeOut)
            .slideY(
              begin: 0.12,
              end: 0,
              duration: 450.ms,
              curve: Curves.easeOutCubic,
            ),

        const SizedBox(height: 16),

        // Body
        Text(
              page.body,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.55,
              ),
            )
            .animate(delay: 160.ms)
            .fadeIn(duration: 450.ms, curve: Curves.easeOut)
            .slideY(
              begin: 0.10,
              end: 0,
              duration: 450.ms,
              curve: Curves.easeOutCubic,
            ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pagination dots
// ─────────────────────────────────────────────────────────────────────────────

class _PaginationDots extends StatelessWidget {
  const _PaginationDots({
    required this.count,
    required this.current,
    required this.colorScheme,
  });

  final int count;
  final int current;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(right: 6),
          width: isActive ? 24 : 7,
          height: 7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.15),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Illustrations — pure Flutter drawing, no assets needed
// ─────────────────────────────────────────────────────────────────────────────

/// Slide 1 — Map with location pins
class _IllustrationMap extends StatefulWidget {
  const _IllustrationMap({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  State<_IllustrationMap> createState() => _IllustrationMapState();
}

class _IllustrationMapState extends State<_IllustrationMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.colorScheme;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => CustomPaint(
        painter: _MapPainter(cs: cs, t: _ctrl.value),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  const _MapPainter({required this.cs, required this.t});
  final ColorScheme cs;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Card background
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: size.width * 0.88,
        height: size.height * 0.82,
      ),
      const Radius.circular(28),
    );
    canvas.drawRRect(
      cardRect,
      Paint()..color = cs.surfaceContainerHighest.withValues(alpha: 0.55),
    );

    // Grid lines (map roads)
    final roadPaint = Paint()
      ..color = cs.onSurface.withValues(alpha: 0.07)
      ..strokeWidth = 1.5;
    for (var i = 0; i < 6; i++) {
      final x = size.width * 0.08 + i * size.width * 0.16;
      canvas.drawLine(
        Offset(x, size.height * 0.1),
        Offset(x, size.height * 0.9),
        roadPaint,
      );
    }
    for (var i = 0; i < 5; i++) {
      final y = size.height * 0.15 + i * size.height * 0.16;
      canvas.drawLine(
        Offset(size.width * 0.06, y),
        Offset(size.width * 0.94, y),
        roadPaint,
      );
    }

    // Blocks (buildings)
    final blockPaint = Paint()..color = cs.primary.withValues(alpha: 0.08);
    final blocks = [
      Rect.fromLTWH(cx - 80, cy - 60, 60, 40),
      Rect.fromLTWH(cx + 20, cy - 70, 50, 55),
      Rect.fromLTWH(cx - 90, cy + 10, 45, 35),
      Rect.fromLTWH(cx + 30, cy + 5, 55, 30),
      Rect.fromLTWH(cx - 30, cy + 30, 40, 45),
    ];
    for (final b in blocks) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(b, const Radius.circular(6)),
        blockPaint,
      );
    }

    // Pins
    final pins = [
      (Offset(cx, cy - 20), true, 0.0),
      (Offset(cx - 55, cy + 15), false, 0.3),
      (Offset(cx + 50, cy - 35), false, 0.6),
    ];

    for (final (pos, isMain, phase) in pins) {
      final pulse = math.sin((t + phase) * math.pi) * 0.5 + 0.5;

      if (isMain) {
        // Pulse ring
        canvas.drawCircle(
          pos,
          18 + pulse * 10,
          Paint()
            ..color = cs.primary.withValues(alpha: 0.15 * (1 - pulse))
            ..style = PaintingStyle.fill,
        );
      }

      // Pin body
      final pinPaint = Paint()..color = isMain ? cs.primary : cs.secondary;

      final path = Path()
        ..addOval(
          Rect.fromCircle(center: pos + const Offset(0, -16), radius: 12),
        )
        ..moveTo(pos.dx - 4, pos.dy - 8)
        ..lineTo(pos.dx, pos.dy)
        ..lineTo(pos.dx + 4, pos.dy - 8)
        ..close();
      canvas.drawPath(path, pinPaint);

      // Star inside pin
      canvas.drawCircle(
        pos + const Offset(0, -16),
        4,
        Paint()..color = cs.onPrimary,
      );
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.t != t;
}

// ────────────────────────────────────────────────────────────────────────────
/// Slide 2 — Review card with stars
class _IllustrationReview extends StatelessWidget {
  const _IllustrationReview({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final cs = colorScheme;
    return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main review card
              _ReviewCard(
                cs: cs,
                name: 'Sophie M.',
                rating: 5,
                text: 'Excellent service, je recommande vivement !',
                delay: 0,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ReviewCard(
                    cs: cs,
                    name: 'Lucas D.',
                    rating: 4,
                    text: 'Très bon rapport qualité/prix.',
                    delay: 100,
                    compact: true,
                  ),
                  const SizedBox(width: 12),
                  _ReviewCard(
                    cs: cs,
                    name: 'Amina K.',
                    rating: 5,
                    text: 'Parfait, rien à redire.',
                    delay: 200,
                    compact: true,
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(
          begin: 0.06,
          end: 0,
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.cs,
    required this.name,
    required this.rating,
    required this.text,
    required this.delay,
    this.compact = false,
  });

  final ColorScheme cs;
  final String name;
  final int rating;
  final String text;
  final int delay;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
          constraints: compact
              ? const BoxConstraints(maxWidth: 150)
              : const BoxConstraints(maxWidth: 300),
          padding: EdgeInsets.all(compact ? 12 : 16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: compact ? 12 : 16,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      name[0],
                      style: TextStyle(
                        fontSize: compact ? 11 : 13,
                        fontWeight: FontWeight.w700,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        fontSize: compact ? 11 : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: compact ? 12 : 15,
                    color: i < rating ? const Color(0xFFFFC107) : cs.outline,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                text,
                style: textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                  fontSize: compact ? 10 : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        )
        .animate(delay: delay.ms)
        .fadeIn(duration: 400.ms)
        .slideY(
          begin: 0.1,
          end: 0,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Slide 3 — Community / people
class _IllustrationCommunity extends StatelessWidget {
  const _IllustrationCommunity({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final cs = colorScheme;

    final members = [
      ('A', cs.primary, 120.0, 90.0),
      ('L', cs.secondary, 200.0, 60.0),
      ('M', cs.tertiary, 80.0, 160.0),
      ('K', cs.primary, 230.0, 150.0),
      ('R', cs.secondary, 155.0, 195.0),
      ('T', cs.tertiary, 45.0, 100.0),
    ];

    return Stack(
      children: [
        // Connection lines
        CustomPaint(
          painter: _ConnectionPainter(cs: cs),
          child: const SizedBox.expand(),
        ),
        // Avatar nodes
        ...members.asMap().entries.map((entry) {
          final i = entry.key;
          final (label, color, x, y) = entry.value;
          return Positioned(
            left: x,
            top: y,
            child: _AvatarNode(label: label, color: color, cs: cs)
                .animate(delay: (i * 80).ms)
                .fadeIn(duration: 400.ms)
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  duration: 400.ms,
                  curve: Curves.easeOutBack,
                ),
          );
        }),
        // Central badge
        Positioned(
          left: 120,
          top: 120,
          child:
              Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.star_rounded,
                      color: cs.primary,
                      size: 28,
                    ),
                  )
                  .animate(delay: 500.ms)
                  .fadeIn(duration: 400.ms)
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1.0, 1.0),
                    duration: 500.ms,
                    curve: Curves.easeOutBack,
                  ),
        ),
      ],
    );
  }
}

class _AvatarNode extends StatelessWidget {
  const _AvatarNode({
    required this.label,
    required this.color,
    required this.cs,
  });
  final String label;
  final Color color;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _ConnectionPainter extends CustomPainter {
  const _ConnectionPainter({required this.cs});
  final ColorScheme cs;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = cs.primary.withValues(alpha: 0.10)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Positions matching the Stack offsets (center of 44×44 avatars)
    final nodes = [
      const Offset(142, 112),
      const Offset(222, 82),
      const Offset(102, 182),
      const Offset(252, 172),
      const Offset(177, 217),
      const Offset(67, 122),
    ];

    // Connect nearby nodes
    for (var i = 0; i < nodes.length; i++) {
      for (var j = i + 1; j < nodes.length; j++) {
        final dist = (nodes[i] - nodes[j]).distance;
        if (dist < 130) {
          canvas.drawLine(nodes[i], nodes[j], paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_ConnectionPainter old) => false;
}
