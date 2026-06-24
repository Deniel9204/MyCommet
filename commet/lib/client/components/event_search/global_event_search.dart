import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/event_search/event_search_component.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/utils/search_result_merge.dart';

/// A single cross-room search hit: an [event] together with the [room] it
/// belongs to.
class GlobalSearchResult {
  GlobalSearchResult(this.room, this.event);

  final Room room;
  final TimelineEvent event;
}

/// Runs a message search across many rooms at once by fanning out to each
/// room's [EventSearchSession] and merging their results (deduped by event id,
/// most-recent-first). Create one per search, listen to [results], and
/// [dispose] when done.
class GlobalEventSearch {
  GlobalEventSearch(this.component);

  final EventSearchComponent component;

  final StreamController<List<GlobalSearchResult>> _controller =
      StreamController<List<GlobalSearchResult>>.broadcast();
  final List<StreamSubscription> _subs = [];
  final Map<String, List<GlobalSearchResult>> _resultsByRoom = {};
  int _activeSearches = 0;

  /// Emits the merged result list whenever any room's results change.
  Stream<List<GlobalSearchResult>> get results => _controller.stream;

  /// Whether any per-room search is still running.
  bool get currentlySearching => _activeSearches > 0;

  /// Starts searching [rooms] for [query]. Call once per instance.
  Future<void> start(Iterable<Room> rooms, String query) async {
    final roomList = rooms.toList();
    if (roomList.isEmpty) {
      _emit();
      return;
    }

    for (final room in roomList) {
      final session = await component.createSearchSession(room);
      _activeSearches++;
      final sub = session.startSearch(query).listen(
        (events) {
          _resultsByRoom[room.identifier] =
              events.map((e) => GlobalSearchResult(room, e)).toList();
          _emit();
        },
        onDone: () {
          _activeSearches--;
          _emit();
        },
        onError: (Object _) {
          _activeSearches--;
          _emit();
        },
      );
      _subs.add(sub);
    }
  }

  void _emit() {
    if (_controller.isClosed) return;
    _controller.add(mergeSearchResults<GlobalSearchResult>(
      _resultsByRoom.values,
      idOf: (r) => r.event.eventId,
      sortKey: (r) => r.event.originServerTs.millisecondsSinceEpoch,
    ));
  }

  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
    if (!_controller.isClosed) _controller.close();
  }
}
