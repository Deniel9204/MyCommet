import 'package:commet/client/components/push_notification/modifiers/notification_modifiers.dart';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/main.dart';
import 'package:intl/intl.dart';

class NotificationModifierHideContent implements NotificationModifier {
  String get notificationModifiersPrivacyEnhanced => Intl.message(
      "Sent a message",
      name: "notificationModifiersPrivacyEnhanced",
      desc:
          "Placeholder text to put in a notification when the user has privacy enhanced notifications enabled.");

  @override
  Future<NotificationContent?> process(NotificationContent content) async {
    if (!preferences.hideNotificationContent.value) {
      return content;
    }

    content.content = "A Notification was received";

    if (content is MessageNotificationContent) {
      content.content = notificationModifiersPrivacyEnhanced;
    }

    return content;
  }
}
