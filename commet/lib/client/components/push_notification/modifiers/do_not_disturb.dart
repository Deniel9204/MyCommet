import 'package:commet/client/components/push_notification/modifiers/notification_modifiers.dart';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/main.dart';

class NotificationModifierDoNotDisturb implements NotificationModifier {
  @override
  Future<NotificationContent?> process(NotificationContent content) async {
    // Returning null suppresses the notification entirely.
    if (preferences.doNotDisturb.value) {
      return null;
    }
    return content;
  }
}
