import 'package:equatable/equatable.dart';

enum NotificationType {
  connectionRequest,
  connectionAccepted,
  listingInquiry,
  newListing,
  reminderDue,
  general;

  static NotificationType fromString(String? v) {
    switch (v) {
      case 'connection_request':
        return NotificationType.connectionRequest;
      case 'connection_accepted':
        return NotificationType.connectionAccepted;
      case 'listing_inquiry':
        return NotificationType.listingInquiry;
      case 'new_listing':
        return NotificationType.newListing;
      case 'reminder_due':
        return NotificationType.reminderDue;
      default:
        return NotificationType.general;
    }
  }

  String get key {
    switch (this) {
      case NotificationType.connectionRequest:
        return 'connection_request';
      case NotificationType.connectionAccepted:
        return 'connection_accepted';
      case NotificationType.listingInquiry:
        return 'listing_inquiry';
      case NotificationType.newListing:
        return 'new_listing';
      case NotificationType.reminderDue:
        return 'reminder_due';
      case NotificationType.general:
        return 'general';
    }
  }
}

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.actorUid,
    this.targetId,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? actorUid;
  final String? targetId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      actorUid: actorUid,
      targetId: targetId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, type, title, body, actorUid, targetId, isRead, createdAt];
}
