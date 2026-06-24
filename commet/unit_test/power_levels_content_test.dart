import 'package:commet/utils/power_levels_content.dart';
import 'package:test/test.dart';

void main() {
  group('applyPowerLevelChanges', () {
    test('sets a top-level key', () {
      final result = applyPowerLevelChanges(
        {'ban': 50},
        [(key: 'ban', parent: null, powerLevel: 100)],
      );
      expect(result['ban'], 100);
    });

    test('sets a nested key under an existing parent map', () {
      final result = applyPowerLevelChanges(
        {
          'events': {'m.room.name': 50}
        },
        [(key: 'm.room.name', parent: 'events', powerLevel: 100)],
      );
      expect((result['events'] as Map)['m.room.name'], 100);
    });

    test('creates the parent map when it is missing', () {
      final result = applyPowerLevelChanges(
        {'state_default': 50},
        [(key: 'm.reaction', parent: 'events', powerLevel: 0)],
      );
      expect((result['events'] as Map)['m.reaction'], 0);
      expect(result['state_default'], 50);
    });

    test('applies multiple changes', () {
      final result = applyPowerLevelChanges(
        {
          'ban': 50,
          'events': {'m.room.name': 0}
        },
        [
          (key: 'ban', parent: null, powerLevel: 100),
          (key: 'm.room.name', parent: 'events', powerLevel: 50),
          (key: 'kick', parent: null, powerLevel: 50),
        ],
      );
      expect(result['ban'], 100);
      expect(result['kick'], 50);
      expect((result['events'] as Map)['m.room.name'], 50);
    });

    test('does not mutate the base map or its sub-maps', () {
      final base = {
        'ban': 50,
        'events': {'m.room.name': 0}
      };
      applyPowerLevelChanges(base, [
        (key: 'ban', parent: null, powerLevel: 100),
        (key: 'm.room.name', parent: 'events', powerLevel: 50),
      ]);

      expect(base['ban'], 50);
      expect((base['events'] as Map)['m.room.name'], 0);
    });

    test('preserves unrelated keys', () {
      final result = applyPowerLevelChanges(
        {
          'users_default': 0,
          'users': {'@a:b': 100},
          'events': {'m.room.topic': 50},
        },
        [(key: 'm.room.topic', parent: 'events', powerLevel: 100)],
      );
      expect(result['users_default'], 0);
      expect((result['users'] as Map)['@a:b'], 100);
      expect((result['events'] as Map)['m.room.topic'], 100);
    });
  });
}
