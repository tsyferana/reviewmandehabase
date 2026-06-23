import 'package:review_app/utils/couleur.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../controllers/notification_controller.dart';
import '../../models/notification_model.dart';
import '../../routes/app_router.dart' as router;

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key, this.isAdmin = false});

  final bool isAdmin;

  static const routeName = '/notifications';

  Future<void> _handleTap(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
  ) async {
    await ref.read(notificationControllerProvider).markAsRead(notification.id);

    if (!context.mounted) return;

    final authRole = ref.read(router.authStateProvider).userRole;

    if (notification.relatedId != null) {
      if (notification.type == NotificationType.review ||
          notification.type == NotificationType.reply) {
        if (authRole == 'business') {
          context.go('/business/reviews');
        } else {
          context.go('/home/business/${notification.relatedId}');
        }
      } else if (notification.type == NotificationType.business_request) {
        if (authRole == 'admin') {
          context.go('/admin/approvals');
        } else {
          context.go('/business/dashboard');
        }
      } else if (notification.type == NotificationType.report) {
        if (authRole == 'admin') {
          context.go('/admin/reports');
        }
      } else if (notification.type == NotificationType.approval ||
          notification.type == NotificationType.rejection) {
        context.go('/business/dashboard');
      }
    }
  }

  Future<void> _deleteNotification(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
  ) async {
    await ref
        .read(notificationControllerProvider)
        .deleteNotification(notification.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notification supprimée.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  Map<String, List<NotificationModel>> _groupNotifications(
    List<NotificationModel> notifications,
  ) {
    final now = DateTime.now();
    final today = <NotificationModel>[];
    final thisWeek = <NotificationModel>[];
    final older = <NotificationModel>[];

    for (final notification in notifications) {
      final difference = now.difference(notification.createdAt);
      if (difference.inDays == 0) {
        today.add(notification);
      } else if (difference.inDays < 7) {
        thisWeek.add(notification);
      } else {
        older.add(notification);
      }
    }

    return {
      "Aujourd'hui": today,
      'Cette semaine': thisWeek,
      'Plus ancien': older,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final isTablet = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: isAdmin && !isTablet
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              )
            : null,
        actions: [
          notificationsAsync.maybeWhen(
            data: (notifications) {
              final hasUnread = notifications.any((n) => !n.isRead);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: hasUnread
                      ? () => ref
                            .read(notificationControllerProvider)
                            .markAllAsRead()
                      : null,
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: const Text('Tout lire'),
                  style: TextButton.styleFrom(
                    foregroundColor: hasUnread
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => _NotificationsLoading(colorScheme: colorScheme),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: colorScheme.error,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Erreur lors du chargement',
                style: textTheme.titleMedium,
              ),
            ],
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) return const _EmptyNotificationsState();

          final groups = _groupNotifications(notifications);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              for (final entry in groups.entries) ...[
                if (entry.value.isNotEmpty) ...[
                  // Group header chip
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(
                              alpha: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Text(
                            entry.key,
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Divider(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...entry.value.asMap().entries.map((e) {
                    final notification = e.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Dismissible(
                        key: ValueKey(notification.id),
                        direction: DismissDirection.endToStart,
                        background: const _NotificationDismissBackground(),
                        onDismissed: (_) =>
                            _deleteNotification(context, ref, notification),
                        child: _NotificationCard(
                          notification: notification,
                          onTap: () => _handleTap(context, ref, notification),
                        ).animate(delay: (e.key * 40).ms).fadeIn(duration: 300.ms).slideX(begin: 0.05),
                      ),
                    );
                  }),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final time = DateFormat('HH:mm').format(notification.createdAt.toLocal());

    final bgColor = notification.isRead
        ? colorScheme.surface
        : colorScheme.primaryContainer.withValues(alpha: 0.15);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead
              ? colorScheme.outlineVariant.withValues(alpha: 0.5)
              : colorScheme.primary.withValues(alpha: 0.2),
          width: notification.isRead ? 0.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _iconBackground(context, notification.type),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconFor(notification.type),
                    color: _iconColor(context, notification.type),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            time,
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        notification.message,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Unread dot
                if (!notification.isRead) ...[
                  const SizedBox(width: 10),
                  Container(
                    width: 9,
                    height: 9,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.review:
        return Icons.star_rounded;
      case NotificationType.reply:
        return Icons.reply_rounded;
      case NotificationType.business_request:
        return Icons.business_center_rounded;
      case NotificationType.approval:
        return Icons.check_circle_rounded;
      case NotificationType.rejection:
        return Icons.cancel_rounded;
      case NotificationType.report:
        return Icons.flag_rounded;
      case NotificationType.system:
        return Icons.notifications_rounded;
    }
  }

  Color _iconBackground(BuildContext context, NotificationType type) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (type) {
      case NotificationType.review:
        return colorScheme.primaryContainer;
      case NotificationType.reply:
        return colorScheme.tertiaryContainer;
      case NotificationType.business_request:
        return colorScheme.secondaryContainer;
      case NotificationType.approval:
        return AppColors.success.withValues(alpha: 0.2);
      case NotificationType.rejection:
        return colorScheme.errorContainer;
      case NotificationType.report:
        return colorScheme.errorContainer;
      case NotificationType.system:
        return colorScheme.surfaceContainerHighest;
    }
  }

  Color _iconColor(BuildContext context, NotificationType type) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (type) {
      case NotificationType.review:
        return colorScheme.primary;
      case NotificationType.reply:
        return colorScheme.tertiary;
      case NotificationType.business_request:
        return colorScheme.secondary;
      case NotificationType.approval:
        return AppColors.success;
      case NotificationType.rejection:
        return colorScheme.error;
      case NotificationType.report:
        return colorScheme.error;
      case NotificationType.system:
        return colorScheme.onSurfaceVariant;
    }
  }
}

class _NotificationDismissBackground extends StatelessWidget {
  const _NotificationDismissBackground();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_rounded, color: colorScheme.onErrorContainer),
          const SizedBox(height: 4),
          Text(
            'Supprimer',
            style: TextStyle(
              color: colorScheme.onErrorContainer,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNotificationsState extends StatelessWidget {
  const _EmptyNotificationsState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    size: 48,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ).animate().scale(
              begin: const Offset(0.7, 0.7),
              end: const Offset(1, 1),
              duration: 500.ms,
              curve: Curves.easeOutBack,
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune notification',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ).animate(delay: 150.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 8),
            Text(
              'Les mises à jour importantes apparaîtront ici.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ).animate(delay: 220.ms).fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

class _NotificationsLoading extends StatelessWidget {
  const _NotificationsLoading({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        return Container(
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fade(begin: 0.4, end: 1, duration: 800.ms);
      },
    );
  }
}
