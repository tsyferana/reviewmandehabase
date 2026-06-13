import '../models/notification_model.dart';

class NotificationRepository {
  static final List<NotificationModel> _notifications =
      List.generate(50, (index) {
    final type = NotificationType.values[index % NotificationType.values.length];
    final now = DateTime.now();
    final createdAt = now.subtract(Duration(
      hours: index * 5,
      days: index ~/ 9,
    ));

    return NotificationModel(
      id: 'notification-${index + 1}',
      type: type,
      title: _titleFor(type),
      message: _messageFor(type, index),
      createdAt: createdAt,
      isRead: index % 3 == 0,
      route: _routeFor(type),
    );
  });

  Future<List<NotificationModel>> getNotifications() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return _notifications.map((notification) => notification.copyWith()).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> markAsRead(String notificationId) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    final index = _notifications.indexWhere(
      (notification) => notification.id == notificationId,
    );
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  Future<void> markAllAsRead() async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    for (var index = 0; index < _notifications.length; index++) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    _notifications.removeWhere(
      (notification) => notification.id == notificationId,
    );
  }

  static String _titleFor(NotificationType type) {
    switch (type) {
      case NotificationType.review:
        return 'Nouvel avis';
      case NotificationType.favorite:
        return 'Favori mis a jour';
      case NotificationType.promotion:
        return 'Offre locale';
      case NotificationType.report:
        return 'Signalement traite';
      case NotificationType.system:
        return 'Info ReviewApp';
    }
  }

  static String _messageFor(NotificationType type, int index) {
    switch (type) {
      case NotificationType.review:
        return 'Une entreprise que vous suivez a recu un nouvel avis.';
      case NotificationType.favorite:
        return 'Un lieu favori a mis a jour ses horaires.';
      case NotificationType.promotion:
        return 'Une offre est disponible pres de vous cette semaine.';
      case NotificationType.report:
        return 'Votre signalement #${1000 + index} a ete examine.';
      case NotificationType.system:
        return 'Decouvrez de nouvelles recommandations a Antananarivo.';
    }
  }

  static String? _routeFor(NotificationType type) {
    switch (type) {
      case NotificationType.review:
        return '/business/biz-001/reviews';
      case NotificationType.favorite:
        return '/favorites';
      case NotificationType.promotion:
        return '/search';
      case NotificationType.report:
        return null;
      case NotificationType.system:
        return '/home';
    }
  }
}
