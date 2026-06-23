import 'package:commet/client/room.dart';
import 'package:commet/ui/molecules/space_selector.dart';
import 'package:commet/utils/rng.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:commet/main.dart';
import 'package:integration_test/integration_test.dart';

import '../extensions/common_flows.dart';
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
  await tester.tap(find
      .widgetWithText(tiamat.Button, T.current.promptConfirmRoomCreation)
      .last);

  await tester.pumpAndSettle();
}

Future<void> _setSpaceName(WidgetTester tester, String spaceName) async {
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
  await tester.tap(find.byType(tiamat.DropdownSelector<RoomVisibility?>).last);

  await tester.pumpAndSettle();

  await tester.tap(find
      .widgetWithText(tiamat.Text, T.current.roomVisibilityPrivateExplanation)
      .last);

  await tester.pumpAndSettle();
}

Future<void> _setPublic(WidgetTester tester) async {
  await tester.tap(find.byType(tiamat.DropdownSelector<RoomVisibility?>).last);

  await tester.pumpAndSettle();

  await tester.tap(find
      .widgetWithText(tiamat.Text, T.current.roomVisibilityPublicExplanation)
      .last);

  await tester.pumpAndSettle();
}

Future<void> _openSpaceCreator(WidgetTester tester, App app) async {
  await tester.pumpWidget(app);

  await tester.login(app);

  await tester.pumpAndSettle();

  // Open the "add space" menu from the side navigation bar.
  await tester.dragUntilVisible(
      find.widgetWithIcon(tiamat.ImageButton, Icons.add),
      find.byType(SpaceSelector),
      const Offset(0, 50));

  await tester.tap(find.widgetWithIcon(tiamat.ImageButton, Icons.add).last);

  await tester.pumpAndSettle();

  // On the wide (desktop) layout the GetOrCreateRoom dialog shows a list of
  // creators; we need to pick "Space" and then press next to open the form.
  // On the narrow (mobile) layout the space form may be shown directly, so
  // these steps are conditional.
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
}
