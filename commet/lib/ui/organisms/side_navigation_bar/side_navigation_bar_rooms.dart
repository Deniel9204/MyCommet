import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/client_manager.dart';
import 'package:commet/ui/atoms/space_icon.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';

/// Shows the rooms that aren't part of any space (and aren't direct messages) as
/// icons in the navigation rail, so they're reachable without digging through
/// the home screen (#13 / commetchat/commet#836).
///
/// The list comes from [ClientManager.singleRooms], which already filters out
/// DMs and space children and honours the account filter: with no filter it
/// shows non-space rooms across every logged-in account ("mix" view), and when
/// an account is selected it shows only that account's rooms — matching how the
/// direct message rail above it behaves.
class SideNavigationBarRooms extends StatefulWidget {
  const SideNavigationBarRooms(this.clientManager,
      {super.key, this.onRoomTapped, this.filterClient});

  final ClientManager clientManager;
  final Client? filterClient;
  final void Function(Room room)? onRoomTapped;

  @override
  State<SideNavigationBarRooms> createState() => _SideNavigationBarRoomsState();
}

class _SideNavigationBarRoomsState extends State<SideNavigationBarRooms> {
  late List<Room> rooms;
  Client? filterClient;

  late List<StreamSubscription> subscriptions;

  @override
  void initState() {
    super.initState();
    filterClient = widget.filterClient;

    updateRooms();

    subscriptions = [
      EventBus.setFilterClient.stream.listen(setFilterClient),
      widget.clientManager.onSync.stream.listen((_) => refresh()),
      widget.clientManager.onRoomAdded.listen((_) => refresh()),
      widget.clientManager.onRoomRemoved.listen((_) => refresh()),
      // A room joining/leaving a space changes whether it counts as a single
      // room, so refresh on space child updates too.
      widget.clientManager.onSpaceChildUpdated.stream.listen((_) => refresh()),
    ];
  }

  @override
  void dispose() {
    for (var element in subscriptions) {
      element.cancel();
    }
    super.dispose();
  }

  void setFilterClient(Client? event) {
    filterClient = event;
    refresh();
  }

  void refresh() {
    if (!mounted) return;
    setState(() {
      updateRooms();
    });
  }

  void updateRooms() {
    rooms = widget.clientManager.singleRooms(filterClient: filterClient);
  }

  @override
  Widget build(BuildContext context) {
    bool empty = rooms.isEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(0, empty ? 0 : 4, 0, 0),
      child: ImplicitlyAnimatedList(
        shrinkWrap: true,
        itemData: rooms,
        padding: const EdgeInsets.all(0),
        itemBuilder: (context, data) {
          return Padding(
            padding: EdgeInsetsGeometry.fromLTRB(0, 2, 0, 2),
            child: SpaceIcon(
              displayName: data.displayName,
              placeholderColor: data.defaultColor,
              spaceId: data.identifier,
              avatar: data.avatar,
              width: 70,
              highlightedNotificationCount: data.notificationCount,
              onTap: () => widget.onRoomTapped?.call(data),
            ),
          );
        },
      ),
    );
  }
}
