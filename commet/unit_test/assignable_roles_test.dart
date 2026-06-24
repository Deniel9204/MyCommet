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
}
