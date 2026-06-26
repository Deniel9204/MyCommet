window.BENCHMARK_DATA = {
  "lastUpdate": 1782477318569,
  "repoUrl": "https://github.com/Deniel9204/MyCommet",
  "entries": {
    "Benchmark": [
      {
        "commit": {
          "author": {
            "email": "5380799+Deniel9204@users.noreply.github.com",
            "name": "Akumul",
            "username": "Deniel9204"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "82a492bf764904c1ef2b1f3cfaf49a2bfa0ddd65",
          "message": "Fix benchmark drive crashes and ffmpeg-kill step (#234)\n\n* Don't crash room permission checks when there's no logged-in user\n\nThe benchmark drive crashed on every timeline entry:\n\n    Null check operator used on a null value\n    #0 Room.ownPowerLevel (matrix/src/room.dart:2130)   // client.userID!\n    #1 Room.canRedact\n    #2 MatrixRoomPermissions.canDeleteOtherUserMessages\n    #3 MatrixTimeline.canDeleteEvent\n    #4 new TimelineEventMenu\n\nThe matrix SDK's power-level checks all resolve `ownPowerLevel`, which does\n`client.userID!` and throws when the client isn't logged in. The render\nbenchmark uses a mock client that never logs in (no userID), so building any\ntimeline entry's menu threw, the list had no valid children, and the drive\nthen failed in scrollUntilVisible.\n\nGuard every power-level-dependent getter in MatrixRoomPermissions with a\nlogged-in check: an unidentified user has no permissions, so return false\ninstead of dereferencing a null userID. No behaviour change for a logged-in\nuser (the SDK call is only skipped when userID is null).\n\n* Guard canPinMessages against a null userID too\n\nThe benchmark's next crash after the permissions guard was\nMatrixPinnedMessagesComponent.canPinMessages -> matrixRoom.canChangeStateEvent\n-> ownPowerLevel -> client.userID!. It's the timeline event menu's only other\npower-level check (canEndPoll uses self, canUserEditMessages returns true), so\nguard it the same way: no logged-in user means it can't pin.\n\n* Guard availableEmoji against unloaded UnicodeEmojis.packs\n\nThe benchmark's next crash after the permission guards was the reaction\npicker: availableEmoji -> _getAvailablePacks -> UnicodeEmojis.packs!, which is\nnull until the emoji data is loaded at startup (the bare benchmark never loads\nit). Skip the unicode packs when they're not loaded instead of force-\nunwrapping; this also hardens any access before load in the real app.\n\n* Don't fail the benchmark step when ffmpeg already exited\n\nWith the drive crashes fixed, the benchmark now passes (\"All tests passed!\")\nbut the step still failed: `kill $(pgrep ffmpeg)` ran with no PID (ffmpeg had\nalready exited, so video.mkv was never produced either), which errors with\nexit 2 and failed the step *after* a passing run — so \"Store benchmark result\"\nwas skipped. Use `pkill -x ffmpeg || true` so the cleanup can't fail the step,\nand the real drive exit code is what's returned.",
          "timestamp": "2026-06-26T14:22:50+02:00",
          "tree_id": "232f50177320f3db354f01ae43dd5390385ab6c2",
          "url": "https://github.com/Deniel9204/MyCommet/commit/82a492bf764904c1ef2b1f3cfaf49a2bfa0ddd65"
        },
        "date": 1782477318071,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "TimelineViewer Scrolling - Timeline Event Build Count",
            "value": 505,
            "unit": "Builds"
          },
          {
            "name": "TimelineViewer Scrolling - Timeline Event Message Body Build Count",
            "value": 103,
            "unit": "Builds"
          },
          {
            "name": "TimelineViewer Scrolling - Timeline Event Message Reply Body Build Count",
            "value": 90,
            "unit": "Builds"
          },
          {
            "name": "TimelineViewer Scrolling - Timeline Event Message Url Preview Build Count",
            "value": 0,
            "unit": "Builds"
          },
          {
            "name": "TimelineViewer Scrolling - Average Build Time",
            "value": 1.5875000000000001,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Average Raster Time",
            "value": 5.5132812499999995,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Worst Build Time",
            "value": 3.397,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Worst Raster Time",
            "value": 6.831,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 99th Percentile Build Time",
            "value": 3.397,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 90th Percentile Build Time",
            "value": 3.397,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 99th Percentile Raster Time",
            "value": 6.831,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 90th Percentile Raster Time",
            "value": 6.169,
            "unit": "ms"
          }
        ]
      }
    ]
  }
}