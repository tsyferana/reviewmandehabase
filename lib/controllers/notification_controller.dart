import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class NotificationController extends ChangeNotifier {
  NotificationController(this._notificationRepository);

  final NotificationRepository _notificationRepository;

  bool _isLoading = false;
  List<NotificationModel> _notifications = [];

  bool get isLoading => _isLoading;
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);

  Future<void> loadNotifications() async {
    _setLoading(true);
    _notifications = await _notificationRepository.getNotifications();
    _setLoading(false);
  }

  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere(
      (notification) => notification.id == notificationId,
    );
    if (index == -1) return;

    _notifications[index] = _notifications[index].copyWith(isRead: true);
    notifyListeners();
    await _notificationRepository.markAsRead(notificationId);
  }

  Future<void> markAllAsRead() async {
    _notifications = _notifications
        .map((notification) => notification.copyWith(isRead: true))
        .toList();
    notifyListeners();
    await _notificationRepository.markAllAsRead();
  }

  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere(
      (notification) => notification.id == notificationId,
    );
    notifyListeners();
    await _notificationRepository.deleteNotification(notificationId);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
