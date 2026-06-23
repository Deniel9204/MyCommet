import 'package:commet/ui/pages/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

import '../extensions/wait_for.dart';
import '../extensions/common_flows.dart';
import 'package:commet/generated/l10n.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test Matrix Login Success', (WidgetTester tester) async {
    await tester.clearUserData();
    // Build our app and trigger a frame.

    var app = await tester.setupApp();
    await tester.pumpWidget(app);

    await tester.login(app);

    await tester.waitFor(() => app.clientManager.isLoggedIn(),
        timeout: const Duration(seconds: 5), skipPumpAndSettle: true);
    expect(app.clientManager.isLoggedIn(), equals(true));

    await app.clientManager.close();
    await tester.clean();
  });

  testWidgets('Test Matrix Login Invalid', (WidgetTester tester) async {
    var username = "invalidUser";
    var password = "InvalidPassword!";

    // Build our app and trigger a frame.
    var app = await tester.setupApp();
    await tester.pumpWidget(app);

    await tester.waitFor(() => find.byType(LoginPage).evaluate().isNotEmpty);

    // Enter the homeserver first; the username/password fields and the login
    // button only appear once the homeserver's login flow has loaded. Use the
    // shared homeserver getter so the http:// scheme is included.
    await tester.enterText(find.byType(TextField).at(0), tester.homeserver);
    await tester.pumpAndSettle();

    await tester.waitFor(() => find.byType(TextField).evaluate().length >= 3);

    await tester.enterText(find.byType(TextField).at(1), username);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(2), password);
    await tester.pumpAndSettle();

    // The submit control is a tiamat.Button labelled with promptSubmitLogin,
    // not a Material ElevatedButton.
    var button =
        find.widgetWithText(tiamat.Button, T.current.promptSubmitLogin);

    await tester.tap(button);

    // An invalid login surfaces as an AdaptiveDialog. On the Linux desktop
    // build used in CI this renders via PopupDialog, whose title is the
    // literal "Login failed" string passed by LoginPageState.doLogin. The
    // dialog body holds the server's error message rather than
    // messageLoginFailed, so assert against the stable title instead.
    await tester.waitFor(() => find.text("Login failed").evaluate().isNotEmpty,
        skipPumpAndSettle: false, timeout: const Duration(seconds: 5));
    await tester.pumpFrames(app, const Duration(seconds: 1));
    expect(app.clientManager.isLoggedIn(), equals(false));

    await app.clientManager.close();
    await tester.clean();
  });
}
