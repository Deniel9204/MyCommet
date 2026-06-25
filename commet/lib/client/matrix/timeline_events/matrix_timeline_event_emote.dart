import 'dart:convert';

import 'package:commet/client/matrix/timeline_events/matrix_timeline_event.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event_emote.dart';
import 'package:commet/client/timeline_events/timeline_event_generic.dart';
import 'package:commet/ui/atoms/rich_text/matrix_html_parser.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:matrix/matrix.dart' as matrix;

class MatrixTimelineEventEmote extends MatrixTimelineEvent
    implements TimelineEventEmote, TimelineEventGeneric {
  MatrixTimelineEventEmote(super.event, {required super.client});

  String messageUserEmote(String user, String emote) =>
      Intl.message("*$user $emote",
          desc: "Message to display when a user does a custom emote (/me)",
          args: [user, emote],
          name: "messageUserEmote");

  @override
  String getBody({Timeline? timeline}) {
    String? sender = event.senderId.localpart;

    if (timeline != null) {
      sender = timeline.room.getMemberOrFallback(event.senderId).displayName;
    }

    if (sender != null) {
      return messageUserEmote(sender, event.body);
    }

    return event.body;
  }

  @override
  Widget? buildFormattedContent({Timeline? timeline}) {
    if (event.formattedText == "") {
      return null;
    }

    final room = client.getRoom(event.roomId!);
    if (room == null) {
      return null;
    }

    String sender = event.senderId.localpart ?? event.senderId;
    if (timeline != null) {
      sender = timeline.room.getMemberOrFallback(event.senderId).displayName;
    }

    // Render "* <sender> <formatted body>" as a single HTML fragment so the
    // formatted body's markup (e.g. the colours from /rainbowme) is shown
    // inline. The sender name is escaped; the formatted body is already HTML.
    final html =
        "* ${const HtmlEscape().convert(sender)} ${event.formattedText}";
    return MatrixHtmlParser.parse(html, client, room);
  }

  @override
  IconData? get icon => null;

  @override
  bool get showSenderAvatar => true;
}
