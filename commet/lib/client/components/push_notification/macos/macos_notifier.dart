import 'dart:convert';

import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/client/components/push_notification/notification_manager.dart';
import 'package:commet/client/components/push_notification/notifier.dart';
import 'package:commet/client/room.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:commet/utils/notification_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:media_kit/media_kit.dart';

/// Local (UNUserNotificationCenter) notifications for macOS.
///
/// macOS has no remote push transport here; like the Linux and Windows
/// notifiers it shows notifications that the foreground app produces when a
/// message/call arrives (see matrix_room.dart -> NotificationManager.notify).
class MacosNotifier implements Notifier {
  static FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

  static int notificationId = 0;

  static const messageCategory = "message";
  static const callCategory = "call";

  static const replyAction = "inline-reply";
  static const callAccept = "call.accept";
  static const callDecline = "call.decline";

  @override
  bool get hasPermission => true;

  @override
  bool get enabled => true;

  @override
  bool get needsToken => false;

  @override
  Future<String?> getToken() async => null;

  @override
  Map<String, dynamic>? extraRegistrationData() => null;

  @override
  Future<bool> requestPermission() async {
    final granted = await flutterLocalNotificationsPlugin
        ?.resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return granted ?? false;
  }

  @override
  Future<void> init() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    final initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          messageCategory,
          actions: [
            DarwinNotificationAction.text(
              replyAction,
              "Reply",
              buttonTitle: "Send",
              // Required: the macOS plugin force-casts this (`as! String`) while
              // building the category, so a null placeholder crashes init().
              placeholder: "Reply",
            ),
          ],
        ),
        DarwinNotificationCategory(
          callCategory,
          actions: [
            DarwinNotificationAction.plain(
                callAccept, CommonStrings.promptAccept),
            DarwinNotificationAction.plain(
                callDecline, CommonStrings.promptDecline),
          ],
        ),
      ],
    );

    await flutterLocalNotificationsPlugin?.initialize(
      InitializationSettings(macOS: initializationSettingsDarwin),
      onDidReceiveNotificationResponse: notificationResponse,
    );

    if (clientManager != null) {
      clientManager!.directMessages.highlightedRoomsList.onListUpdated
          .listen((_) => updateBadgeCount());
      clientManager!.onSpaceUpdated.stream.listen((_) => updateBadgeCount());
    }

    updateBadgeCount();
  }

  static const MethodChannel _dockChannel =
      MethodChannel("chat.commet.commetapp/dock");

  Future<void> _setDockBadge(int count) async {
    try {
      await _dockChannel.invokeMethod("setBadgeCount", count);
    } catch (e) {
      Log.w("Failed to set macOS dock badge: $e");
    }
  }

  Future<void> updateBadgeCount() async {
    if (clientManager == null) return;
    if (preferences.showNotificationBadgesInTaskbar.value == true) {
      var counts = NotificationUtils.getNotificationCounts();
      await _setDockBadge(counts.$2);
    }
  }

  static void notificationResponse(NotificationResponse details) {
    if (details.payload == null) return;
    final payload = jsonDecode(details.payload!) as Map<String, dynamic>;
    final action = details.actionId;

    if (action == replyAction) {
      final clientId = payload['client_id'];
      final roomId = payload['room_id'];
      final message = details.input;

      if (clientId == null || roomId == null || message == null) return;

      final client = clientManager!.getClient(clientId);
      if (client == null) return;

      if (message.trim().isNotEmpty) {
        client.getRoom(roomId)?.sendMessage(message: message.trim());
      }
      return;
    }

    if (action == callAccept || action == callDecline) {
      final callId = payload['call_id'];
      final clientId = payload['client_id'];
      final session = clientManager?.callManager.currentSessions
          .where(
              (e) => e.sessionId == callId && e.client.identifier == clientId)
          .firstOrNull;

      if (action == callDecline) {
        clientManager?.callManager.stopRingtone();
      }

      if (session != null) {
        if (action == callAccept) session.acceptCall(withMicrophone: true);
        if (action == callDecline) session.declineCall();
      }
      return;
    }

    // Default tap (no action button) -> open the room. macOS already brings the
    // app to the foreground when its notification is clicked, and
    // window_manager's show()/focus() force-unwrap a main window that isn't
    // initialized here (which crashes), so just navigate to the room.
    final roomId = payload['room_id'];
    if (roomId != null) {
      EventBus.doOpenRoom(roomId, clientId: payload['client_id'] as String?);
    }
  }

  @override
  Future<void> notify(NotificationContent notification) async {
    switch (notification) {
      case MessageNotificationContent _:
        return displayMessageNotification(notification);
      case CallNotificationContent _:
        return displayCallNotification(notification);
      default:
        return displaySimpleNotification(notification);
    }
  }

  Future<void> displayMessageNotification(
      MessageNotificationContent content) async {
    var title = "${content.senderName} (${content.roomName})";
    if (content.isDirectMessage) {
      title = content.senderName;
    }

    final details = DarwinNotificationDetails(
      categoryIdentifier: messageCategory,
      // Group notifications from the same room together.
      threadIdentifier: content.roomId,
      // The app plays its own sound below (respecting the volume preference).
      presentSound: false,
      presentAlert: true,
    );

    final payload = {
      "room_id": content.roomId,
      "client_id": content.clientId,
      "event_id": content.eventId,
    };

    var player = NotificationManager.getSoundPlayer();
    player.open(Media("asset:///assets/sound/message.ogg"));

    await flutterLocalNotificationsPlugin?.show(
      notificationId++,
      title,
      content.content,
      NotificationDetails(macOS: details),
      payload: jsonEncode(payload),
    );
  }

  Future<void> displayCallNotification(CallNotificationContent content) async {
    final details = DarwinNotificationDetails(
      categoryIdentifier: callCategory,
      interruptionLevel: InterruptionLevel.timeSensitive,
      presentAlert: true,
      presentSound: true,
    );

    final payload = {
      "room_id": content.roomId,
      "client_id": content.clientId,
      "call_id": content.callId,
    };

    await flutterLocalNotificationsPlugin?.show(
      0,
      content.title,
      content.content,
      NotificationDetails(macOS: details),
      payload: jsonEncode(payload),
    );
  }

  Future<void> displaySimpleNotification(NotificationContent content) async {
    await flutterLocalNotificationsPlugin?.show(
      notificationId++,
      content.title,
      content.content,
      const NotificationDetails(macOS: DarwinNotificationDetails()),
    );
  }

  @override
  Future<void> clearNotifications(Room room) async {}

  @override
  Future<void> enableBadges() async {
    await updateBadgeCount();
  }

  @override
  Future<void> disableBadges() async {
    await _setDockBadge(0);
  }
}
