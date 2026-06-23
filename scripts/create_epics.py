#!/usr/bin/env python3
"""
Create the 8 long-running "epic" tracking issues on Deniel9204/MyCommet,
each with a task-list referencing its child issues (#1..#87 from create_issues.py).

Usage:
    DRY_RUN=1 python3 scripts/create_epics.py
    GH_TOKEN=<token> python3 scripts/create_epics.py
"""
import json, os, sys, time, urllib.request, urllib.error

REPO = os.environ.get("REPO", "Deniel9204/MyCommet")
TOKEN = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
DRY_RUN = bool(os.environ.get("DRY_RUN")) or not TOKEN
API = "https://api.github.com"

TITLES = {
 1:"Restore Firebase/FCM push on Google-Play builds",2:"Make UnifiedPush delivery reliable",
 3:"Notification settings have no effect",4:"Notifications show stale/outdated room icons",
 5:"Add keyword & per-rule push editor (@room, mentions)",6:"Separate unread indicator from notifications",
 7:"Bulk re-decrypt whole room + batch key re-request",8:"Add encryption setup to OOBE / post-login",
 9:"Fix fragile key-backup restoration",10:"Share outbound Megolm keys to bridge-bot devices",
 11:"Fix 'Encryption is already enabled!' error on room creation",12:"Offline E2E room-key export/import to encrypted file",
 13:"Room list / sidebar shows no rooms on Web & Linux",14:"Separate DM / spaceless view; show standalone rooms in sidebar",
 15:"Add public room directory / 'Explore rooms'",16:"Add forum-style channel room type (MSC3765)",
 17:"Long space names overlap the arrow icon",18:"Permission/role edits silently fail; Owner(150) not assignable in v12",
 19:"Add unban action and banned-user list",20:"Client-level ignore/block (m.ignored_user_list)",
 21:"Content reporting to homeserver; CSAM/NSFW handling",22:"Room-version selection at creation + additional_creators (v12)",
 23:"History-visibility control for authorized users",24:"VoIP crashes on TURN-less servers (e.g. Tchap)",
 25:"Add a video-call entry point in the UI",26:"Element Call screen-share with audio",
 27:"Per-source audio / mic-gain controls; hide non-video sources; fullscreen stream",
 28:"Screen-share dialog bugs: KDE duplicates, Android not fullscreen",
 29:"Converge call stacks; add ringing/accept-decline and call stats",
 30:"Image lightbox controls (zoom/rotate/next-prev/download)",31:"Video playback options (speed/quality/PiP); slow start",
 32:"AVIF images do not render",33:"Animated stickers appear broken",34:"APNG link preview crashes the app",
 35:"Background/queued upload with progress, retry, compression",36:"Embedded media for oEmbed/iframe video providers",
 37:"Keyboard GIF/image insert (Android Commit Content API)",38:"Downloaded media doesn't display instantly",
 39:"Sticker-pack create/import buttons disappear after first pack",40:"Save draft messages when switching rooms",
 41:"Double-send when typing fast then pressing Enter",42:"Render /me & /rainbowme correctly; allow editing emotes",
 43:"Markdown strips trailing spaces; \\n adds spurious line breaks",44:"Markdown wrap actions (bold/italic/code) in selection menu",
 45:"Add spellchecking",46:"Message forwarding to another room",47:"Copy message link / permalink",
 48:"View message edit history",49:"Scheduled / send-later messages",50:"Voice messages (record & send)",
 51:"Location sharing",52:"Jump-to-original leaves message stuck-selected",53:"User prefixes ending in a space not supported",
 54:"In-app 24-hour clock toggle",55:"Discord-style relative timestamps",56:"Animation-speed / reduce-motion setting",
 57:"Custom / fallback font support",58:"Theme editor / template UI + accent picker",59:"Inline message translation",
 60:"Accessibility / screen-reader semantics across the app",61:"Allow clearing avatars and banner",
 62:"iOS/macOS support (stubs; not in CI; iOS build blocked)",63:"Web instance is broken (desktop layout, empty sidebar)",
 64:"Ubuntu package cannot be installed",65:"Minimize-on-close traps the process; add quit/exit button",
 66:"Flatpak: NetworkManager dep, no clipboard/DnD, reports GNOME under KDE",67:"No uninstaller; binaries not signature-verifiable",
 68:"Network resilience: DNS-retry, WebGL-less freeze, ramdisk",69:"System tray, autostart, and file associations",
 70:"Sluggish room switching after long uptime",71:"App-wide animation stutter on Android",
 72:"Slow media playback; downloaded media not instant",73:"Removed members slow to update in member list",
 74:"Cache profile information",75:"Adopt sliding sync for large accounts",76:"Unread indicator broken against Continuwuity",
 77:"Calendar: configurable week-start + timezone conversion",78:"User presence: null-check crash + status-message edit UI",
 79:"Sandbox matrix widgets",80:"Bot/integration & discoverable command framework",81:"Finish donation awards & activities",
 82:"Hover to see who reacted (desktop)",83:"File-manager room type / widget",
 84:"Infinite UIA auth loop when removing a session",85:"Login fails against alternate homeservers on Win11",
 86:"In-app account registration (/register)",87:"QR-code / rendezvous cross-device sign-in",
}

# key, name, area, prio, description, why-long, child issue numbers, related refs, extra (text) workstreams
EPICS = [
 ("LR-1","Reliable Push Notification Program","push","P0",
  "Make push notifications work dependably across both Android build variants and lay groundwork for Apple/web push.",
  "Spans native Android (Firebase/UnifiedPush receivers), the Dart notifier stack, a fragile background-decryption service, avatar caching, and new platform backends (APNs/PushKit, web push). Each must be validated end-to-end against multiple gateways and homeservers.",
  [1,2,3,4,5,6],[62],
  ["Rework the background handler to reuse one MatrixBackgroundClient; harden headless decryption","APNs/PushKit (iOS/macOS) and web-push backends — blocked on LR-5 (#62)"]),
 ("LR-2","Encryption Robustness & Key-Backup Lifecycle","encryption","P0",
  "Make E2EE trustworthy end to end: guide verification & key backup at login, recover undecryptable history in bulk, and finish the cross-signing/SSSS state machine.",
  "Touches onboarding (OOBE), the bootstrap/SSSS state machine, bulk re-decryption, cross-session trust indicators, bridge-bot key sharing, and offline export/import — all interlocking and security-critical.",
  [7,8,9,10,11,12],[22,23],
  ["Global + per-room trust indicators (unverified session/devices, backup-missing banners)","Render numeric/decimal SAS in addition to emoji verification"]),
 ("LR-3","Calling & Element Call Maturity","voip","P1",
  "Bring VoIP from working-1:1 to a robust group-calling experience on the Element Call/LiveKit path: screen-share audio, video entry points, group calls, ringing, stats, and crash hardening.",
  "Two parallel call stacks (legacy WebRTC + LiveKit/MatrixRTC) must converge; group calling, E2EE call setup, ringing, stats, and screenshare-with-audio each require protocol-level work (MSC4143/3401/4140) plus cross-platform media plumbing and low-end performance tuning.",
  [24,25,26,27,28,29],[31,71,72],
  ["Human-readable call timeline events; revive or remove the screen-share annotation feature"]),
 ("LR-4","Performance & Sync Overhaul for Large Accounts","performance","P1",
  "Reduce sluggish room switching, app-wide animation stutter, and high memory on long-running sessions and large accounts; move toward sliding sync and streaming media.",
  "Architectural: adopting sliding / simplified sliding sync (MSC4186/3575), memoizing sidebar/recent rebuilds, streaming attachment upload/download instead of whole-file in-memory handling, and profiling timeline/call hot paths per platform.",
  [70,71,72,73,74,75,76],[13,35,68],
  ["Memoize sidebar getSpaces and home-screen recent re-sort"]),
 ("LR-5","iOS / macOS / Web Platform Coverage","platform","P1",
  "Bring Commet to Apple platforms and the web (listed as planned but not built in CI), with push, media, and notification parity.",
  "Multi-release: per-platform CI/build pipelines, Apple push (APNs/PushKit), web push & WebGL constraints, platform media/notification backends, store/distribution, and the iOS localization build blocker.",
  [62,63,64,65,66,67,68,69],[13],
  ["Add iOS/macOS/web targets to CI build & release workflows","Native macOS/iOS app layers (notifications, window mgmt, deep links) + store distribution"]),
 ("LR-6","Moderation, Safety & Room-Version Correctness","moderation","P0",
  "Make moderation actually work and safe: fix silent permission failures, add unban, client-level ignore/block, content reporting, history-visibility control, and proper v6/v11/v12 handling.",
  "Combines correctness fixes (PL evaluation, version-aware roles), new moderation surfaces (unban, reasons, reporting), account-wide safety (m.ignored_user_list, CSAM), and room-version selection — spanning rooms, settings, and the timeline.",
  [18,19,20,21,22,23],[],
  ["Server ACLs and space-wide moderation actions","Redact-on-ban and ban/kick reason fields"]),
 ("LR-7","Accessibility Program","accessibility","P1",
  "Add screen-reader and accessibility support across the app and the tiamat design system — there is currently zero Semantics usage anywhere.",
  "Accessibility must be retrofitted across custom-painted widgets, the timeline, dialogs, and tiamat: semantics, focus order, contrast, and ongoing testing with assistive tech — a sustained cross-cutting effort, not a single feature.",
  [60],[],
  ["Add Semantics/semanticLabels to atoms and tiamat components","Make the timeline & composer screen-reader navigable","Focus order, keyboard navigation, and contrast audit","Establish accessibility testing in CI/QA"]),
 ("LR-8","Extensibility & Widget Sandboxing","extensions","P2",
  "Make extensibility safe and powerful: sandbox widgets, add a discoverable bot/command framework, and ship new room types (forum, file-manager).",
  "Widgets currently run unsandboxed with full app/system access and no crash isolation; there is no discoverable bot/command framework. Safe extensibility plus new room types is a security + architecture effort.",
  [16,79,80,83],[77,78,81,82],
  ["Capability-scoped widget sandboxing + resource limits + crash isolation","Composer slash-command autocomplete/help"]),
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

def body_for(e):
    key,name,area,prio,desc,why,children,related,extra = e
    b = [f"**{desc}**", "", f"**Why it's long-running:** {why}", "", "## Tracked issues"]
    for n in children:
        b.append(f"- [ ] #{n} — {TITLES[n]}")
    for w in extra:
        b.append(f"- [ ] {w}")
    if related:
        b.append("")
        b.append("## Related (tracked under other epics)")
        for n in related:
            b.append(f"- #{n} — {TITLES[n]}")
    b += ["", f"<sub>Epic {key} · area: {area} · auto-generated from `ROADMAP.md` §5.</sub>"]
    return "\n".join(b)

def main():
    print(f"Repo: {REPO} | Mode: {'DRY RUN' if DRY_RUN else 'LIVE'}\n")
    if DRY_RUN:
        for e in EPICS:
            print(f"[Epic] {e[0]} · {e[1]}  -> children {e[5]} related {e[6]}")
        print("\nDry run. Re-run with GH_TOKEN=<token>.")
        return
    st, me = req("GET", "/user")
    if st != 200: sys.exit(f"Auth failed ({st}): {me.get('message')}")
    print(f"Authenticated as: {me.get('login')}")
    # ensure 'epic' label
    req("POST", f"/repos/{REPO}/labels", {"name":"epic","color":"6f42c1"})
    for e in EPICS:
        key,name,area,prio = e[0],e[1],e[2],e[3]
        payload = {"title": f"[Epic] {key} · {name}",
                   "body": body_for(e),
                   "labels": ["epic","roadmap",f"area:{area}",f"priority:{prio}"]}
        st, r = req("POST", f"/repos/{REPO}/issues", payload)
        if st == 201:
            print(f"#{r['number']:>3}  [Epic] {key} · {name}")
        else:
            print(f"FAIL ({st}): {key} -> {r.get('message')}")
        time.sleep(1.0)
    print("\nDone creating epics.")

if __name__ == "__main__":
    main()
