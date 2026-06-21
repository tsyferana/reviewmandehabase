import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final authStateProvider = StreamProvider((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final notificationsStreamProvider = StreamProvider<List<NotificationModel>>((ref) {
  // S'abonner aux changements d'authentification pour recharger le stream
  ref.watch(authStateProvider);
  
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.streamNotifications();
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsStreamProvider);
  return notificationsAsync.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

final notificationControllerProvider = Provider<NotificationController>((ref) {
  return NotificationController(ref.watch(notificationRepositoryProvider));
});

class NotificationController {
  NotificationController(this._notificationRepository);

  final NotificationRepository _notificationRepository;

  Future<void> markAsRead(String notificationId) async {
    await _notificationRepository.markAsRead(notificationId);
  }

  Future<void> markAllAsRead() async {
    await _notificationRepository.markAllAsRead();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _notificationRepository.deleteNotification(notificationId);
  }
}
