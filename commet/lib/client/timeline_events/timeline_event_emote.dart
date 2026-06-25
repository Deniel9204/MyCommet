import 'package:commet/client/timeline.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:flutter/widgets.dart';

abstract class TimelineEventEmote extends TimelineEvent {
  /// Builds the emote's formatted body (e.g. the colours from /rainbowme) as
  /// rich HTML, prefixed with "* <sender>". Returns null when the emote has no
  /// formatted body, so the view can fall back to plain text.
  Widget? buildFormattedContent({Timeline? timeline});
}
