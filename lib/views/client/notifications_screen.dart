import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../controllers/notification_controller.dart';
import '../../models/notification_model.dart';
import '../../repositories/notification_repository.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  static const routeName = '/notifications';

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationController _notificationController;

  @override
  void initState() {
    super.initState();
    _notificationController = NotificationController(NotificationRepository());
    _notificationController.addListener(_onNotificationsChanged);
    unawaited(_notificationController.loadNotifications());
  }

  @override
  void dispose() {
    _notificationController
      ..removeListener(_onNotificationsChanged)
      ..dispose();
    super.dispose();
  }

  void _onNotificationsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleTap(NotificationModel notification) async {
    await _notificationController.markAsRead(notification.id);

    if (!mounted) return;

    final route = notification.route;
    if (route != null) {
      context.go(route);
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    await _notificationController.deleteNotification(notification.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification supprimee.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _notificationController.notifications;
    final groups = _groupNotifications(notifications);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: notifications.any((notification) => !notification.isRead)
                ? _notificationController.markAllAsRead
                : null,
            child: const Text('Tout marquer comme lu'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _notificationController.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const _EmptyNotificationsState()
              : ListView(
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
                              onDismissed: (_) {
                                _deleteNotification(notification);
                              },
                              child: _NotificationCard(
                                notification: notification,
                                onTap: () => _handleTap(notification),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
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
      'Aujourd’hui': today,
      'Cette semaine': thisWeek,
      'Plus ancien': older,
    };
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
    final time = DateFormat('HH:mm').format(notification.createdAt);

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
        return Icons.rate_review_rounded;
      case NotificationType.favorite:
        return Icons.favorite_rounded;
      case NotificationType.promotion:
        return Icons.local_offer_rounded;
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
      case NotificationType.favorite:
        return colorScheme.tertiaryContainer;
      case NotificationType.promotion:
        return colorScheme.secondaryContainer;
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
              'Les mises a jour importantes apparaitront ici.',
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
