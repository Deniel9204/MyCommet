import 'package:commet/utils/enter_key_action.dart';
import 'package:test/test.dart';

void main() {
  group('resolveEnterAction', () {
    test('initial Enter press sends', () {
      expect(
        resolveEnterAction(
            isInitialPress: true,
            shiftPressed: false,
            hasAutofillSelection: false),
        EnterAction.send,
      );
    });

    test('auto-repeat Enter is swallowed, not sent again (#868)', () {
      expect(
        resolveEnterAction(
            isInitialPress: false,
            shiftPressed: false,
            hasAutofillSelection: false),
        EnterAction.swallow,
      );
    });

    test('shift+Enter is ignored so a newline is inserted', () {
      expect(
        resolveEnterAction(
            isInitialPress: true,
            shiftPressed: true,
            hasAutofillSelection: false),
        EnterAction.ignore,
      );
    });

    test('shift+Enter on repeat is still ignored (newline can repeat)', () {
      expect(
        resolveEnterAction(
            isInitialPress: false,
            shiftPressed: true,
            hasAutofillSelection: false),
        EnterAction.ignore,
      );
    });

    test('Enter with a highlighted suggestion applies it on first press', () {
      expect(
        resolveEnterAction(
            isInitialPress: true,
            shiftPressed: false,
            hasAutofillSelection: true),
        EnterAction.applyAutofill,
      );
    });

    test('repeat Enter with a suggestion is swallowed, not re-applied', () {
      expect(
        resolveEnterAction(
            isInitialPress: false,
            shiftPressed: false,
            hasAutofillSelection: true),
        EnterAction.swallow,
      );
    });

    test('autofill selection takes precedence over shift', () {
      expect(
        resolveEnterAction(
            isInitialPress: true,
            shiftPressed: true,
            hasAutofillSelection: true),
        EnterAction.applyAutofill,
      );
    });
  });
}
