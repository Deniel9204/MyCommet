window.BENCHMARK_DATA = {
  "lastUpdate": 1782487219850,
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
      },
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
          "id": "7692e1bb63c322a19d2207d907b672bf63155639",
          "message": "Fix integration-test DB lifecycle and login settling (#235)\n\n* Reopen the DB isolate when its file was deleted (fix readonly DBMOVED)\n\nThe integration tests failed with SqliteException(1032) — \"attempt to write a\nreadonly database\":\n\n    [Matrix] Unable to clear database - SqliteException(1032)\n    [Matrix] Client initialization failed - SqliteException(1032)\n\nError 1032 is SQLITE_READONLY_DBMOVED: the database file was moved/deleted\nwhile a connection had it open. MultiDatabaseServer caches one DriftIsolate\nper database path and never evicts it, but the integration tests wipe the\ndatabase directory between their (sequentially-run) test files. The cached\nconnection then points at a deleted inode, so the next client init that clears\nor writes the database fails.\n\nReuse a cached connection only while its file still exists; otherwise drop the\nstale isolate and reopen against the fresh file. This was masked until now by\nthe login crash that failed the tests earlier (#232).\n\n* Don't pumpAndSettle through the login loading spinner in integration tests\n\nAfter the DB fix, login got further but failed with \"pumpAndSettle timed out\":\nthe login flow calls pumpAndSettle right after entering the homeserver and\nafter tapping login, but both show a loading spinner (homeserver lookup /\nlogging in) that animates continuously, so the frame never settles. The first\ntest then leaves a pending frame, cascading into !inTest / _pendingFrame\nbinding assertions on every later test.\n\nUse pump() at those points and rely on the existing waitFor() (which pumps a\nframe at a time and checks a condition) to advance until the login flow loads\nand the client logs in.",
          "timestamp": "2026-06-26T14:22:52+02:00",
          "tree_id": "177b152930b1c9838ec65f0e6bb46b3c9c8c4900",
          "url": "https://github.com/Deniel9204/MyCommet/commit/7692e1bb63c322a19d2207d907b672bf63155639"
        },
        "date": 1782477359894,
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
            "value": 1.7233235294117644,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Average Raster Time",
            "value": 5.893787878787877,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Worst Build Time",
            "value": 3.633,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Worst Raster Time",
            "value": 6.748,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 99th Percentile Build Time",
            "value": 3.633,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 90th Percentile Build Time",
            "value": 3.633,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 99th Percentile Raster Time",
            "value": 6.748,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 90th Percentile Raster Time",
            "value": 6.503,
            "unit": "ms"
          }
        ]
      },
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
          "id": "3867ad9782b6303a3a0afeae7c9dfadaff7dafa6",
          "message": "Fix unread indicator on homeservers without notification counts (#239)\n\nThe unread indicator used the matrix SDK's Room.isUnread, which is\n`notificationCount > 0 || markedUnread`. notification_count isn't sent by every\nhomeserver (notably Continuwuity), so the indicator never appeared there.\n\nFall back to the SDK's receipt-based hasNewMessages (which compares our own\nread receipt / its timestamp to the last event) when isUnread is false, so\nunread is detected from read receipts rather than server-provided counts. Mute\nis still respected: rooms set to dontNotify don't surface unread this way.",
          "timestamp": "2026-06-26T15:41:40+02:00",
          "tree_id": "9fb9632a47c755fcf0ea01226e05626ed43d3bdf",
          "url": "https://github.com/Deniel9204/MyCommet/commit/3867ad9782b6303a3a0afeae7c9dfadaff7dafa6"
        },
        "date": 1782482084812,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "TimelineViewer Scrolling - Timeline Event Build Count",
            "value": 504,
            "unit": "Builds"
          },
          {
            "name": "TimelineViewer Scrolling - Timeline Event Message Body Build Count",
            "value": 102,
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
            "value": 1.5542941176470588,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Average Raster Time",
            "value": 7.407030303030301,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Worst Build Time",
            "value": 3.297,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Worst Raster Time",
            "value": 12.456,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 99th Percentile Build Time",
            "value": 3.297,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 90th Percentile Build Time",
            "value": 3.297,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 99th Percentile Raster Time",
            "value": 12.456,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 90th Percentile Raster Time",
            "value": 10.07,
            "unit": "ms"
          }
        ]
      },
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
          "id": "d7c8e38c3667f293e26172609736e146bcc35a77",
          "message": "Fix slow image loading: use cached push rule in hasUnreadMessages (#240)\n\nThe unread-indicator fix (#76) called _matrixRoom.pushRuleState directly in\nhasUnreadMessages. That getter scans the whole account's push rules and is\nexpensive enough that MatrixRoom already caches it in _pushRule (see the\n\"becoming an expensive operation for ui stuff\" note on the pushRule getter).\nhasUnreadMessages runs for every room on every list rebuild, so the uncached\ncall starved the UI thread and made space/room/avatar images load very slowly.\n\nUse the cached pushRule getter instead. Same unread behaviour, cheap per call.",
          "timestamp": "2026-06-26T16:10:25+02:00",
          "tree_id": "d143c7ad3a7a2a665b7c19a64a186f4d43ba8944",
          "url": "https://github.com/Deniel9204/MyCommet/commit/d7c8e38c3667f293e26172609736e146bcc35a77"
        },
        "date": 1782484000162,
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
            "value": 1.4946470588235297,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Average Raster Time",
            "value": 5.256875,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Worst Build Time",
            "value": 3.757,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Worst Raster Time",
            "value": 6.299,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 99th Percentile Build Time",
            "value": 3.757,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 90th Percentile Build Time",
            "value": 3.757,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 99th Percentile Raster Time",
            "value": 6.299,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 90th Percentile Raster Time",
            "value": 5.857,
            "unit": "ms"
          }
        ]
      },
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
          "id": "9d955d43b13d6a89b9ced90698ba78f642f6408c",
          "message": "Fix macOS crash on call start: add microphone/camera permission (#241)\n\nThe macOS app crashed (SIGABRT, TCC privacy violation) the moment a voice or\nvideo call started — the .ips report shows __TCC_CRASHING_DUE_TO_PRIVACY_VIOLATION__\nbecause WebRTC requests the microphone but Info.plist had no usage description.\nThis was unconditional: it had nothing to do with TURN/the call-error dialog;\nany call crashes because mic access happens during call setup.\n\n- Add NSMicrophoneUsageDescription and NSCameraUsageDescription to Info.plist\n  (macOS hard-kills the app without these).\n- Add com.apple.security.device.audio-input and .device.camera entitlements to\n  the Release and DebugProfile entitlements (the app is sandboxed, so WebRTC\n  can't open the mic/camera without them).",
          "timestamp": "2026-06-26T17:07:38+02:00",
          "tree_id": "23a536a8d5e45f2a5998ab13d210d1187580715d",
          "url": "https://github.com/Deniel9204/MyCommet/commit/9d955d43b13d6a89b9ced90698ba78f642f6408c"
        },
        "date": 1782487218946,
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
            "value": 1.5459411764705884,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Average Raster Time",
            "value": 5.763062499999999,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Worst Build Time",
            "value": 3.557,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Worst Raster Time",
            "value": 8.043,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 99th Percentile Build Time",
            "value": 3.557,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 90th Percentile Build Time",
            "value": 3.557,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 99th Percentile Raster Time",
            "value": 8.043,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 90th Percentile Raster Time",
            "value": 6.491,
            "unit": "ms"
          }
        ]
      }
    ]
  }
}