import 'package:commet/client/client.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/pages/get_or_create_room/room_creator.dart';
import 'package:commet/utils/error_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiamat/atoms/tile.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class RoomSecuritySettingsPage extends StatefulWidget {
  const RoomSecuritySettingsPage({
    required this.room,
    this.contextSpace,
    this.showEncryptionToggle = true,
    super.key,
  });
  final Room room;
  final Space? contextSpace;
  final bool showEncryptionToggle;

  @override
  State<RoomSecuritySettingsPage> createState() =>
      _RoomSecuritySettingsPageState();
}

class _RoomSecuritySettingsPageState extends State<RoomSecuritySettingsPage> {
  late bool isE2EEEnabled;
  late RoomVisibility visibility;
  late RoomHistoryVisibility historyVisibility;

  String get promptEnableEncryptionRoomSettings =>
      Intl.message("Enable Encryption",
          name: "promptEnableEncryptionRoomSettings",
          desc: "Short prompt to enable encryption for a room");

  String get encryptionCannotBeDisabledExplanationRoomSettings =>
      Intl.message("If enabled, encryption cannot be disabled later",
          name: "encryptionCannotBeDisabledExplanationRoomSettings",
          desc: "Explains that encryption cannot be disabled once enabled");

  String get labelBannedUsers => Intl.message("Banned users",
      name: "labelBannedUsers",
      desc: "Header for the list of banned users in room settings");

  String get labelUnban => Intl.message("Unban",
      name: "labelUnban",
      desc: "Label for the button to unban a user from a room");

  Future<void> unban(String userId) async {
    await ErrorUtils.tryRun(context, () async {
      await widget.room.unbanUser(userId);
    });
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    isE2EEEnabled = widget.room.isE2EE;
    visibility = widget.room.visibility;
    historyVisibility = widget.room.historyVisibility;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      children: [
        if (widget.room.client.supportsE2EE && widget.showEncryptionToggle)
          buildE2EEToggle(),
        buildRoomVisibility(),
        buildHistoryVisibility(),
        if (widget.room.bannedUserIds.isNotEmpty) buildBannedUsers(),
      ],
    );
  }

  Widget buildBannedUsers() {
    return tiamat.Panel(
      header: labelBannedUsers,
      mode: tiamat.TileType.surfaceContainerLow,
      child: Column(
        children: [
          for (final userId in widget.room.bannedUserIds)
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text(userId),
              trailing: TextButton(
                onPressed: () => unban(userId),
                child: Text(labelUnban),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildE2EEToggle() {
    return tiamat.Panel(
      mode: tiamat.TileType.surfaceContainerLow,
      child: Opacity(
        opacity: widget.room.permissions.canEnableE2EE ? 1 : 0.5,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  tiamat.Text.labelEmphasised(
                      promptEnableEncryptionRoomSettings),
                  tiamat.Text.labelLow(
                      encryptionCannotBeDisabledExplanationRoomSettings)
                ]),
            IgnorePointer(
              ignoring: isE2EEEnabled || !widget.room.permissions.canEnableE2EE,
              child: tiamat.Switch(
                state: isE2EEEnabled,
                onChanged: (value) {
                  if (value != true) return;
                  setState(() {
                    isE2EEEnabled = true;
                    widget.room.enableE2EE();
                  });
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildRoomVisibility() {
    return IgnorePointer(
      ignoring: !widget.room.permissions.canChangeVisibility,
      child: tiamat.Panel(
        header: "Room Visibility",
        mode: TileType.surfaceContainerLow,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              List<String> spaces = List.empty(growable: true);
              if (widget.room.visibility
                  case RoomVisibilityRestricted restricted) {
                spaces.addAll(restricted.spaces);
              }

              if (widget.contextSpace != null &&
                  !spaces.contains(widget.contextSpace?.identifier)) {
                spaces.add(widget.contextSpace!.identifier);
              }

              if (spaces.isEmpty) {
                var parents = widget.room.client.spaces.where((i) => i.subspaces
                    .any((i) => i.identifier == widget.room.identifier));

                for (var p in parents) {
                  spaces.add(p.identifier);
                }
              }

              var items = [
                if (spaces.isNotEmpty) RoomVisibilityRestricted(spaces),
                RoomVisibilityPrivate(),
                RoomVisibilityPublic(),
              ];

              var newVisibility = await AdaptiveDialog.pickOne(
                title: "Set Visibility",
                context,
                items: items,
                itemBuilder: (context, item, callback) {
                  return Material(
                    borderRadius: BorderRadius.circular(8),
                    clipBehavior: Clip.antiAlias,
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: callback,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: RoomFieldVisibility.buildRoomVisibility(
                            widget.room.client, item),
                      ),
                    ),
                  );
                },
              );

              if (newVisibility != null) {
                ErrorUtils.tryRun(context, () async {
                  await widget.room.setVisibility(newVisibility);

                  setState(() {
                    visibility = newVisibility;
                  });
                });
              }
            },
            child: RoomFieldVisibility.buildRoomVisibility(
                widget.room.client, visibility),
          ),
        ),
      ),
    );
  }

  String get labelHistoryVisibility => Intl.message("Who can read history",
      name: "labelHistoryVisibility",
      desc: "Header for the room history-visibility setting");

  String historyVisibilityLabel(RoomHistoryVisibility v) {
    switch (v) {
      case RoomHistoryVisibility.worldReadable:
        return "Anyone, even without joining";
      case RoomHistoryVisibility.shared:
        return "Members (all history)";
      case RoomHistoryVisibility.invited:
        return "Members (from when they were invited)";
      case RoomHistoryVisibility.joined:
        return "Members (from when they joined)";
    }
  }

  Widget buildHistoryVisibility() {
    return tiamat.Panel(
      header: labelHistoryVisibility,
      mode: tiamat.TileType.surfaceContainerLow,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final picked = await AdaptiveDialog.pickOne(
              context,
              title: labelHistoryVisibility,
              items: RoomHistoryVisibility.values,
              itemBuilder: (context, item, callback) => Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: callback,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(historyVisibilityLabel(item)),
                  ),
                ),
              ),
            );
            if (picked != null) {
              ErrorUtils.tryRun(context, () async {
                await widget.room.setHistoryVisibility(picked);
                setState(() {
                  historyVisibility = picked;
                });
              });
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(historyVisibilityLabel(historyVisibility)),
          ),
        ),
      ),
    );
  }
}
