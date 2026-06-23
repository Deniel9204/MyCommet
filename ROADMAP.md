# Commet — Product Roadmap & Feature Gap Analysis

> **Status:** Draft, 2026-06-22.
> **Scope:** This roadmap was produced by auditing the Commet codebase (10 feature
> domains) against the **86 open issues** in the upstream tracker
> (`commetchat/commet`) and against feature parity with mature Matrix clients
> (Element / Element X, FluffyChat, SchildiChat, Cinny) and modern chat apps.
> Issue numbers below (`#NNN`) reference the upstream GitHub tracker.

Commet already has a remarkably **broad** feature surface — E2EE, threads, spaces,
polls, Element Call, custom emoji/stickers, GIF search, read receipts, typing
indicators, message effects, pinned messages, photo albums, and a calendar. The
strategic problem is **not breadth, it's depth**: many of these features are
partial, fragile at the edges, or broken on specific servers/platforms.

The guiding principle of this roadmap is therefore **reliability and inclusivity
over new surface area** — finish and stabilize what is started before adding more.

---

## 1. Vision

Commet aims to be a polished, trustworthy, open-source Matrix client that can serve
as someone's **primary** messenger across Linux, Windows, Android, and — in time —
Apple platforms and the web. The product strategy is three-pronged:

1. **Harden the core** — push notifications, encryption/decryption reliability, the
   room list, moderation, and calling — so the breadth that exists can actually be
   trusted day-to-day.
2. **Close parity gaps** — global search, public-room discovery, voice messages,
   ignore/block, account registration — the table-stakes features users expect from
   any mature client.
3. **Invest in foundations** — sliding sync & performance, iOS/macOS/web coverage,
   and accessibility — the architectural work that lets Commet scale to large
   accounts and reach every user.

---

## 2. Current State Snapshot

**Platforms shipping today:** Windows, Linux, Android.
**Listed as planned (not built in CI):** iOS, macOS, Web (web target exists but is broken — `#862`, `#836`).

**Solid / production-ready:** text messaging + markdown, message edit/delete,
replies, threads, reactions, read receipts, typing indicators, polls, pinned
messages, message effects, photo albums, mention/emoji autocomplete, attachments
(file/image/camera/clipboard/drag-drop on desktop), stickers & GIFs, 28 UI
languages, 4 built-in themes + custom-theme ZIP loading.

**Partial / fragile:** push notifications, decryption recovery, the sidebar/room
list, moderation & permissions, VoIP/Element Call, `/me` & `/rainbowme` rendering,
24h-clock handling, calendar (week-start/timezone), user presence, widgets
(unsandboxed), activities, profile (no caching).

**Stub / placeholder:** Firebase/FCM push on Google-Play builds, macOS & iOS native
layers, donation awards, the bot/command extensibility framework.

---

## 3. Missing Features & Gaps (by domain)

Severity reflects user impact; effort is a rough order of magnitude.

### 3.1 Push notifications & background delivery — **CRITICAL**
- **FCM/Firebase push is stubbed** on Google-Play builds — registration crashes at
  startup; Android push is effectively broken. (`#937`, `#810`) — *high / small*
- **UnifiedPush delivery is flaky** — envelope parsing, de-dup, and headless
  decryption need end-to-end testing against ntfy and other distributors.
  (`#963`, `#937`) — *high / medium*
- **Notification settings have no effect** — the settings page is near-empty and
  `DoNotDisturb`/`HideContent` modifiers are dead code. (`#858`) — *high / medium*
- **Stale room icons** in notifications — avatar cache returns `null` on first
  notification. (`#945`) — *medium / small*
- **No keyword / per-rule push editor**, no `@room` toggle, no account-wide mention
  rules (Element has these). — *medium / medium*
- **Unread indicator can't be separated from notifications.** (`#845`) — *medium / medium*

### 3.2 Encryption, verification & key backup — **CRITICAL**
- **No bulk re-decryption** — only a per-event "Retry Decrypt"; old messages often
  fail to decrypt with no room-wide recovery or batch key re-request. (`#933`, `#975`) — *high / medium*
- **No encryption setup in OOBE** — fresh sessions are never prompted to verify,
  set up cross-signing, or create/restore key backup. (`#1002`, `#852`) — *high / large*
- **Key-backup restoration is fragile** — fails if not done immediately after
  verification in the same session. (`#852`) — *high / medium*
- **Outbound Megolm keys not shared to bridge-bot devices** in encrypted rooms. (`#873`) — *medium / medium*
- **"Encryption is already enabled!" error** during room creation. (`#864`) — *medium / small*
- **No offline E2E room-key export/import** to an encrypted file (Element's offline
  recovery path). — *low / medium*

### 3.3 Room list, spaces & navigation — **HIGH**
- **Rooms don't appear in the sidebar** on Web/Linux for some users — a total-loss
  bug. (`#836`) — *high / large*
- **No separated DM / spaceless-chat view**; standalone rooms can't appear in the
  sidebar rail. (`#995`, `#880`) — *high / large*
- **No public-room directory / "Explore rooms"** — joining requires typing an exact
  alias/ID; no `/publicRooms` discovery browser. — *high / medium*
- **No forum-style channel** room type (threads as top-level posts, MSC3765). (`#887`, `#974`) — *medium / large*
- Long space names overlap the arrow icon. (`#968`) — *low / small*

### 3.4 Moderation, permissions & room versions — **HIGH**
- **Permission/role edits silently fail** — PL inconsistencies; `Owner(150)` not
  assignable in v12 rooms; no success/failure feedback. (`#958`, `#855`) — *high / medium*
- **No unban action / banned-user list** — bans can't be reversed in-app. (`#958`) — *high / small*
- **No client-level ignore/block** (`m.ignored_user_list`) and **no per-user invite
  blocking.** (`#971`) — *high / medium*
- **No content reporting** to homeserver admins from the event menu; no CSAM/NSFW
  handling. (`#896`) — *medium / medium*
- **No room-version selection at creation** and no `additional_creators` (v12)
  handling. (`#816`, `#855`) — *medium / medium*
- **No history-visibility control** for authorized users. (`#851`) — *medium / medium*

### 3.5 Voice & video calls (VoIP / Element Call) — **HIGH**
- **VoIP crashes on TURN-less servers** (e.g. Tchap) — force-unwrapped nav context
  + thrown "No Turn servers". (`#972`) — *high / medium*
- **No video-call entry point in the UI** — `CallType.video` is plumbed but the UI
  hardcodes `CallType.voice`. (`#1001`) — *high / small*
- **No screen-share-with-audio** on the Element Call/LiveKit stack. (`#969`) — *high / medium*
- **No per-source audio / mic-gain controls**; **can't hide non-video sources**;
  **no fullscreen stream.** (`#884`, `#920`, `#883`) — *medium / medium*
- **Screen-share dialog bugs** — KDE duplicate dialogs with no window selection;
  Android not true-fullscreen. (`#854`, `#844`) — *medium / medium*
- Two parallel call stacks (legacy WebRTC + LiveKit/MatrixRTC) need to converge;
  no ringing/accept-decline for MatrixRTC, no real call stats.

### 3.6 Media, attachments & rendering — **MEDIUM**
- **No image lightbox controls** — click-to-zoom, rotate, next/prev, download. (`#954`) — *medium / medium*
- **No video playback options** — speed, quality, PiP; playback is slow to start. (`#919`, `#918`) — *medium / medium*
- **AVIF images don't render**; **animated stickers appear broken**; APNG link
  preview **crashes the app** ~1 min later. (`#820`, `#940`, `#900`) — *medium / mixed*
- **No background / queued upload with progress & retry**; no compression. (`#827`) — *medium / medium*
- **No embedded media** for oEmbed/iframe video providers. (`#898`) — *medium / large*
- **No keyboard GIF/image insert** (Android Commit Content API). (`#925`) — *low / small*
- Downloaded media doesn't display instantly. (`#909`) — *low / small*
- Sticker-pack create/import buttons disappear after the first pack. (`#860`) — *low / small*

### 3.7 Messaging & composer UX — **MEDIUM**
- **No draft saving** when switching rooms — table-stakes; loses in-progress text. (`#952`) — *high / medium*
- **Double-send on fast Enter** — `onKey` acts on every key event with only a 20 ms
  debounce. (`#868`) — *medium / small*
- **`/me` & `/rainbowme` render wrong** (formatted_body ignored) and **emotes can't
  be edited.** (`#829`, `#813`) — *medium / medium*
- **Markdown round-trip strips trailing spaces** after URLs; `\n` in `formatted_body`
  adds spurious line breaks. (`#955`, `#903`) — *medium / small*
- **No markdown wrap actions** (bold/italic/code) in the selection menu. (`#956`) — *low / small*
- **No spellchecking.** (`#960`) — *low / medium*
- **No message forwarding**, **no copy-permalink**, **no edit-history viewer**,
  **no scheduled send**, **no voice messages**, **no location sharing** (parity
  gaps vs Element/Telegram). — *mixed*
- Jump-to-original leaves a message stuck-selected. (`#961`) — *low / small*

### 3.8 Settings, theming, accessibility & customization — **MEDIUM**
- **No in-app 24-hour clock toggle** — only honors `MediaQuery.alwaysUse24HourFormat`
  on Android. (`#982`) — *high / small*
- **No Discord-style relative timestamps.** (`#921`) — *medium / small*
- **No animation-speed / reduce-motion setting.** (`#932`) — *medium / medium*
- **No custom/fallback font support** — hardcoded Roboto + emoji fallback. (`#939`) — *medium / large*
- **No theme editor / template UI** — ZIP/JSON themes load but there's no editor or
  accent-color picker. (`#894`) — *medium / medium*
- **No inline message translation.** (`#872`) — *low / medium*
- **Zero accessibility semantics** — no `Semantics`/`semanticLabel` usage anywhere;
  custom-painted widgets, the timeline, and icon buttons expose ~no a11y tree. — *high / large*

### 3.9 Platform, packaging & desktop integration — **MEDIUM/HIGH**
- **iOS/macOS are stubs**, not built in CI; iOS build is blocked by a missing
  `messages_all.dart` localization artifact. (`#998`, `#895`) — *high / large*
- **Web instance is broken** (desktop layout on web; empty sidebar). (`#862`, `#836`) — *high / large*
- **Ubuntu package can't install** (architecture `all` vs native binaries). (`#931`) — *high / medium*
- **Minimize-on-close traps the process** on Linux/KDE — blocks manual close &
  shutdown; **no quit/exit button.** (`#842`, `#985`) — *high / small*
- **Flatpak issues** — hard NetworkManager dependency (`#930`), no clipboard/drag-drop
  of attachments (`#819`), reports GNOME under KDE (`#814`). — *medium / small–medium*
- **No uninstaller**; **binaries aren't signature-verifiable** despite a published
  PGP key. (`#913`, `#879`) — *medium / medium*
- **No DNS-failure retry** (host-lookup error is terminal); **app freezes without
  WebGL**; can't run on a ramdisk. (`#821`, `#811`, `#808`) — *mixed*
- **No system tray, autostart, or desktop file associations.** — *medium / medium*

### 3.10 Performance & resource usage — **HIGH**
- **Sluggish room switching** after the app has been open for ~2 days. (`#970`) — *high / large*
- **App-wide animation stutter on Android** — affects even system animations. (`#965`) — *high / medium*
- **Slow media playback / downloaded media not instant.** (`#918`, `#909`) — *medium / medium*
- **Removed members take a while to update** in the member list. (`#936`) — *medium / small*
- **No profile caching** — `getProfile()` always hits the server on every
  avatar/name display. (`#938`) — *medium / medium*
- **No sliding sync** — relies on full `/sync`; large accounts get slow startup &
  high memory. — *medium / large*
- Unread indicator broken against Continuwuity. (`#935`) — *medium / small*

### 3.11 Extensions (calendar, presence, widgets, bots) — **MEDIUM**
- **Calendar:** week-start hardcoded (`#841`), no timezone conversion in views. — *medium / small*
- **User presence:** null-check crash in `Api.getPresence` (`#924`); no status-message
  edit UI. — *medium / small*
- **Widgets are unsandboxed** — run in full app context / native subprocess with no
  resource limits or crash isolation. — *high / large*
- **No bot/integration framework** — only 6 hardcoded slash commands, not
  discoverable; no command picker/autocomplete in the composer. — *medium / large*
- **Donation awards** validation is a stub; **activities** only track calls/widgets. — *low*
- Hover-to-see-who-reacted (desktop). (`#962`) — *low / small*

### 3.12 Authentication & sessions — **HIGH**
- **Infinite UIA auth loop** when removing a session — blocks device management;
  hardcodes a password identifier and only renders a password box (breaks SSO/dummy
  stages). (`#980`) — *high / medium*
- **Login fails against alternate homeservers on Win11.** (`#977`) — *high / medium*
- **No in-app account registration** (`/register`) — sign-in only. — *medium / medium*
- **No QR-code / rendezvous cross-device sign-in.** — *low / medium*

---

## 4. Roadmap by Horizon

### 🟢 Near-term — *Next release: stabilize core flows*
Fix the bugs that block Commet as a primary messenger, plus high-value quick wins.

| Priority | Item | Issues |
|---|---|---|
| **P0** | Restore Firebase/FCM push on Google-Play builds (un-stub notifier) | `#937`, `#810` |
| **P0** | Fix infinite UIA auth loop when removing a session (SSO/dummy stages) | `#980`, `#977` |
| **P0** | Populate the room list / sidebar reliably (Web + Linux) | `#836` |
| **P0** | Fix permission/role edits that silently fail; make `Owner(150)` assignable in v12 | `#958`, `#855` |
| **P0** | Add unban action + banned-user list | `#958` |
| **P0** | Crash-harden VoIP start without TURN servers | `#972` |
| **P1** | Fix `.apng` link-preview crash | `#900` |
| **P1** | Fix room-icon cache returning `null` on first notification | `#945` |
| **P1** | Guard against double-send on fast Enter | `#868` |
| **P1** | Save draft messages when switching rooms | `#952` |
| **P1** | In-app 24-hour clock toggle | `#982` |
| **P1** | Add a video-call entry point (use existing `CallType.video`) | `#1001` |
| **P1** | Fix minimize-on-close trapping the process; add quit/exit button | `#842`, `#985` |
| **P2** | Clear jump-to-original highlight on scroll/timeout | `#961` |
| **P2** | Fix sticker-pack create/import buttons disappearing | `#860` |
| **P2** | Preserve trailing spaces after URLs; fix spurious newlines | `#955`, `#903` |
| **P2** | Render `/me` & `/rainbowme` correctly; allow editing emotes | `#829`, `#813` |

### 🟡 Mid-term — *1–2 releases out: parity & larger features*
Close parity gaps with mature clients and deliver frequently-requested features.

| Priority | Item | Issues |
|---|---|---|
| **P0** | App-level notification settings + push-rule/keyword editor (wire dead modifiers) | `#858`, `#845` |
| **P0** | Reliable UnifiedPush delivery (end-to-end against ntfy et al.) | `#963`, `#937` |
| **P0** | Bulk re-decrypt whole room + batch key re-request | `#975`, `#933` |
| **P0** | Encryption setup in OOBE / post-login (verify, cross-sign, backup) | `#1002`, `#852` |
| **P0** | Client-level ignore/block + content reporting | `#971`, `#896` |
| **P1** | Global cross-room message search | — |
| **P1** | Public room directory / "Explore rooms" browser | — |
| **P1** | Voice messages (record & send, MSC3245) | — |
| **P1** | Element Call screen-share with audio | `#969` |
| **P1** | Separate DM / spaceless view; standalone rooms in sidebar | `#995`, `#880`, `#836` |
| **P1** | History-visibility setting + room-version selection | `#851`, `#816`, `#855` |
| **P1** | Mark read/unread, low-priority tag; fix unread vs Continuwuity | `#845`, `#935` |
| **P2** | Lightbox controls + video playback options | `#954`, `#919`, `#883` |
| **P2** | AVIF/SVG support + animated stickers | `#820`, `#940` |
| **P2** | Message forwarding + copy-permalink | — |
| **P2** | In-app account registration | — |
| **P2** | Custom fonts, animation-speed, theme editor, Discord timestamps | `#939`, `#932`, `#894`, `#921` |

### 🔴 Long-term — *Architecture & platform*
See the dedicated **Long-Running Initiatives** section below.

---

## 5. 🏗 Long-Running Initiatives

These are multi-release programs, not single tasks. Each spans several subsystems,
needs end-to-end validation across servers/platforms, and should have a continuous
owner. They are the backbone of the long-term roadmap.

### LR-1 · Reliable Push Notification Program *(Android → multi-platform)*
**Why it's long-running:** spans native Android (Firebase/UnifiedPush receivers),
the Dart notifier stack, a fragile background-decryption service, avatar caching,
and *new* platform backends (APNs/PushKit, web push). Each is a separate moving part
that must be validated against multiple gateways and homeservers.
**Issues:** `#937`, `#963`, `#810`, `#858`, `#945`, `#845`
**Workstreams:**
- Restore real Firebase/FCM integration; verify token registration on GMS builds.
- End-to-end UnifiedPush against ntfy & other distributors; fix envelope parsing & de-dup.
- Rework the background handler to reuse one `MatrixBackgroundClient`; harden headless decryption.
- Fix avatar cache miss + add invalidation/TTL.
- Real app-level notification settings: global rules, keyword/`@room` editor, wire `DoNotDisturb`/`HideContent`.
- APNs/PushKit (iOS/macOS) and web-push backends *(blocked on LR-5)*.

### LR-2 · Encryption Robustness & Key-Backup Lifecycle
**Why it's long-running:** touches onboarding, the bootstrap/SSSS state machine,
bulk re-decryption, cross-session trust indicators, bridge-bot key sharing, and
offline export/import — all interlocking and security-critical.
**Issues:** `#1002`, `#975`, `#933`, `#852`, `#873`, `#864`, `#851`, `#855`
**Workstreams:**
- Encryption/verification/key-backup step in OOBE and post-login.
- Bulk "re-decrypt whole room" + batch key re-request + re-import from backup.
- Handle `askUnlockSsss`/`askBadSsss` with retry/error UI; render numeric/decimal SAS.
- Global + per-room trust indicators (unverified sessions, backup-missing banners).
- Key-sharing policy for bridge-bot/unverified devices; guard against re-enabling E2EE.
- Offline E2E room-key export/import to an encrypted file.

### LR-3 · Calling & Element Call Maturity
**Why it's long-running:** two call stacks (legacy WebRTC + LiveKit/MatrixRTC) must
converge; group calling, ringing, E2EE call setup, stats, and screenshare-with-audio
each need protocol-level work (MSC4143/3401/4140) plus cross-platform media plumbing.
**Issues:** `#1001`, `#969`, `#972`, `#920`, `#919`, `#918`, `#884`, `#883`, `#854`, `#965`
**Workstreams:**
- Screen-share with system/screen audio on both stacks.
- LiveKit accept/decline + ring/invite flow + missed-call handling.
- Group calls in arbitrary rooms; video-call entry point.
- Crash hardening (TURN-less servers, null nav context); Wayland source picker + KDE fix.
- Mic input-gain control + hide-non-video tiles; real call stats/quality indicators.
- Human-readable call timeline events; revive or remove screen-share annotation.

### LR-4 · Performance & Sync Overhaul for Large Accounts
**Why it's long-running:** architectural — adopting sliding/simplified sliding sync
(MSC4186/3575), memoizing sidebar/recent rebuilds, streaming media instead of
whole-file in-memory handling, and profiling timeline/call hot paths per platform.
**Issues:** `#970`, `#965`, `#918`, `#909`, `#936`, `#836`, `#827`, `#808`, `#811`
**Workstreams:**
- Adopt sliding / simplified sliding sync for fast startup with many rooms.
- Memoize sidebar `getSpaces` and home-screen re-sort; profile-cache & member-list speed-ups.
- Streaming/queued attachment upload & download with progress + retry.
- Faster media-playback start; instant downloaded-media display.
- Investigate animation stutter, WebGL-less freeze, ramdisk execution.

### LR-5 · iOS / macOS / Web Platform Coverage
**Why it's long-running:** per-platform CI/build pipelines, Apple push (APNs/PushKit),
web push & WebGL constraints, platform media/notification backends, store/distribution,
and the iOS localization build blocker.
**Issues:** `#998`, `#895`, `#862`, `#836`, `#808`
**Workstreams:**
- Add iOS/macOS/web targets to CI build & release workflows.
- Fix the iOS/Xcode localization build blocker (`messages_all.dart`).
- Apple push (APNs/PushKit) + web-push backends.
- Web-specific constraints (WebGL requirement; web room-list population).
- Platform media/notification parity + store distribution + native macOS/iOS layers.

### LR-6 · Moderation, Safety & Room-Version Correctness
**Why it's long-running:** combines correctness fixes (PL evaluation, version-aware
roles), new moderation surfaces (unban, reasons, reporting), account-wide safety
(`m.ignored_user_list`, CSAM), and room-version selection — across rooms, settings,
and the timeline.
**Issues:** `#958`, `#855`, `#816`, `#971`, `#896`, `#851`
**Workstreams:**
- Fix PL inconsistency; version-aware `availableRoles`; custom levels; `Owner(150)` in v12.
- Pre-flight permission validation + success/failure feedback.
- Unban + banned-user list; ban/kick reasons; redact-on-ban.
- Client-level ignore/block (`m.ignored_user_list`) + per-user invite blocking.
- Content reporting to homeserver; CSAM/NSFW handling.
- History-visibility setting + room-version selection (incl. `additional_creators`).

### LR-7 · Accessibility Program
**Why it's long-running:** a11y must be retrofitted across custom-painted widgets,
the timeline, dialogs, and the `tiamat` design system — there is currently **zero**
`Semantics` usage. It needs semantics, focus order, contrast, and ongoing testing
with assistive tech — a sustained cross-cutting effort.
**Issues:** —
**Workstreams:**
- Add `Semantics`/`semanticLabel` to atoms and `tiamat` components.
- Make the timeline & composer screen-reader navigable.
- Focus order, keyboard navigation, and contrast audit.
- Establish accessibility testing in CI/QA.

### LR-8 · Extensibility & Widget Sandboxing *(emerging)*
**Why it's long-running:** widgets currently run **unsandboxed** with full app/system
access and no crash isolation; there is no discoverable bot/command framework. Safe
extensibility is a security architecture effort.
**Issues:** `#974`, `#887`
**Workstreams:**
- Capability-scoped widget sandboxing + resource limits + crash isolation.
- Discoverable slash-command framework with composer autocomplete/help.
- Forum-style channel room type (MSC3765); file-manager room type/widget.
- Bot/integration profile support.

---

## 6. ⚡ Quick Wins
Small, high-value, low-effort items — good first issues / momentum builders.

- Un-stub Firebase/FCM push (one-file fix restoring Android push). `#937`, `#810`
- Fix room-icon cache returning `null` on first notification. `#945`
- In-app 24-hour clock toggle. `#982`
- Add unban action + banned-user list. `#958`
- Filter `KeyRepeatEvent` to stop double-send on fast Enter. `#868`
- Clear jump-to-original highlight on scroll/timeout. `#961`
- Add a video-call button using the already-plumbed `CallType.video`. `#1001`
- Preserve trailing spaces after URLs on send. `#955`
- Fix sticker-pack create/import buttons disappearing after first pack. `#860`
- Make `Owner(150)` assignable in v12 rooms in the role picker. `#958`
- Add an explicit quit/exit button; fix minimize-on-close trap. `#985`, `#842`
- Dissolve single-item sidebar folders; ellipsis for long space names. `#968`
- Hover tooltip for who-reacted on desktop. `#962`
- Markdown wrap actions (bold/italic/code) in the selection menu. `#956`
- Null-safety guard in `Api.getPresence`. `#924`
- Calendar: configurable week-start day. `#841`
- Avoid hard NetworkManager dependency in Flatpak. `#930`

---

## 7. Appendix — Open Issues by Theme

*(86 open issues in `commetchat/commet`, clustered. Priority = likely user impact.)*

| Priority | Theme | Issues |
|---|---|---|
| HIGH | Push notifications & reliability | `#963 #937 #810 #858 #945 #845` |
| HIGH | Encryption, key backup & decryption | `#1002 #975 #933 #852 #873 #864 #851` |
| HIGH | VoIP / video calls & screen sharing | `#1001 #972 #969 #968 #920 #919 #918 #884 #883 #854 #844` |
| HIGH | Room list / sidebar / spaces | `#836 #880 #995 #967 #999 #887` |
| HIGH | App performance & resource usage | `#970 #965 #918 #909 #808 #811` |
| HIGH | Moderation, permissions & room versions | `#958 #855 #816 #971 #896` |
| HIGH | Authentication, sessions & login | `#980 #977 #998 #895` |
| HIGH | Networking & server compatibility | `#821 #935 #862 #924` |
| HIGH | App stability / crashes | `#900 #972 #811 #808 #924` |
| MEDIUM | Linux packaging, install & distribution | `#931 #930 #913 #879 #819 #814 #842 #985` |
| MEDIUM | Message composition & input UX | `#868 #952 #956 #960 #925 #955 #875 #827` |
| MEDIUM | Message rendering & formatting | `#903 #813 #829 #940 #820 #967` |
| MEDIUM | Media viewing & playback controls | `#954 #919 #898 #883` |
| MEDIUM | Timeline navigation & reactions | `#961 #962 #861 #936 #938` |
| LOW | Theming, customization & display | `#982 #939 #932 #894 #921 #841 #881` |
| LOW | Stickers & GIF tooling | `#860 #940 #925` |
| LOW | Misc (translation, file manager, quit) | `#872 #974 #985 #880` |

### Most impactful open bugs
1. `#937` — Push notifications don't work on either Android build *(systemic; app unusable as primary messenger)*
2. `#933` — Decrypting old messages often fails *(E2EE is the headline feature; lost history)*
3. `#836` — Web/Linux show no rooms in the sidebar *(total-loss for affected users)*
4. `#980` — Can't remove session (infinite auth) *(blocks device/security management)*
5. `#958` — Moderation impossible: missing permissions + PL inconsistency *(every room admin)*

### Most requested / valuable features
1. `#952` — Save draft messages when switching rooms *(table-stakes; every user)*
2. `#969` — Element Call screen-share with audio *(strategic VoIP path)*
3. `#995` — Separate DM and spaceless chat *(core navigation)*
4. `#851` — Change room message history visibility *(standard admin control)*
5. `#982` — 24-hour clock *(high-demand i18n win)*

### Parity gaps vs mature clients *(not all have issues filed)*
**High:** global cross-room search · public-room directory · voice messages ·
ignore/block list · accessibility semantics · iOS/macOS/web parity.
**Medium:** location sharing · report message · message forwarding · copy-permalink ·
keyword push-rule editor · sliding sync · in-app registration.
**Low:** scheduled send · draft persistence · QR cross-device sign-in · edit-history
viewer · offline key export · low-priority tag · mark-all-as-read.

---

*Generated from a multi-agent audit of the codebase + open-issue tracker. Issue
numbers reference `github.com/commetchat/commet`. Re-run the analysis as the tracker
and code evolve.*
