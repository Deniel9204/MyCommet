import 'package:commet/utils/assignable_roles.dart';
import 'package:test/test.dart';

void main() {
  group('assignableRoleLevels', () {
    const allRoles = [100, 50, 25, 0];

    test('an admin can assign every role at or below admin', () {
      expect(assignableRoleLevels(allRoles, 100), [100, 50, 25, 0]);
    });

    test('a moderator cannot assign admin', () {
      expect(assignableRoleLevels(allRoles, 50), [50, 25, 0]);
    });

    test('your own level is assignable (inclusive)', () {
      expect(assignableRoleLevels(allRoles, 50), contains(50));
    });

    test('a plain member can only assign member', () {
      expect(assignableRoleLevels(allRoles, 0), [0]);
    });

    test('a custom level between roles assigns only what it meets', () {
      expect(assignableRoleLevels(allRoles, 30), [25, 0]);
    });

    test('order is preserved', () {
      expect(assignableRoleLevels([0, 50, 100], 100), [0, 50, 100]);
    });

    test('an owner-level user can assign everything', () {
      expect(assignableRoleLevels([150, 100, 50, 0], 150), [150, 100, 50, 0]);
    });
  });

  group('availableRoleLevels', () {
    // A room v12 creator's own power level is effectively infinite.
    const creatorPower = 9007199254740991;

    test('owner (150) is offered in room version 12', () {
      expect(availableRoleLevels(12, creatorPower), [150, 100, 50, 0]);
    });

    test('owner (150) is not offered below room version 12', () {
      expect(availableRoleLevels(11, creatorPower), [100, 50, 0]);
      expect(availableRoleLevels(1, creatorPower), [100, 50, 0]);
    });

    test('a null room version is treated as pre-v12 (no owner)', () {
      expect(availableRoleLevels(null, creatorPower), [100, 50, 0]);
    });

    test('an admin in a v12 room cannot assign owner', () {
      expect(availableRoleLevels(12, 100), [100, 50, 0]);
    });

    test('a moderator only sees moderator and member', () {
      expect(availableRoleLevels(12, 50), [50, 0]);
    });

    test('calendar moderator (25) is included only for calendar rooms', () {
      expect(availableRoleLevels(11, creatorPower, hasCalendar: true),
          [100, 50, 25, 0]);
      expect(availableRoleLevels(11, creatorPower), [100, 50, 0]);
    });

    test('calendar moderator is filtered out below its level', () {
      expect(availableRoleLevels(11, 10, hasCalendar: true), [0]);
      expect(availableRoleLevels(11, 25, hasCalendar: true), [25, 0]);
    });
  });
}
