import 'package:commet/client/components/push_notification/modifiers/notification_modifiers.dart';
import 'package:commet/client/components/push_notification/notification_content.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/platform_utils.dart';
import 'package:commet/main.dart';
import 'package:commet/utils/event_bus.dart';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class NotificationModifierSuppressActiveRoom implements NotificationModifier {
  String? roomId = "";

  NotificationModifierSuppressActiveRoom() {
    EventBus.onSelectedRoomChanged.stream.listen((event) {
      roomId = event?.identifier;
    });
  }

  @override
  Future<NotificationContent?> process(NotificationContent content) async {
    if (preferences.suppressNotificationWhenRoomFocused.value == false) {
      return content;
    }

    if (content is MessageNotificationContent) {
      // window_manager isn't initialized on macOS (WindowManagement.init bails),
      // so windowManager.isFocused() force-unwraps a nil main window and crashes
      // the moment a notification arrives. Use the app lifecycle state there.
      if (BuildConfig.DESKTOP && !PlatformUtils.isMac) {
        if (!await windowManager.isFocused()) {
          return content;
        }
      } else {
        if (WidgetsBinding.instance.lifecycleState !=
            AppLifecycleState.resumed) {
          return content;
        }
      }

      if (content.roomId == roomId) return null;
    }

    return content;
  }
}
