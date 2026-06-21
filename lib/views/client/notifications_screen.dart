import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../controllers/notification_controller.dart';
import '../../models/notification_model.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const routeName = '/notifications';

  Future<void> _handleTap(BuildContext context, WidgetRef ref, NotificationModel notification) async {
    await ref.read(notificationControllerProvider).markAsRead(notification.id);

    if (!context.mounted) return;

    if (notification.relatedId != null) {
      if (notification.type == NotificationType.review || notification.type == NotificationType.reply) {
        context.go('/business/${notification.relatedId}');
      } else if (notification.type == NotificationType.business_request) {
        // Assume admins go to their dashboard
        context.go('/admin/dashboard');
      } else if (notification.type == NotificationType.approval || notification.type == NotificationType.rejection) {
        context.go('/business-dashboard');
      }
    }
  }

  Future<void> _deleteNotification(BuildContext context, WidgetRef ref, NotificationModel notification) async {
    await ref.read(notificationControllerProvider).deleteNotification(notification.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification supprimee.')),
    );
  }

  Map<String, List<NotificationModel>> _groupNotifications(List<NotificationModel> notifications) {
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
      'Aujourd’hui': today,
      'Cette semaine': thisWeek,
      'Plus ancien': older,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          notificationsAsync.maybeWhen(
            data: (notifications) {
              final hasUnread = notifications.any((n) => !n.isRead);
              return TextButton(
                onPressed: hasUnread
                    ? () => ref.read(notificationControllerProvider).markAllAsRead()
                    : null,
                child: const Text('Tout marquer comme lu'),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
        data: (notifications) {
          if (notifications.isEmpty) return const _EmptyNotificationsState();

          final groups = _groupNotifications(notifications);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              for (final entry in groups.entries) ...[
                if (entry.value.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
                    child: Text(
                      entry.key,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  ...entry.value.map(
                    (notification) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Dismissible(
                        key: ValueKey(notification.id),
                        direction: DismissDirection.endToStart,
                        background: const _NotificationDismissBackground(),
                        onDismissed: (_) => _deleteNotification(context, ref, notification),
                        child: _NotificationCard(
                          notification: notification,
                          onTap: () => _handleTap(context, ref, notification),
                        ),
                      ),
                    ),
                  ),
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
  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final time = DateFormat('HH:mm').format(notification.createdAt.toLocal());

    return Card(
      elevation: 0,
      color: notification.isRead
          ? colorScheme.surface
          : colorScheme.primaryContainer.withValues(alpha: 0.28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: _iconBackground(context, notification.type),
                child: Icon(
                  _iconFor(notification.type),
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          time,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notification.message,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead) ...[
                const SizedBox(width: 10),
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(top: 7),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
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
        return Colors.green.withValues(alpha: 0.2);
      case NotificationType.rejection:
        return colorScheme.errorContainer;
      case NotificationType.report:
        return colorScheme.errorContainer;
      case NotificationType.system:
        return colorScheme.surfaceContainerHighest;
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
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.delete_rounded,
        color: colorScheme.onErrorContainer,
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
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 112,
              height: 112,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 54,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Aucune notification',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les mises à jour importantes apparaîtront ici.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
