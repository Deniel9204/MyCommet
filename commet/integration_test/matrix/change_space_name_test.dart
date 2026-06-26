import 'package:commet/ui/atoms/space_header.dart';
import 'package:commet/ui/atoms/space_icon.dart';
import 'package:commet/ui/organisms/space_summary/space_summary_view.dart';
import 'package:commet/ui/pages/main/main_page.dart';
import 'package:commet/ui/pages/settings/desktop_settings_page.dart';
import 'package:commet/utils/rng.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:tiamat/tiamat.dart' as tiamat;
import '../extensions/common_flows.dart';
import '../extensions/wait_for.dart';
import 'package:commet/generated/l10n.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test Matrix Login Success', (WidgetTester tester) async {
    await tester.clearUserData();
    // Build our app and trigger a frame.
    var app = await tester.setupApp();
    await tester.pumpWidget(app);
    await tester.login(app);

    await _selectSpace(tester);
    MainPageState chatPage = tester.state(find.byType(MainPage));

    String newName = "New Space Name ${RandomUtils.getRandomString(10)}";
    var space = chatPage.currentSpace!;
    String name = space.displayName;

    expect(name, isNot(newName));

    await _openSpaceSettings(tester);
    await _openSpaceAppearanceSettings(tester);

    await tester.tap(find.widgetWithIcon(tiamat.IconButton, Icons.edit));
    await tester.pumpBounded();

    await tester.enterText(find.byType(TextField), newName);
    await tester.pumpBounded();

    await tester.tap(find.widgetWithIcon(tiamat.IconButton, Icons.check));
    await tester.pumpBounded();

    await tester.tap(find.byKey(DesktopSettingsPageState.backButtonKey));
    await tester.pumpBounded();

    // The rename round-trips to the server and applies on the next sync, so
    // wait for the space's name to update before asserting.
    await tester.waitFor(() => space.displayName == newName);

    expect(space.displayName, equals(newName));

    // The space header rebuilds in response to the space's onUpdate stream,
    // which fires after the (async) rename round-trip completes, so wait for
    // the new name to appear rather than asserting immediately.
    await tester.waitFor(
        () => find.widgetWithText(SpaceHeader, newName).evaluate().isNotEmpty);

    expect(find.widgetWithText(SpaceHeader, newName).evaluate().isNotEmpty,
        isTrue);
  });
}

Future<void> _selectSpace(WidgetTester tester) async {
  // Spaces are loaded from the client asynchronously after login, so the side
  // navigation bar may not have rendered any SpaceIcon yet. Wait for at least
  // one to appear before tapping it.
  await tester.waitFor(() => find.byType(SpaceIcon).evaluate().isNotEmpty);

  await tester.tap(find.byType(SpaceIcon).first);
  await tester.pumpBounded();
}

Future<void> _openSpaceSettings(WidgetTester tester) async {
  // SpaceSummaryView reuses the same key for both the invite button and the
  // settings button, and when the user can invite members both are rendered.
  // The settings button is built last in the row, so take the last match.
  await tester.waitFor(() => find
      .byKey(SpaceSummaryViewState.spaceSettingsButtonKey)
      .evaluate()
      .isNotEmpty);

  await tester
      .tap(find.byKey(SpaceSummaryViewState.spaceSettingsButtonKey).last);
  await tester.pumpBounded();
}

Future<void> _openSpaceAppearanceSettings(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(
      tiamat.TextButton, T.current.labelSpaceAppearanceSettings));
  await tester.pumpBounded();
}
