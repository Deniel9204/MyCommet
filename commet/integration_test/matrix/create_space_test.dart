import 'package:commet/client/room.dart';
import 'package:commet/ui/molecules/space_selector.dart';
import 'package:commet/ui/pages/get_or_create_room/get_or_create_room.dart';
import 'package:commet/ui/pages/get_or_create_room/room_creator.dart';
import 'package:commet/utils/rng.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:commet/main.dart';
import 'package:integration_test/integration_test.dart';

import '../extensions/common_flows.dart';
import '../extensions/wait_for.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import 'package:commet/generated/l10n.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Create Private Space', (WidgetTester tester) async {
    await tester.clearUserData();

    var app = await tester.setupApp();
    await _openSpaceCreator(tester, app);
    await _setPrivate(tester);

    String spaceName = "Private Space ${RandomUtils.getRandomString(8)}";
    await _setSpaceName(tester, spaceName);
    await _confirmCreateSpace(tester);

    var client = app.clientManager.clients.first;

    expect(client.spaces.any((element) => element.displayName == spaceName),
        isTrue);
    expect(
        client.spaces
            .firstWhere((element) => element.displayName == spaceName)
            .visibility,
        equals(RoomVisibilityPrivate()));

    await app.clientManager.close();
    await tester.clean();
  });

  testWidgets('Create Public Space', (WidgetTester tester) async {
    await tester.clearUserData();

    var app = await tester.setupApp();
    await _openSpaceCreator(tester, app);
    await _setPublic(tester);

    String spaceName = "Public Space ${RandomUtils.getRandomString(8)}";
    await _setSpaceName(tester, spaceName);
    await _confirmCreateSpace(tester);

    var client = app.clientManager.clients.first;

    expect(client.spaces.any((element) => element.displayName == spaceName),
        isTrue);
    expect(
        client.spaces
            .firstWhere((element) => element.displayName == spaceName)
            .visibility,
        equals(RoomVisibilityPublic()));

    await app.clientManager.close();
    await tester.clean();
  });
}

Future<void> _confirmCreateSpace(WidgetTester tester) async {
  final confirm = find
      .widgetWithText(tiamat.Button, T.current.promptConfirmRoomCreation)
      .last;

  // The confirm button is wrapped in IgnorePointer(ignoring: !valid); it only
  // becomes tappable once every field (including a non-empty room name) is
  // valid, so wait for the form to be ready before tapping.
  await tester.waitFor(() => find
      .widgetWithText(tiamat.Button, T.current.promptConfirmRoomCreation)
      .evaluate()
      .isNotEmpty);

  await tester.tap(confirm);

  await tester.pumpAndSettle();
}

Future<void> _setSpaceName(WidgetTester tester, String spaceName) async {
  await tester.waitFor(() => find
      .widgetWithText(TextField, T.current.promptRoomName)
      .evaluate()
      .isNotEmpty);

  await tester.enterText(
      find
          .widgetWithText(
            TextField,
            T.current.promptRoomName,
          )
          .last,
      spaceName);

  await tester.pumpAndSettle();
}

Future<void> _setPrivate(WidgetTester tester) async {
  await _selectVisibility(tester, T.current.roomVisibilityPrivateExplanation);
}

Future<void> _setPublic(WidgetTester tester) async {
  await _selectVisibility(tester, T.current.roomVisibilityPublicExplanation);
}

/// Opens the visibility DropdownSelector and taps the menu entry whose
/// subtitle matches [explanation]. The selector is part of the
/// RoomCreatorWidget form; its items render the explanation via
/// tiamat.Text.labelLow inside a dropdown_button2 overlay route.
Future<void> _selectVisibility(WidgetTester tester, String explanation) async {
  await tester.waitFor(() => find
      .byType(tiamat.DropdownSelector<RoomVisibility?>)
      .evaluate()
      .isNotEmpty);

  await tester.tap(find.byType(tiamat.DropdownSelector<RoomVisibility?>).last);

  // The dropdown_button2 menu opens in its own overlay route; wait for the
  // route's transition to finish so the menu items are hit-testable.
  await tester.pumpAndSettle();

  await tester.waitFor(() =>
      find.widgetWithText(tiamat.Text, explanation).evaluate().isNotEmpty);

  await tester.tap(find.widgetWithText(tiamat.Text, explanation).last);

  await tester.pumpAndSettle();
}

Future<void> _openSpaceCreator(WidgetTester tester, App app) async {
  await tester.pumpWidget(app);

  await tester.login(app);

  await tester.pumpAndSettle();

  // Open the "add space" menu from the side navigation bar footer. The button
  // is a tiamat.ImageButton with Icons.add inside the SpaceSelector.
  await tester.dragUntilVisible(
      find.widgetWithIcon(tiamat.ImageButton, Icons.add),
      find.byType(SpaceSelector),
      const Offset(0, 50));

  await tester.tap(find.widgetWithIcon(tiamat.ImageButton, Icons.add).last);

  await tester.pumpAndSettle();

  // The CI integration suite runs the Linux desktop build, so GetOrCreateRoom
  // takes the desktop branch: the dialog lists the room creators on the left
  // with the "Join Room" entry pre-selected. We must select the "Space"
  // creator entry and then press "Next" to open the creation form dialog.
  await tester.waitFor(() =>
      find.byType(GetOrCreateRoom).evaluate().isNotEmpty ||
      find
          .widgetWithText(tiamat.TextButton, T.current.labelRoomTypeSpace)
          .evaluate()
          .isNotEmpty);

  final spaceEntry =
      find.widgetWithText(tiamat.TextButton, T.current.labelRoomTypeSpace);
  if (spaceEntry.evaluate().isNotEmpty) {
    await tester.tap(spaceEntry.last);
    await tester.pumpAndSettle();
  }

  final nextButton = find.widgetWithText(tiamat.Button, T.current.promptNext);
  if (nextButton.evaluate().isNotEmpty) {
    await tester.tap(nextButton.last);
    await tester.pumpAndSettle();
  }

  // Wait for the creation form dialog (RoomCreatorWidget) to appear before the
  // caller starts filling in fields.
  await tester.waitFor(() =>
      find.byType(RoomCreatorWidget).evaluate().isNotEmpty ||
      find
          .byType(tiamat.DropdownSelector<RoomVisibility?>)
          .evaluate()
          .isNotEmpty);
}
