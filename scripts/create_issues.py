#!/usr/bin/env python3
"""
Create GitHub issues on Deniel9204/MyCommet from the ROADMAP.md gap analysis.

Usage:
    DRY_RUN=1 python3 scripts/create_issues.py          # print the plan, create nothing
    GH_TOKEN=<token> python3 scripts/create_issues.py    # actually create the issues

Env vars:
    GH_TOKEN   GitHub token with `issues:write` (and `repo`/admin to auto-enable Issues).
    REPO       Override target repo (default: Deniel9204/MyCommet).
    DRY_RUN    If set (and no GH_TOKEN), only prints what would be created.
    START_AT   1-based index to resume from (skips already-created issues on re-run).

Upstream issue refs (#NNN) point at github.com/commetchat/commet.
"""
import json
import os
import sys
import time
import urllib.request
import urllib.error

REPO = os.environ.get("REPO", "Deniel9204/MyCommet")
TOKEN = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
DRY_RUN = bool(os.environ.get("DRY_RUN")) or not TOKEN
START_AT = int(os.environ.get("START_AT", "1"))
API = "https://api.github.com"
UPSTREAM = "commetchat/commet"

# ---------------------------------------------------------------------------
# Labels (name -> color). Pre-created so issue creation never fails on a label.
# ---------------------------------------------------------------------------
LABELS = {
    "type:bug": "d73a4a", "type:feature": "a2eeef",
    "priority:P0": "b60205", "priority:P1": "d93f0b", "priority:P2": "fbca04",
    "roadmap": "5319e7",
    "area:push": "0e8a16", "area:encryption": "0e8a16", "area:navigation": "0e8a16",
    "area:moderation": "0e8a16", "area:voip": "0e8a16", "area:media": "0e8a16",
    "area:messaging": "0e8a16", "area:settings": "0e8a16", "area:accessibility": "0e8a16",
    "area:platform": "0e8a16", "area:performance": "0e8a16", "area:extensions": "0e8a16",
    "area:auth": "0e8a16",
}

# ---------------------------------------------------------------------------
# Issues: (title, kind, prio, area, [upstream refs], description)
# ---------------------------------------------------------------------------
I = [
 # --- Push notifications ---
 ("Restore Firebase/FCM push on Google-Play builds", "bug", "P0", "push", [937, 810],
  "FCM/Firebase push is stubbed with dynamic placeholders; registration crashes at startup so Android push is effectively broken on GMS builds. Un-stub the notifier with real firebase_core/messaging imports."),
 ("Make UnifiedPush delivery reliable", "bug", "P0", "push", [963, 937],
  "UnifiedPush notifications frequently fail to arrive. Fix onMessage envelope parsing, de-dup window, and headless decryption; test end-to-end against ntfy and other distributors."),
 ("Notification settings have no effect", "bug", "P0", "push", [858],
  "The notification settings page is near-empty and the DoNotDisturb / HideContent modifiers are dead code. Build real global push rules and wire the modifiers."),
 ("Notifications show stale/outdated room icons", "bug", "P1", "push", [945],
  "The avatar cache returns null on the first notification, so room icons are stale. Return the freshly generated avatar and add cache invalidation/TTL."),
 ("Add keyword & per-rule push editor (@room, mentions)", "feature", "P1", "push", [],
  "No keyword-notification editor, per-event-type rules, @room toggle, or account-wide mention settings (Element has these in its Notifications tab)."),
 ("Separate unread indicator from notifications", "feature", "P1", "push", [845],
  "Unread state is tied to the notification preference; allow showing an unread indicator independently of notifications."),

 # --- Encryption ---
 ("Bulk re-decrypt whole room + batch key re-request", "bug", "P0", "encryption", [933, 975],
  "Only a per-event 'Retry Decrypt' exists; old messages often fail to decrypt with no room-wide recovery. Add bulk re-decryption, batch key re-request, and re-import from backup."),
 ("Add encryption setup to OOBE / post-login", "feature", "P0", "encryption", [1002, 852],
  "Fresh sessions are never prompted to verify, set up cross-signing, or create/restore key backup, leaving users unverified with no recovery key."),
 ("Fix fragile key-backup restoration", "bug", "P0", "encryption", [852],
  "Key-backup restoration fails if not done immediately after verification in the same session. Harden the bootstrap/SSSS state machine (askUnlockSsss/askBadSsss) with retry/error UI."),
 ("Share outbound Megolm keys to bridge-bot devices", "bug", "P1", "encryption", [873],
  "Outbound Megolm keys are not distributed to bridge-bot devices in encrypted rooms, breaking bridges. Define a key-sharing policy for bridge-bot/unverified devices."),
 ("Fix 'Encryption is already enabled!' error on room creation", "bug", "P1", "encryption", [864],
  "Creating a room raises 'Encryption is already enabled!'. Guard against re-enabling E2EE during creation."),
 ("Offline E2E room-key export/import to encrypted file", "feature", "P2", "encryption", [],
  "There is no offline export/import of E2E room keys to an encrypted file (Element's offline recovery path independent of server-side backup)."),

 # --- Room list / spaces / navigation ---
 ("Room list / sidebar shows no rooms on Web & Linux", "bug", "P0", "navigation", [836],
  "Some Web and Linux users see an empty sidebar — a total-loss bug. Investigate and fix matrix_sidebar_entries_component population."),
 ("Separate DM / spaceless view; show standalone rooms in sidebar", "feature", "P1", "navigation", [995, 880],
  "Provide distinct DM vs orphan-room views and let standalone rooms appear in the sidebar rail (new RoomSidebarEntry)."),
 ("Add public room directory / 'Explore rooms'", "feature", "P1", "navigation", [],
  "Joining requires typing an exact alias/ID; add a /publicRooms-backed discovery browser so users can find communities."),
 ("Add forum-style channel room type (MSC3765)", "feature", "P2", "navigation", [887, 974],
  "Add a forum/thread-list room type where threads are top-level posts."),
 ("Long space names overlap the arrow icon", "bug", "P2", "navigation", [968],
  "Long space names overflow and overlap the expand arrow; add overflow ellipsis."),

 # --- Moderation / permissions ---
 ("Permission/role edits silently fail; Owner(150) not assignable in v12", "bug", "P0", "moderation", [958, 855],
  "Power-level inconsistencies make moderation silently no-op. Make Owner(150) assignable in v12, make availableRoles room-version-aware, and add success/failure feedback on permission writes."),
 ("Add unban action and banned-user list", "feature", "P0", "moderation", [958],
  "The client can only show that someone was unbanned; expose an unban action and a list of banned users so moderators can reverse bans. Add ban/kick reasons too."),
 ("Client-level ignore/block (m.ignored_user_list)", "feature", "P1", "moderation", [971],
  "No m.ignored_user_list handling and no block/ignore UI. Add account-wide ignore plus per-user invite blocking."),
 ("Content reporting to homeserver; CSAM/NSFW handling", "feature", "P1", "moderation", [896],
  "No report-to-server action from the event menu and no CSAM/NSFW handling. Add report_content plus a content filter."),
 ("Room-version selection at creation + additional_creators (v12)", "feature", "P1", "moderation", [816, 855],
  "Let users pick the room version (v6/v11/v12) at creation and handle the v12 additional_creators parameter."),
 ("History-visibility control for authorized users", "feature", "P1", "moderation", [851],
  "Add a room setting to change message history visibility for authorized users."),

 # --- VoIP / Element Call ---
 ("VoIP crashes on TURN-less servers (e.g. Tchap)", "bug", "P0", "voip", [972],
  "Starting VoIP force-unwraps navigator.currentContext! and throws 'No Turn servers', crashing on servers without TURN. Handle gracefully."),
 ("Add a video-call entry point in the UI", "feature", "P1", "voip", [1001],
  "The UI hardcodes CallType.voice though CallType.video is already plumbed; surface a video-call (camera-on) button."),
 ("Element Call screen-share with audio", "feature", "P1", "voip", [969],
  "Capture system/screen audio on the LiveKit and legacy stacks and add a UI toggle."),
 ("Per-source audio / mic-gain controls; hide non-video sources; fullscreen stream", "feature", "P2", "voip", [884, 920, 883],
  "Add microphone input-gain control, the ability to hide non-video tiles, and a fullscreen stream view."),
 ("Screen-share dialog bugs: KDE duplicates, Android not fullscreen", "bug", "P2", "voip", [854, 844],
  "On KDE, screen-share opens duplicate dialogs with no window selection (Wayland picker); on Android, screen sharing isn't true-fullscreen."),
 ("Converge call stacks; add ringing/accept-decline and call stats", "feature", "P2", "voip", [1001],
  "Converge the legacy WebRTC and LiveKit/MatrixRTC stacks; add ring/invite/accept/decline for MatrixRTC, group calls in normal rooms, and real call stats."),

 # --- Media ---
 ("Image lightbox controls (zoom/rotate/next-prev/download)", "feature", "P2", "media", [954],
  "Add zoom/reset/rotate, next/previous, and download controls to the image lightbox."),
 ("Video playback options (speed/quality/PiP); slow start", "feature", "P2", "media", [919, 918],
  "Add playback-speed, quality, and picture-in-picture options; reduce time-to-first-frame."),
 ("AVIF images do not render", "bug", "P2", "media", [820],
  "AVIF images do not appear; add AVIF decoding."),
 ("Animated stickers appear broken", "bug", "P2", "media", [940],
  "Animated stickers render broken; add a dedicated animated-image path."),
 ("APNG link preview crashes the app", "bug", "P1", "media", [900],
  "Displaying an .apng link preview crashes the app ~1 minute later. Guard the decode/animation path."),
 ("Background/queued upload with progress, retry, compression", "feature", "P2", "media", [827],
  "Add streaming/queued attachment upload with progress and retry, plus optional compression."),
 ("Embedded media for oEmbed/iframe video providers", "feature", "P2", "media", [898],
  "Add native embeds for oEmbed/iframe video/image providers."),
 ("Keyboard GIF/image insert (Android Commit Content API)", "feature", "P2", "media", [925],
  "Support inserting GIFs/images from the keyboard via the Android Commit Content API."),
 ("Downloaded media doesn't display instantly", "bug", "P2", "media", [909],
  "Downloaded media doesn't show immediately after download completes."),
 ("Sticker-pack create/import buttons disappear after first pack", "bug", "P2", "media", [860],
  "Create/import controls vanish after the first stickerpack is created; restore them."),

 # --- Messaging / composer ---
 ("Save draft messages when switching rooms", "feature", "P1", "messaging", [952],
  "Add a per-room draft store so unsent composer text is preserved across room switches and restart."),
 ("Double-send when typing fast then pressing Enter", "bug", "P1", "messaging", [868],
  "onKey acts on every key event with only a 20ms debounce; filter KeyRepeatEvent and clear text reliably to stop duplicate sends."),
 ("Render /me & /rainbowme correctly; allow editing emotes", "bug", "P2", "messaging", [829, 813],
  "Emote events render plain body only, so /rainbowme colors don't show and /me messages can't be edited. Render formatted_body and allow editing emotes."),
 ("Markdown strips trailing spaces; \\n adds spurious line breaks", "bug", "P2", "messaging", [955, 903],
  "The markdown round-trip strips spaces after URLs (#955) and \\n in formatted_body adds extra line breaks (#903)."),
 ("Markdown wrap actions (bold/italic/code) in selection menu", "feature", "P2", "messaging", [956],
  "Add markdown wrap actions to the right-click/selection menu for selected text."),
 ("Add spellchecking", "feature", "P2", "messaging", [960],
  "Add a spellcheck toggle wired to the composer text field."),
 ("Message forwarding to another room", "feature", "P2", "messaging", [],
  "Add a 'forward to room' action in the timeline event menu."),
 ("Copy message link / permalink", "feature", "P2", "messaging", [],
  "Add a 'copy link to message' (matrix.to permalink) action in the event menu."),
 ("View message edit history", "feature", "P2", "messaging", [],
  "Add an edit-history viewer so users can inspect prior versions of an edited message."),
 ("Scheduled / send-later messages", "feature", "P2", "messaging", [],
  "Add scheduled send (MSC4140 futures)."),
 ("Voice messages (record & send)", "feature", "P1", "messaging", [],
  "Add audio recording with waveform (MSC3245); playback already exists for received files."),
 ("Location sharing", "feature", "P2", "messaging", [],
  "Add m.location / geo: support for sending static (and ideally live) location."),
 ("Jump-to-original leaves message stuck-selected", "bug", "P2", "messaging", [961],
  "After jump-to-original from a reply, the highlight persists until the next jump or leaving the room. Clear it on scroll/timeout."),
 ("User prefixes ending in a space not supported", "bug", "P2", "messaging", [875],
  "Account-switch / user prefixes that end in a space are not handled correctly."),

 # --- Settings / theming / a11y ---
 ("In-app 24-hour clock toggle", "feature", "P1", "settings", [982],
  "Add a user-facing 12h/24h setting instead of only honoring MediaQuery.alwaysUse24HourFormat on Android."),
 ("Discord-style relative timestamps", "feature", "P2", "settings", [921],
  "Add a relative-timestamp format option (e.g. 'Today 3:20 PM')."),
 ("Animation-speed / reduce-motion setting", "feature", "P2", "settings", [932],
  "Add a setting to control animation duration / reduce motion."),
 ("Custom / fallback font support", "feature", "P2", "settings", [939],
  "Allow user-selectable and fallback fonts instead of the hardcoded Roboto + emoji fallback."),
 ("Theme editor / template UI + accent picker", "feature", "P2", "settings", [894],
  "ZIP/JSON themes load but there's no editor, schema validation, or accent-color picker. Add a theme editor."),
 ("Inline message translation", "feature", "P2", "settings", [872],
  "Add the ability to translate received messages within rooms."),
 ("Accessibility / screen-reader semantics across the app", "feature", "P0", "accessibility", [],
  "There is zero Semantics/semanticLabel usage anywhere. Add screen-reader semantics, focus order, and contrast across the app and the tiamat design system."),
 ("Allow clearing avatars and banner", "feature", "P2", "settings", [881],
  "Add the ability to clear (remove) a profile/room avatar and banner."),

 # --- Platform / packaging ---
 ("iOS/macOS support (stubs; not in CI; iOS build blocked)", "feature", "P1", "platform", [998, 895],
  "iOS and macOS are stub AppDelegates, not built in CI; the iOS build is blocked by a missing generated messages_all.dart. Build and ship Apple targets."),
 ("Web instance is broken (desktop layout, empty sidebar)", "bug", "P1", "platform", [862, 836],
  "The web build shows the desktop layout and an empty sidebar. Make the web target usable."),
 ("Ubuntu package cannot be installed", "bug", "P1", "platform", [931],
  "The commet-ubuntu-24.04-x64 package can't install (architecture 'all' vs native binaries)."),
 ("Minimize-on-close traps the process; add quit/exit button", "bug", "P1", "platform", [842, 985],
  "On Linux/KDE, minimize-on-close prevents manual closing and system shutdown; there is also no explicit quit/exit button."),
 ("Flatpak: NetworkManager dep, no clipboard/DnD, reports GNOME under KDE", "bug", "P2", "platform", [930, 819, 814],
  "Flatpak hard-depends on org.freedesktop.NetworkManager (#930), blocks clipboard/drag-drop of attachments (#819), and reports GNOME under KDE (#814)."),
 ("No uninstaller; binaries not signature-verifiable", "feature", "P2", "platform", [913, 879],
  "There is no uninstaller, and release binaries aren't signature-verifiable despite a published PGP key. Add signing to CI and uninstall scripts."),
 ("Network resilience: DNS-retry, WebGL-less freeze, ramdisk", "bug", "P2", "platform", [821, 811, 808],
  "Host-lookup failure is terminal with no retry (#821), the app freezes when WebGL is unavailable (#811), and it can't run on a logical ramdrive (#808)."),
 ("System tray, autostart, and file associations", "feature", "P2", "platform", [],
  "Add a system tray icon, autostart option, and desktop file associations / deep links on desktop."),

 # --- Performance ---
 ("Sluggish room switching after long uptime", "bug", "P1", "performance", [970],
  "Room switching becomes slow after Commet has been open for ~2 days. Profile and fix the hot path."),
 ("App-wide animation stutter on Android", "bug", "P1", "performance", [965],
  "When open, Commet makes all animations stutter, including system ones. Investigate the render/timer load."),
 ("Slow media playback; downloaded media not instant", "bug", "P2", "performance", [918, 909],
  "Videos are slow to play and downloaded media doesn't display instantly."),
 ("Removed members slow to update in member list", "bug", "P2", "performance", [936],
  "Removed members take a while to disappear from the room member list."),
 ("Cache profile information", "feature", "P2", "performance", [938],
  "getProfile() always hits the server on every avatar/name display; add an in-memory + disk profile cache with TTL."),
 ("Adopt sliding sync for large accounts", "feature", "P2", "performance", [],
  "The client uses full /sync; adopt sliding / simplified sliding sync (MSC4186/3575) for fast startup and lower memory on large accounts."),
 ("Unread indicator broken against Continuwuity", "bug", "P2", "performance", [935],
  "The unread indicator doesn't work against the Continuwuity homeserver."),

 # --- Extensions ---
 ("Calendar: configurable week-start + timezone conversion", "bug", "P2", "extensions", [841],
  "Calendar week-start is hardcoded (#841) and views don't apply timezone conversion."),
 ("User presence: null-check crash + status-message edit UI", "bug", "P1", "extensions", [924],
  "getPresence() can crash with a null-check (#924); also there is no UI to edit a custom status message."),
 ("Sandbox matrix widgets", "feature", "P1", "extensions", [],
  "Widgets run unsandboxed in full app/native context with no resource limits or crash isolation. Add capability-scoped sandboxing."),
 ("Bot/integration & discoverable command framework", "feature", "P2", "extensions", [],
  "Only 6 hardcoded slash commands exist, not discoverable, with no composer autocomplete/help. Add an extensible command/bot framework."),
 ("Finish donation awards & activities", "bug", "P2", "extensions", [],
  "Donation-awards validation is a stub (TODO) and activities only track call/widget sessions. Finish or remove."),
 ("Hover to see who reacted (desktop)", "feature", "P2", "extensions", [962],
  "Add a desktop hover tooltip showing who reacted with each emoji (currently long-press only)."),
 ("File-manager room type / widget", "feature", "P2", "extensions", [974],
  "Add a file-manager room type/widget and an extensible room-type registry."),

 # --- Auth / sessions ---
 ("Infinite UIA auth loop when removing a session", "bug", "P0", "auth", [980],
  "matrix_uia_request hardcodes an AuthenticationPassword identifier and only renders a password box; support SSO/fallback/dummy stages so device deletion completes on non-password homeservers."),
 ("Login fails against alternate homeservers on Win11", "bug", "P1", "auth", [977],
  "Login fails for non-default homeservers on Windows 11 (OAuth/URL-scheme handling)."),
 ("In-app account registration (/register)", "feature", "P2", "auth", [],
  "Add a /register sign-up flow so new users can create an account in-app instead of only signing in."),
 ("QR-code / rendezvous cross-device sign-in", "feature", "P2", "auth", [],
  "Add QR-code / rendezvous-based device sign-in (modern Element X onboarding)."),
]


def req(method, path, body=None):
    url = path if path.startswith("http") else f"{API}{path}"
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(url, data=data, method=method)
    r.add_header("Authorization", f"Bearer {TOKEN}")
    r.add_header("Accept", "application/vnd.github+json")
    r.add_header("X-GitHub-Api-Version", "2022-11-28")
    r.add_header("User-Agent", "commet-roadmap-script")
    try:
        with urllib.request.urlopen(r) as resp:
            return resp.status, json.loads(resp.read() or "{}")
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read() or "{}")


def body_for(issue):
    title, kind, prio, area, refs, desc = issue
    ref_txt = ", ".join(f"{UPSTREAM}#{n}" for n in refs) if refs else "_none (parity/architecture gap)_"
    return (f"{desc}\n\n"
            f"**Type:** {kind} · **Priority:** {prio} · **Area:** {area}\n\n"
            f"**Related upstream issues:** {ref_txt}\n\n"
            f"<sub>Auto-generated from `ROADMAP.md`.</sub>")


def labels_for(issue):
    _, kind, prio, area, _, _ = issue
    return [f"type:{kind}", f"priority:{prio}", f"area:{area}", "roadmap"]


def main():
    print(f"Target repo : {REPO}")
    print(f"Mode        : {'DRY RUN (nothing will be created)' if DRY_RUN else 'LIVE'}")
    print(f"Issues       : {len(I)} (starting at #{START_AT})\n")

    if DRY_RUN:
        for n, issue in enumerate(I, 1):
            mark = " " if n >= START_AT else "x"
            print(f"[{mark}] {n:>2}. [{issue[2]}/{issue[1]}/{issue[3]}] {issue[0]}")
        print("\nDry run only. Re-run with GH_TOKEN=<token> to create them.")
        return

    # Verify auth
    st, me = req("GET", "/user")
    if st != 200:
        sys.exit(f"Auth failed ({st}): {me.get('message')}")
    print(f"Authenticated as: {me.get('login')}")

    # Best-effort enable Issues on the repo
    st, _ = req("PATCH", f"/repos/{REPO}", {"has_issues": True})
    print(f"Enable Issues : HTTP {st}")

    # Pre-create labels (ignore 'already_exists')
    for name, color in LABELS.items():
        st, r = req("POST", f"/repos/{REPO}/labels", {"name": name, "color": color})
        if st not in (201, 422):
            print(f"  label {name}: HTTP {st} {r.get('message')}")
    print(f"Labels        : ensured {len(LABELS)}\n")

    created = 0
    for n, issue in enumerate(I, 1):
        if n < START_AT:
            continue
        payload = {"title": issue[0], "body": body_for(issue), "labels": labels_for(issue)}
        st, r = req("POST", f"/repos/{REPO}/issues", payload)
        if st == 201:
            created += 1
            print(f"#{r['number']:>3}  {issue[0]}")
        else:
            print(f"FAIL ({st}) at item {n}: {issue[0]} -> {r.get('message')}")
            if st in (401, 403, 404):
                sys.exit("Stopping: auth/permission/repo error. Fix and resume with START_AT.")
        time.sleep(1.0)  # be gentle with secondary rate limits

    print(f"\nDone. Created {created} issues on {REPO}.")


if __name__ == "__main__":
    main()
