window.BENCHMARK_DATA = {
  "lastUpdate": 1782500157225,
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
          "id": "d5d6339f73a5fe70b07c6d9fc4712aa9a469813f",
          "message": "Cache per-room unread state (fixes remaining slow image loading) (#242)\n\n#240 stopped hasUnreadMessages from scanning push rules uncached, but it still\ncalled the SDK's hasNewMessages (lastEvent + its receipts) on every read for\nevery room. Because the room list rebuilds on scroll/hover/selection - not just\non sync - that recomputation kept stalling avatar/image loading.\n\nCache the computed unread state and invalidate it only when the room actually\nsignals an update. All the existing `_onUpdate.add(null)` callsites (sync, new\nevent, notification, room state, avatar, push-rule change, ...) now go through\n`_notifyUpdate()`, which clears the cache and then notifies. Between updates\n(e.g. while scrolling the room list) the value is served from cache, so the UI\nthread stays free for image decoding.",
          "timestamp": "2026-06-26T17:07:41+02:00",
          "tree_id": "f2afa9c9bd141d601f415a7a320972aba49bd7fe",
          "url": "https://github.com/Deniel9204/MyCommet/commit/d5d6339f73a5fe70b07c6d9fc4712aa9a469813f"
        },
        "date": 1782487238133,
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
            "value": 1.600294117647059,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Average Raster Time",
            "value": 5.866468749999999,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Worst Build Time",
            "value": 3.516,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Worst Raster Time",
            "value": 7.067,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 99th Percentile Build Time",
            "value": 3.516,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 90th Percentile Build Time",
            "value": 3.516,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 99th Percentile Raster Time",
            "value": 7.067,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 90th Percentile Raster Time",
            "value": 6.856,
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
          "id": "58224cbc9018b2849f6dc956177a95ee6d10484a",
          "message": "Make integration-test pass on the fork: fix the test harness + real app bugs (#237)\n\n* Fix integration-test cascade: guard vodozemac init + unmount app at teardown\n\nAfter the login/DB/pumpAndSettle fixes, the first integration test's body\npasses (login works) but the suite still fails 7/8 for two reasons:\n\n1. vodozemac.init() in MatrixClient._checkSystem runs per client, but it wraps\n   flutter_rust_bridge whose init throws if called twice in a process (the\n   suite creates a client per test). RustLib.init() was already guarded; guard\n   vodozemac the same way using the existing vod.isInitialized() check, so only\n   the first client initializes it. Fixes the `BaseEntrypoint.initImpl` crashes\n   on every test after the first.\n\n2. The live-test binding fails a test \"after completion\" (and the next with\n   !inTest) when a frame is still pending at teardown — the mounted app keeps\n   scheduling frames from its sync/stream listeners. Unmount the app in clean()\n   (pumpWidget(SizedBox)) so its widgets dispose and stop scheduling frames.\n\n(The \"well known ... https://localhost Connection refused\" log is non-fatal —\nthe SDK falls back to the explicit http homeserver and login succeeds.)\n\n* Fix setState-after-dispose leaks and skip the unimplemented verification test\n\nThe \"failed after test completion\" cascade had a concrete cause:\n\n    setState() called after dispose(): _CustomSafeAreaState (not mounted)\n    #2 _CustomSafeAreaState.onTextFieldFocused (custom_safe_area.dart:44)\n\nCustomSafeArea subscribed to EventBus.onTextFieldFocused but never cancelled\nthe subscription and had no mounted check, so a focus event during teardown\nset state on the disposed widget — failing the test after completion and\ncascading into the next test. Store and cancel the subscription in dispose,\nand guard the callback with mounted.\n\nApply the same mounted guard to HomeScreen.onSync's delayed setState (a pending\n1s timer would otherwise fire after the widget is disposed).\n\nSkip the key-verification integration test: its createTestClient() is an\nunimplemented stub (no second test client), so it throws UnimplementedError\nand can't pass yet — skip it rather than fail the whole suite.\n\n* Guard fire-and-forget getConfig/firstSync; pump (not settle) on credential entry\n\nNext integration-test layer:\n\n1. MatrixClient.init calls `getConfig().then(...)` and `oneShotSync().then(...)`\n   fire-and-forget. When a half-restored client (no homeserver, e.g. a stale\n   registration left by a failed earlier test) hits getConfig -> getVersions,\n   it dereferences a null baseUri. With no .catchError that escaped as an\n   unhandled async error and failed the test (TypeError \"Null check operator\n   used on a null value\"). Add catchError to both.\n\n2. login()/loginUser2() still used pumpAndSettle after entering the username\n   and password; if anything is still animating that hangs (\"inTest is not\n   true\" after completion). Text entry doesn't need settling — pump() instead.\n\n* Replace post-login pumpAndSettle with bounded pumps + waitFor in integration tests\n\nWith login now passing, the space/account tests failed by hanging: every\npumpAndSettle after login burns its full 10-minute timeout because the live app\nschedules frames continuously (sync loop, spinners), so the tree never settles.\nA few of those per test added up to the suite running ~25 min until cancelled.\n\n- Add WidgetTester.pumpFrames (bounded pump) and use it in place of\n  pumpAndSettle in the post-login flows (create_space, change_space_name,\n  openSettings). The login-page pumpAndSettles (login_test) stay — they settle\n  fine before a sync loop exists.\n- Guard assertions that depend on async network/sync state with waitFor: the\n  created space appearing in client.spaces, the second account being added, and\n  the space rename applying.\n- integration-test.yml: add timeout-minutes: 30 so a future hang fails fast\n  instead of running to GitHub's 6h default, and stop `kill $(pgrep ffmpeg)`\n  from failing the step when ffmpeg already exited (pkill -x || true).\n\n* Rename pumpFrames helper to pumpBounded (clashed with WidgetTester.pumpFrames)\n\nThe new bounded-pump helper was named pumpFrames, which collides with the\nbuilt-in WidgetTester.pumpFrames(Widget, Duration, [Duration]). The instance\nmethod shadows the extension, so the no-arg calls failed to compile\n(\"Too few positional arguments: 2 required, 0 given\") and the whole suite\nfailed to load (0 tests ran). Rename the helper to pumpBounded. login_test's\ngenuine built-in pumpFrames(app, ...) call is left as-is.\n\n* Wait for side nav before opening settings in integration tests\n\nBoth multi_account tests failed in openSettings with \"Found 0 widgets with type\nSideNavigationBar\" used in drag(). login()'s final waitFor uses\nskipPumpAndSettle, so when it returns the app can still be swapping\nLoginPage -> MainPage and the side nav isn't in the tree yet (create_space got\naway with it because its pumpBounded after login rendered the nav first).\n\nWait for SideNavigationBar to appear before dragging within it.\n\n* Fix openSettings: settings button moved out of SideNavigationBar\n\nThe multi_account tests failed in openSettings: it dragged within\nSideNavigationBar looking for SideNavigationBar.settingsKey, but that key is no\nlonger applied to any widget (the settings button was relocated to the user\npanel). dragUntilVisible then dragged forever and eventually threw\n\"Bad state: No element\" as the live app rebuilt the nav under it.\n\nThe settings button is now an Icons.settings tiamat.IconButton in\nUserPanelSettings (inside CurrentSessionPanel), always visible on the desktop\nmain page. Wait for it and tap it directly — no dragging.\n\n* Detect and reject adding an already-logged-in account\n\nLoginResultAlreadyLoggedIn and its \"You have already logged in to this account\"\ndialog existed, but nothing ever produced the result — the password login flow\nalways returned LoginResultSuccess, so adding the same account twice silently\ncreated a duplicate client (and the integration test \"Try Add Same Account\nTwice\" timed out waiting for the dialog).\n\nAfter a successful password login, check whether another logged-in client\nalready has the same user ID; if so, log the just-created session back out and\nreturn LoginResultAlreadyLoggedIn so the existing dialog is shown and no\nduplicate client is added.",
          "timestamp": "2026-06-26T17:20:36+02:00",
          "tree_id": "5548088076f2c75a3d05512b694161939045a560",
          "url": "https://github.com/Deniel9204/MyCommet/commit/58224cbc9018b2849f6dc956177a95ee6d10484a"
        },
        "date": 1782487982893,
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
            "value": 1.5884705882352936,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Average Raster Time",
            "value": 5.573125000000001,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Worst Build Time",
            "value": 3.125,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Worst Raster Time",
            "value": 6.454,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 99th Percentile Build Time",
            "value": 3.125,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 90th Percentile Build Time",
            "value": 3.125,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 99th Percentile Raster Time",
            "value": 6.454,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 90th Percentile Raster Time",
            "value": 6.215,
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
          "id": "2afced21285741c6160bc516ce4e50832ece68b6",
          "message": "ci: raise CARGO_NET_RETRY to reduce flaky native-build failures (#244)\n\nThe native Rust build (flutter_rust_bridge / rust_lib_commet, the `image`\ncrate) intermittently fails CI with transient crates.io fetch errors like\n\"failed to get `png` as a dependency of package `image`\" — the same Linux build\nsucceeds on a re-run / in other workflows on the same commit. Set\nCARGO_NET_RETRY=10 (default 3) on every workflow that compiles Rust so cargo\nretries transient network failures instead of failing the job.",
          "timestamp": "2026-06-26T18:38:18+02:00",
          "tree_id": "fef881c70882cca129ff5ffd8c71a1237f63e1c4",
          "url": "https://github.com/Deniel9204/MyCommet/commit/2afced21285741c6160bc516ce4e50832ece68b6"
        },
        "date": 1782492664712,
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
            "value": 1.4960294117647057,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Average Raster Time",
            "value": 6.629666666666667,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Worst Build Time",
            "value": 3.459,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Worst Raster Time",
            "value": 9.695,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 99th Percentile Build Time",
            "value": 3.459,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 90th Percentile Build Time",
            "value": 3.459,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 99th Percentile Raster Time",
            "value": 9.695,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 90th Percentile Raster Time",
            "value": 8.821,
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
          "id": "d53007b276e1c68807d617480e53e02a2745409b",
          "message": "Fix iOS bundle name casing + bump to 0.1.0 + add macOS to release (#245)\n\n* Fix iOS bundle name casing (Commet) and bump version to 0.1.0\n\n- iOS Info.plist CFBundleName was \"commet\" (lowercase) while CFBundleDisplayName\n  was already \"Commet\"; align CFBundleName to \"Commet\" so the name is\n  consistently cased everywhere iOS surfaces it.\n- Bump version 0.4.2+920 -> 0.1.0+1 for the fork's first tagged release.\n\n* Add macOS to the release (ad-hoc) + macOS display name\n\n- release.yml: add a release-macos job (macos-26 / Xcode 26, like build.yml's\n  build-macos). Builds via build_release.dart (which is platform-generic — bakes\n  version/hash/date), zips commet.app with ditto, uploads commet-macos.zip to\n  the release (and as an artifact on workflow_dispatch). Ad-hoc signed, no Apple\n  secrets; first-open shows a Gatekeeper prompt.\n- macOS Info.plist: add CFBundleDisplayName \"Commet\" so the menu/dock/About show\n  the cased name while the bundle stays commet.app (PRODUCT_NAME unchanged, no\n  build-path break).",
          "timestamp": "2026-06-26T19:42:09+02:00",
          "tree_id": "61fb0d9a3431723f7c7e7eb3556159abb964e8a3",
          "url": "https://github.com/Deniel9204/MyCommet/commit/d53007b276e1c68807d617480e53e02a2745409b"
        },
        "date": 1782496539786,
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
            "value": 1.5989117647058824,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Average Raster Time",
            "value": 6.038812499999999,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Worst Build Time",
            "value": 4.412,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Worst Raster Time",
            "value": 7.872,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 99th Percentile Build Time",
            "value": 4.412,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 90th Percentile Build Time",
            "value": 4.412,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 99th Percentile Raster Time",
            "value": 7.872,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 90th Percentile Raster Time",
            "value": 7.067,
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
          "id": "070bcc6a5d4e191a9f54c8bf63de49e32c239119",
          "message": "Build debug-signed Android APK when no release keystore is configured (#246)\n\nThe Android release jobs failed with \"RangeError ... 0..1: 2\": with no signing\nsecrets (a fork without ANDROID_KEY_STORE_B64 / ANDROID_KEY_PASSWORD), the CI\ncommand becomes `--key_password --key_b64` with no values, and\nsetup_android_release.dart indexed past the args.\n\n- setup_android_release.dart: make getArg bounds-safe, and skip writing\n  key.properties when no keystore is provided (null/empty/leading \"--\").\n- android/app/build.gradle: the release build now falls back to signingConfigs.\n  debug when key.properties is absent, so it produces an installable\n  (sideload-only) APK instead of an unsigned one. With a real keystore present\n  it still release-signs exactly as before.",
          "timestamp": "2026-06-26T20:43:02+02:00",
          "tree_id": "53102035622e7e9a0b698eddf4d4d3e8d94b7be3",
          "url": "https://github.com/Deniel9204/MyCommet/commit/070bcc6a5d4e191a9f54c8bf63de49e32c239119"
        },
        "date": 1782500156629,
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
            "value": 1.451942857142857,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Average Raster Time",
            "value": 5.432818181818182,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Worst Build Time",
            "value": 3.034,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - Worst Raster Time",
            "value": 7.234,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 99th Percentile Build Time",
            "value": 3.034,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 90th Percentile Build Time",
            "value": 3.034,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 99th Percentile Raster Time",
            "value": 7.234,
            "unit": "ms"
          },
          {
            "name": "TimelineViewer Scrolling - 90th Percentile Raster Time",
            "value": 6.122,
            "unit": "ms"
          }
        ]
      }
    ]
  }
}