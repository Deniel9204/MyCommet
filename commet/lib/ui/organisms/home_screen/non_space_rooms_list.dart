import 'dart:async';

import 'package:commet/client/room.dart';
import 'package:commet/ui/atoms/room_panel.dart';
import 'package:commet/ui/pages/get_or_create_room/get_or_create_room.dart';
import 'package:commet/ui/pages/main/main_page.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

/// Lists the rooms that aren't part of any space (and aren't direct messages),
/// for the "Rooms" view reached from the navigation rail (#13 /
/// commetchat/commet#836). It mirrors how [ImportantRoomsList] shows favourites
/// and DMs in the same picker column.
///
/// Rooms come from `ClientManager.singleRooms`, which honours the account
/// filter: the merged ("mix") view lists non-space rooms from every logged-in
/// account, while a selected account lists only its own.
class NonSpaceRoomsList extends StatefulWidget {
  const NonSpaceRoomsList({super.key, required this.state});

  final MainPageState state;

  @override
  State<NonSpaceRoomsList> createState() => _NonSpaceRoomsListState();
}

class _NonSpaceRoomsListState extends State<NonSpaceRoomsList> {
  late List<Room> rooms;
  late List<StreamSubscription> subscriptions;

  String get labelRoomsListHeader => Intl.message("Rooms",
      name: "labelRoomsListHeader",
      desc: "Header for the list of rooms that aren't part of a space");

  @override
  void initState() {
    super.initState();
    updateRooms();

    final clientManager = widget.state.clientManager;
    subscriptions = [
      clientManager.onSync.stream.listen((_) => refresh()),
      clientManager.onRoomAdded.listen((_) => refresh()),
      clientManager.onRoomRemoved.listen((_) => refresh()),
      // A room joining/leaving a space changes whether it counts as a single
      // room, so refresh on space child updates too.
      clientManager.onSpaceChildUpdated.stream.listen((_) => refresh()),
      widget.state.onFilterClientChanged.stream.listen((_) => refresh()),
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
    setState(() {
      updateRooms();
    });
  }

  void updateRooms() {
    rooms = widget.state.clientManager
        .singleRooms(filterClient: widget.state.filterClient);
    rooms.sort((a, b) => b.lastEventTimestamp.compareTo(a.lastEventTimestamp));
  }

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.fromLTRB(0, 4, 0, 4);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: tiamat.Text.labelLow(labelRoomsListHeader),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: tiamat.IconButton(
                  icon: Icons.add,
                  onPressed: () {
                    GetOrCreateRoom.show(null, context,
                        pickExisting: false, showAllRoomTypes: true);
                  },
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(3, 0, 0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rooms
                  .map((room) => Padding(
                        padding: padding,
                        child: RoomPanel(
                          room,
                          key: ValueKey("NonSpaceRoomsList-${room.localId}"),
                          onTap: () {
                            EventBus.doOpenRoom(room.identifier,
                                clientId: room.client.identifier,
                                openInSpace: false);
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
