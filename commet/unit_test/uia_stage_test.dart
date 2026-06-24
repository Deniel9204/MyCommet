import 'package:commet/utils/uia_stage.dart';
import 'package:test/test.dart';

void main() {
  group('resolveUiaStage', () {
    test('password stage', () {
      expect(resolveUiaStage({'m.login.password'}), UiaStageKind.password);
    });

    test('dummy stage', () {
      expect(resolveUiaStage({'m.login.dummy'}), UiaStageKind.dummy);
    });

    test('sso stage', () {
      expect(resolveUiaStage({'m.login.sso'}), UiaStageKind.sso);
    });

    test('dummy is preferred over everything (no user input needed)', () {
      expect(
        resolveUiaStage({'m.login.password', 'm.login.sso', 'm.login.dummy'}),
        UiaStageKind.dummy,
      );
    });

    test('password is preferred over sso when both are offered', () {
      expect(
        resolveUiaStage({'m.login.sso', 'm.login.password'}),
        UiaStageKind.password,
      );
    });

    test('a stage we cannot drive maps to unsupported', () {
      expect(resolveUiaStage({'m.login.recaptcha'}), UiaStageKind.unsupported);
      expect(resolveUiaStage({'m.login.email.identity'}),
          UiaStageKind.unsupported);
    });

    test('empty next stages maps to unsupported (bail, do not loop)', () {
      expect(resolveUiaStage(<String>{}), UiaStageKind.unsupported);
    });
  });
}
