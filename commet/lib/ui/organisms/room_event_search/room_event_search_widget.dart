import 'dart:async';

import 'package:commet/client/client.dart';
import 'package:commet/client/components/event_search/event_search_component.dart';
import 'package:commet/client/components/event_search/global_event_search.dart';
import 'package:commet/client/timeline_events/timeline_event.dart';
import 'package:commet/ui/molecules/timeline_events/timeline_event_view_single.dart';
import 'package:commet/utils/common_strings.dart';
import 'package:commet/utils/debounce.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_list/implicitly_animated_list.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class RoomEventSearchWidget extends StatefulWidget {
  const RoomEventSearchWidget(
      {required this.room, this.close, this.onEventClicked, super.key});
  final Room room;
  final void Function()? close;
  final void Function(String eventId)? onEventClicked;

  @override
  State<RoomEventSearchWidget> createState() => _RoomEventSearchWidgetState();
}

class _RoomEventSearchWidgetState extends State<RoomEventSearchWidget> {
  TextEditingController controller = TextEditingController();
  EventSearchSession? searchSession;
  GlobalEventSearch? globalSearch;

  StreamSubscription? currentSubscription;
  List<GlobalSearchResult>? currentResults;

  Debouncer debouncer = Debouncer(delay: const Duration(seconds: 1));

  bool loading = false;
  bool searchAllRooms = false;

  @override
  void dispose() {
    currentSubscription?.cancel();
    globalSearch?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var color = Theme.of(context).colorScheme.surfaceContainer;
    return Column(
      children: [
        tiamat.Tile.low(
          child: Row(
            children: [
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: TextField(
                    autofocus: true,
                    onChanged: onTextChanged,
                    style: Theme.of(context).textTheme.bodyMedium!,
                    controller: controller,
                    decoration: InputDecoration(
                        hintText: CommonStrings.promptSearch,
                        prefix: const SizedBox(
                          width: 10,
                        ),
                        suffix: loading
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ))
                            : null,
                        contentPadding: const EdgeInsets.fromLTRB(8, 0, 8, 0)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                child: tiamat.IconButton(
                  icon: searchAllRooms ? Icons.travel_explore : Icons.search,
                  size: 20,
                  onPressed: toggleScope,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: tiamat.IconButton(
                  icon: Icons.close,
                  size: 20,
                  onPressed: widget.close,
                ),
              )
            ],
          ),
        ),
        if (currentResults != null)
          Flexible(
            child: ClipRect(
              child: ImplicitlyAnimatedList<GlobalSearchResult>(
                itemEquality: (a, b) => a.event.eventId == b.event.eventId,
                itemData: currentResults!,
                padding: EdgeInsets.all(0),
                itemBuilder: (context, data) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Material(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () =>
                                widget.onEventClicked?.call(data.event.eventId),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (searchAllRooms)
                                    Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(4, 0, 0, 2),
                                      child: tiamat.Text.labelLow(
                                          data.room.displayName),
                                    ),
                                  TimelineEventViewSingle(
                                      room: data.room, event: data.event),
                                ],
                              ),
                            ),
                          )),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  void toggleScope() {
    setState(() => searchAllRooms = !searchAllRooms);
    if (controller.text.trim().isNotEmpty) {
      onTextChanged(controller.text);
    }
  }

  void onTextChanged(String value) {
    _resetSearch();

    if (value.trim().isEmpty) {
      setState(() {
        debouncer.cancel();
        loading = false;
      });
    } else {
      debouncer.run(() => startSearch(value));
      setState(() {
        loading = debouncer.running;
      });
    }
  }

  void _resetSearch() {
    currentSubscription?.cancel();
    currentSubscription = null;
    globalSearch?.dispose();
    globalSearch = null;
    searchSession = null;
    setState(() {
      currentResults = null;
    });
  }

  void startSearch(String value) async {
    final component = widget.room.client.getComponent<EventSearchComponent>();
    if (component == null) return;

    if (searchAllRooms) {
      var search = GlobalEventSearch(component);
      globalSearch = search;
      currentSubscription = search.results.listen(onGlobalResults);
      await search.start(widget.room.client.rooms, value);
    } else {
      var session = await component.createSearchSession(widget.room);
      searchSession = session;
      currentSubscription = session.startSearch(value).listen(onRoomResults);
    }
  }

  void onRoomResults(List<TimelineEvent<Client>> results) {
    setState(() {
      loading = searchSession?.currentlySearching == true;
      currentResults =
          results.map((e) => GlobalSearchResult(widget.room, e)).toList();
    });
  }

  void onGlobalResults(List<GlobalSearchResult> results) {
    setState(() {
      loading = globalSearch?.currentlySearching == true;
      currentResults = results;
    });
  }
}
