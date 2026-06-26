import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/ui/atoms/notification_badge.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/tiamat.dart';

/// The navigation-rail button that opens the Rooms view (#13). Shows an
/// aggregate unread badge for rooms that aren't part of a space, so new messages
/// in them are visible without opening the view.
///
/// The count comes from `ClientManager.singleRooms`, so it honours the account
/// filter the same way the rooms list does: the merged ("mix") view counts
/// non-space rooms across every account, a selected account only its own.
class SideNavigationBarRoomsButton extends StatefulWidget {
  const SideNavigationBarRoomsButton(this.clientManager,
      {super.key, this.onTap, this.filterClient, this.size = 70});

  final ClientManager clientManager;
  final Client? filterClient;
  final void Function()? onTap;
  final double size;

  @override
  State<SideNavigationBarRoomsButton> createState() =>
      _SideNavigationBarRoomsButtonState();
}

class _SideNavigationBarRoomsButtonState
    extends State<SideNavigationBarRoomsButton> {
  Client? filterClient;
  int notificationCount = 0;

  late List<StreamSubscription> subscriptions;

  @override
  void initState() {
    super.initState();
    filterClient = widget.filterClient;
    updateCount();

    subscriptions = [
      EventBus.setFilterClient.stream.listen((client) {
        filterClient = client;
        refresh();
      }),
      widget.clientManager.onSync.stream.listen((_) => refresh()),
      widget.clientManager.onRoomAdded.listen((_) => refresh()),
      widget.clientManager.onRoomRemoved.listen((_) => refresh()),
      widget.clientManager.onSpaceChildUpdated.stream.listen((_) => refresh()),
    ];
  }

  @override
  void dispose() {
    for (var sub in subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  void refresh() {
    if (!mounted) return;
    setState(updateCount);
  }

  void updateCount() {
    notificationCount = widget.clientManager
        .singleRooms(filterClient: filterClient)
        .fold(0, (sum, room) => sum + room.displayNotificationCount);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ImageButton(
          size: widget.size,
          icon: Icons.forum,
          onTap: () => widget.onTap?.call(),
        ),
        if (notificationCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: SizedBox(
              width: 20,
              height: 20,
              child: NotificationBadge(notificationCount),
            ),
          ),
      ],
    );
  }
}
