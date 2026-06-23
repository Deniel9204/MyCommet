import 'package:commet/client/client.dart';
import 'package:commet/client/components/event_search/event_search_component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_view_entry.dart';
import 'package:commet/utils/mime.dart';
import 'package:commet/utils/search_query.dart';
// ignore: implementation_imports
import 'package:matrix/src/event.dart';

class MatrixEventSearchSession extends EventSearchSession {
  MatrixTimeline timeline;
  String? currentSearchTerm;
  String? prevBatch;

  MatrixEventSearchSession(this.timeline);

  @override
  bool currentlySearching = false;

  SearchQuery? _query;

  @override
  Stream<List<TimelineEvent<Client>>> startSearch(String searchTerm) async* {
    currentSearchTerm = searchTerm.toLowerCase();

    currentlySearching = true;
    _query = SearchQuery.parse(searchTerm);

    var search = timeline.matrixTimeline!
        .startSearch(searchTerm: searchTerm, searchFunc: searchFunc);
    List<TimelineEvent<Client>> result = List.empty();
    await for (final chunk in search) {
      result = chunk.$1
          .map((e) => (timeline.room as MatrixRoom).convertEvent(e))
          .toList();

      Map<String, TimelineEvent> m = {};

      for (var event in result) {
        var type = TimelineViewEntryState.eventToDisplayType(event);
        if (type != TimelineEventWidgetDisplayType.hidden) {
          m[event.eventId] = event;
        }
      }

      if (chunk.$2 != null) {
        prevBatch = chunk.$2;
      }

      result = m.values.toList();
      result.sort((a, b) => b.originServerTs.compareTo(a.originServerTs));

      yield result;
    }

    currentlySearching = false;
    yield result;
  }

  bool searchFunc(Event event) {
    return _query!.matches(
      plaintextBody: event.plaintextBody,
      type: event.type,
      messageType: event.messageType,
      senderId: event.senderId,
      hasAttachment: event.hasAttachment,
      isImageAttachment: Mime.imageTypes.contains(event.attachmentMimetype),
      isVideoAttachment: Mime.videoTypes.contains(event.attachmentMimetype),
    );
  }
}

class MatrixEventSearchComponent implements EventSearchComponent<MatrixClient> {
  @override
  MatrixClient client;

  MatrixEventSearchComponent(this.client);

  @override
  Future<EventSearchSession> createSearchSession(Room room) async {
    var timeline = await room.getTimeline();
    return MatrixEventSearchSession(timeline as MatrixTimeline);
  }
}
