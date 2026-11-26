import 'package:flutter/widgets.dart';

/// Notification display data for the inbox UI.
///
/// Backend records map [id] to the notification UUID. Navigation uses
/// [targetType]/[targetId], never the record id. Cart-derived helpers may still
/// populate [orderId]/[asProvider] when used outside the API inbox.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timeLabel,
    this.titleFa = '',
    this.messageFa = '',
    this.imageUrl,
    this.unreadCount = 0,
    this.orderId,
    this.asProvider = false,
    this.createdAt,
    this.targetType,
    this.targetId,
  });

  final String id, title, message, timeLabel;
  final String titleFa, messageFa;
  final String? imageUrl;
  final int unreadCount;
  final String? orderId;
  final bool asProvider;
  final DateTime? createdAt;
  final String? targetType;
  final String? targetId;

  String localizedTitle(Locale locale) =>
      _localized(locale, english: title, persian: titleFa);

  String localizedMessage(Locale locale) =>
      _localized(locale, english: message, persian: messageFa);

  static String _localized(
    Locale locale, {
    required String english,
    required String persian,
  }) {
    final en = english.trim();
    final fa = persian.trim();
    if (locale.languageCode == 'fa') {
      if (fa.isNotEmpty) return fa;
      return en;
    }
    if (en.isNotEmpty) return en;
    return fa;
  }

  AppNotification markRead() => AppNotification(
    id: id,
    title: title,
    message: message,
    titleFa: titleFa,
    messageFa: messageFa,
    timeLabel: timeLabel,
    imageUrl: imageUrl,
    orderId: orderId,
    asProvider: asProvider,
    createdAt: createdAt,
    targetType: targetType,
    targetId: targetId,
  );

  AppNotification copyWith({int? unreadCount, String? timeLabel}) =>
      AppNotification(
        id: id,
        title: title,
        message: message,
        titleFa: titleFa,
        messageFa: messageFa,
        timeLabel: timeLabel ?? this.timeLabel,
        imageUrl: imageUrl,
        unreadCount: unreadCount ?? this.unreadCount,
        orderId: orderId,
        asProvider: asProvider,
        createdAt: createdAt,
        targetType: targetType,
        targetId: targetId,
      );
}
