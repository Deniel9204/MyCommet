import 'package:commet/client/client.dart';
import 'package:commet/client/room_preview.dart';
import 'package:commet/utils/debounce.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Browse and search the homeserver's public room directory, and join rooms
/// from it.
class ExploreRoomsView extends StatefulWidget {
  const ExploreRoomsView({required this.client, super.key});

  final Client client;

  @override
  State<ExploreRoomsView> createState() => _ExploreRoomsViewState();
}

class _ExploreRoomsViewState extends State<ExploreRoomsView> {
  final TextEditingController controller = TextEditingController();
  final TextEditingController serverController = TextEditingController();
  final Debouncer debouncer =
      Debouncer(delay: const Duration(milliseconds: 500));

  List<RoomPreview>? results;
  bool loading = false;
  String? error;
  String? joining;

  String get labelExploreRooms => Intl.message("Explore rooms",
      name: "labelExploreRooms",
      desc: "Title for the public room directory browser");

  String get promptSearchPublicRooms => Intl.message("Search public rooms",
      name: "promptSearchPublicRooms",
      desc: "Hint text for the public room directory search field");

  String get promptServer => Intl.message("Server (blank = your homeserver)",
      name: "promptExploreServer",
      desc: "Hint for the server field in the public room directory browser");

  String get labelJoin =>
      Intl.message("Join", name: "labelExploreJoin", desc: "Join a room");

  String get labelNoRoomsFound => Intl.message("No rooms found",
      name: "labelNoRoomsFound",
      desc: "Shown when the public room search returns nothing");

  String get errorDirectoryPrivate =>
      Intl.message("This server's room directory is private or unavailable.",
          name: "errorDirectoryPrivate",
          desc: "Shown when a server's public room directory is forbidden");

  String get errorPublicRoomsFailed => Intl.message(
      "Couldn't load public rooms. Check the server name and try again.",
      name: "errorPublicRoomsFailed",
      desc: "Generic error when loading the public room directory fails");

  String memberCount(int count) => Intl.message("$count members",
      name: "labelRoomMemberCount",
      args: [count],
      desc: "Number of members in a room");

  @override
  void initState() {
    super.initState();
    search("");
  }

  @override
  void dispose() {
    debouncer.cancel();
    controller.dispose();
    serverController.dispose();
    super.dispose();
  }

  void onTextChanged(String value) {
    setState(() => loading = true);
    debouncer.run(() => search(value));
  }

  Future<void> search(String query) async {
    final trimmed = query.trim();
    final server = serverController.text.trim();
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await widget.client.searchPublicRooms(
        query: trimmed.isEmpty ? null : trimmed,
        server: server.isEmpty ? null : server,
      );
      if (!mounted) return;
      setState(() {
        results = result.rooms;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString();
      setState(() {
        error = (raw.contains("M_FORBIDDEN") || raw.contains("not public"))
            ? errorDirectoryPrivate
            : errorPublicRoomsFailed;
        loading = false;
      });
    }
  }

  Future<void> join(RoomPreview preview) async {
    setState(() => joining = preview.roomId);
    try {
      final room = await widget.client.joinRoomFromPreview(preview);
      if (!mounted) return;
      EventBus.doOpenRoom(room.identifier, clientId: widget.client.identifier);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => joining = null);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(labelExploreRooms),
            Text(
              widget.client.self?.displayName ?? widget.client.identifier,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: TextField(
              controller: serverController,
              onChanged: (_) => onTextChanged(controller.text),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.dns),
                hintText: promptServer,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: controller,
              autofocus: true,
              onChanged: onTextChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: promptSearchPublicRooms,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          if (loading) const LinearProgressIndicator(),
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          if (results != null && results!.isEmpty && !loading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(labelNoRoomsFound),
            ),
          if (results != null)
            Expanded(
              child: ListView.builder(
                itemCount: results!.length,
                itemBuilder: (context, index) => buildRoom(results![index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildRoom(RoomPreview room) {
    final subtitleParts = <String>[
      if (room.numMembers != null) memberCount(room.numMembers!),
      if (room.topic != null && room.topic!.isNotEmpty) room.topic!,
    ];

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: room.avatar,
        child: room.avatar == null
            ? Text(room.displayName.isNotEmpty
                ? room.displayName.characters.first
                : "#")
            : null,
      ),
      title:
          Text(room.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitleParts.isEmpty
          ? null
          : Text(subtitleParts.join(" · "),
              maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: joining == room.roomId
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2))
          : TextButton(onPressed: () => join(room), child: Text(labelJoin)),
    );
  }
}
