# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and versioning adheres to [Semantic Versioning](https://semver.org/).

## [3.2.0] — 2026-10-29

### Repository layout

- Reorganised into `src` / `dist` / `tools` / `docs`: hand-written sources under `src\`
  (`CAScreenGuard-demo.ps1` is now `src\CAScreenGuard.ps1`), build output under `dist\`, build and
  generator scripts under `tools\`, documentation and screenshots under `docs\`; the bridge scripts moved
  to `src\bridge\` and their notes to `docs\bridge.md`.
- `.gitignore` now ships only the two `dist\` artifacts; every other generated file stays out.
- The build script and the release packaging list follow the new paths.

### Documentation

- Both READMEs, SECURITY and the bridge notes rewritten: filler and marketing phrasing removed, facts
  kept. Added the parts never documented before - the top-left status chip, in-place upgrade, the
  precision tiers. SECURITY's supported version corrected from 1.0.x to 3.x.

### Installer

- The welcome page now carries one optional suggestion: if you use DeepSeek Harness, install the
  companion plugin `dsh-get-session-status` so the lock screen can show whether the agent is working or
  waiting for you. That file holds state only, no conversation content.
- Fixed clipped text: the welcome-page blurb outgrew its box in the previous version (English needs one
  line more than Chinese), so both languages were re-measured and the layout re-spaced.
## [3.1.0] — 2026-10-28

### Any agent harness can report its state

- **New `bridge\` layer**, decoupled from any harness internals. The lock screen only knows one file
  contract (`%LOCALAPPDATA%\CAScreenGuard\agents\<source>.json`), so adding a harness never means touching
  the lock screen.
  - `cascreenguard-status.ps1`: one command writes one state — made for hooks;
  - `cascreenguard-watch.ps1` + `watch.json`: a generic watcher that infers from session-log activity,
    needing no configuration on the other side;
  - `README.md`: hook recipes per harness (**not verified on this machine**; apply after installing one).
- Both use only stock Windows PowerShell 5.1; writes are temp-file + atomic replace.

### State precision, so "unknown" is no longer reported as "finished"

- State files gain an optional `precision` field: `exact` (default, real hook) or `inferred` (log-based guess).
- The lock screen switches display tiers on it:
  - `exact` → `DSH 等你回答 · 3 分钟` (amber) / `DSH 正在工作 · 已 6 分钟` (green) /
    `DSH 已完成 · N 分钟前` (grey);
  - `inferred` → **`Codex 最后活动 · 5 分钟前`** (grey; never claims completion, never amber).
- When all we know is "the log went quiet", the lock screen no longer asserts "the turn ended".
- With mixed sources, `exact` wins; the chip names its source (a product name is not content).
- The old format (no `precision`) is read as `exact`, so the running DSH plugin needs no change or restart.
## [3.0.0] — 2026-10-20 Sonnet

### The lock screen shows what the agent is doing

- **A status chip in the top-left corner.** The mask reads the JSON written by the companion plugin
  ([dsh-get-session-status](https://github.com/Conste11ation117/dsh-get-session-status)) and shows one of:
  - `DSH 正在工作 · 已 6 分钟` — green dot, neutral plate;
  - `DSH 等你回答 · 2 个对话 · 3 分钟` — **amber plate and text**; the only state that wants you back;
  - `DSH 已完成 · 7 分钟前` — grey dot, dim text.
- **Multiple conversations at once.** The plugin writes one file per session under `agents\`; the chip
  aggregates them into a single line (`2 个对话`), so a dozen parallel sessions never turn into a wall of
  chips. The newest/oldest one supplies the elapsed time.
- **Only conversations alive since the lock started are shown.** A `waiting` state that is older than the
  moment the screen locked is old news and stays hidden; a `working` session is always shown, however long
  it has been running. Anything older than ten minutes is dropped as stale.
- **State only, never content.** No prompt, answer, project name or file name ever reaches the lock screen.

### Under the hood

- Reads on the existing 10-second heartbeat; no new timer, no network, no extra process.
- Falls back to the single `agent-state.json` when the `agents\` directory is absent (older plugin builds).
## [2.2.0] — 2026-10-19

### New look

- **The brand mark moved to the bottom-left corner of the screen** — it used to sit inside the card, to
  the left of the title. To its right is the product name set in JetBrains Mono, pre-rendered to a PNG and
  embedded in the script: nothing has to be installed on the user's machine, and no font work happens at
  paint time (`make-wordmark.ps1` regenerates the asset).
- **Battery, network and Wi-Fi strength in the bottom-right corner, Windows-lock-screen style**: one
  rounded, translucent plate holding a network icon and the battery — icon plus percentage, a charging
  bolt that flips to a dark cut-out on a full white fill, and a red fill at 15% or below. The network icon
  is a globe when the link is wired, a slashed globe when nothing is up, and Wi-Fi arcs while on Wi-Fi,
  with one, two or three segments lit according to the signal. Signal strength comes from
  `netsh wlan show interfaces` every 30 seconds; the Wi-Fi name itself is deliberately never read.
  Everything is refreshed every 10 seconds, not on every 250 ms tick.
- **A hand mark for privacy, back at the card title's left** — the Unicode raised hand (U+270B) drawn
  in the system symbol font, in white, so it stays crisp at any DPI and needs no extra font installed.
- The card title now sits centred together with that hand mark.
- **The sound cue on a successful unlock is gone.** The error and warning cues stay — they are feedback
  for a mistake, which is worth hearing.

### Setup

- **In-place upgrade.** Running a newer installer on a machine that already has CAScreenGuard asks once,
  then replaces the program files in the existing folder. The unlock password, authorization code, hint,
  hotkey, desktop shortcut and both credential stores are left exactly as they are; the configuration
  file is not written at all.
- **Everything is backed up first.** The old program files and both registry keys — as a standard `.reg`
  you can double-click to restore — go into `backup-<timestamp>\` inside the install folder.
- The upgrade refuses, with a reason and without touching anything, when the install folder is missing or
  unrecognised, the configuration file is gone, or CAScreenGuard is still running.
- The welcome page now points at the releases page for new versions.
- Installs record their version (`HKCU\Software\CAScreenGuard\Version`), which is what the next upgrade
  compares against.

## [2.0.0] — 2026-10-16 Eclipse

The lock screen becomes a real screen. This release is mostly about how it looks and feels; on top of that
it closes two gaps: a location you cannot write to now offers a way forward instead of a clipped one-liner,
and a wake request that lapsed across sleep/hibernate is now re-issued.

### New look

- **Wallpaper-backed mask.** The cover is no longer flat black: it reads the current desktop wallpaper
  (`SPI_GETDESKWALLPAPER`), scales it to cover the whole virtual desktop and dims it, so a blanked screen
  looks like the lock screen instead of a black rectangle. If the wallpaper cannot be read (solid colour,
  slideshow, corrupt file) it falls back to plain black, silently, on every launch.
- **A clock, laid out the way Windows 11 does it.** Large time and date above the card, using Windows 11's
  measured proportions (digit height 71 DIP, top margin 162 DIP, 32 DIP gap); on small screens it steps the
  size down instead of overflowing. The card shrank by ~80 px and went back to being centred so it stays
  clear of the clock.
- **A proper card.** Rounded corners, the SG brand mark drawn as vectors (no longer decoded from the .ico),
  and a capsule-shaped password box whose outline shows focus, a wrong password, and the lockout state.
- **The card is dimmed harder.** One dark layer over the whole screen, a second one over the card itself —
  so the card is always darker than its surroundings and picks up a hint of the wallpaper instead of being
  a patch of dead black.

### Polish

- The screen goes dark *first*; the wallpaper is composited and painted a second later, so you never catch
  it mid-draw. The mask is double-buffered.
- Unlocking fades the mask out (~0.7 s, ease-out) and then restores the display; blanking again stays
  immediate.
- The lockout notice replaces the two hotkey lines instead of reserving dead space, which let the card
  shrink by ~80 px and sit centred again.
- The dimming went one notch deeper (about 45% → 31% brightness): the wallpaper is still there, but it sits
  back and the clock and card read more clearly.
- Chinese text is now uniformly Microsoft YaHei. The clock used to ask for JetBrains Mono, which has no
  CJK glyphs — Windows substituted SimSun for every Chinese character.

### Fixed

- The brand mark stayed opaque in wallpaper mode; `Rfc2898DeriveBytes` was never disposed; when the idle
  query failed the mask fought for focus on every tick; the marker write condition was too brittle.
- Six duplicated blocks merged (new-password validation, dialog DPI, font constants, card positioning,
  primary-screen size, external-credential cleanup).
- P/Invoke signatures corrected; the keyboard hook now defends against a null pointer.
- The icon was redrawn: only the two large letters **SG** remain inside the black square — the product name
  and the key are gone, because both turned into mush below 48 px. Small frames are now written as BMP,
  which stops .NET/GDI from decoding PNG frames into colour noise.

### Installer: a way out when the location is not writable

- Installing into a location you cannot write to (say `C:\Program Files`) used to produce a single red line
  504 px wide while the message itself measures 931 px — the "underlying error" half was always clipped by
  the control, so users could not report anything useful. A failure now opens a dialog with the **complete
  reason** (exception type + `HResult` + message, selectable and copyable) and a shield-bearing
  **"Retry as administrator"** button.
- The elevation step does exactly two things: create the installation folder and grant write access to
  **your current account**. So the password and authorization code never travel on the command line (other
  processes can read command lines), and the installed files are owned by you — later config writes, logs
  and uninstalling need no elevation at all.
- The elevation helper only accepts a folder named `CAScreenGuard-<date>`, so it cannot be abused as a
  general "grant write access anywhere" tool; it never touches the password or the configuration — that
  code path does not contain them. If the target folder already holds something, it is still refused: only
  an empty folder we just created is adopted.
- **The LICENSE now ships with the copies.** MIT requires the copyright and permission notice to travel
  with the software; the released script has its comments stripped and the `.cs` files never had a
  copyright header, so an installed copy carried no notice at all. The installer now drops a byte-identical
  `LICENSE` into the installation folder, and the Setup release package ships it too.

### Stability

- **Periodic wake-request re-check**: `SetThreadExecutionState` is per-thread, and a request may no longer
  count after sleep/hibernate. It is now re-issued every 30 seconds; a failed re-issue (return value 0) is
  recorded.
- **Sleep-resume detection**: the timer runs at 250 ms, so a gap of more than 5 seconds between two ticks is
  treated as "probably just resumed from sleep" — keep-awake is re-issued, the mask is pushed back to the
  top, and the screen is blanked again if it was blank.
- **UI-thread exception fallback**: an event handler that throws no longer takes the whole process down
  (the mask stays); it is recorded and the program keeps running. Such *handled* exceptions are
  deliberately kept out of `crash-*.log`, so the next launch does not report a crash that never happened.
- **`guard.log`**: `%LOCALAPPDATA%\CAScreenGuard\guard.log` records startup/exit, the two events above and
  UI-thread exceptions, truncated automatically past 64 KB. It contains **no user name, machine name, path
  or PID** — it is meant to be sent in for troubleshooting; `crash-*.log` is a local file and still carries
  `user@machine` and the pid.

## [1.1.0] — 2026-10-15

A full review pass over the codebase, plus a correction to how `Ctrl+Alt+Del` was described.

### Fixed

- **The shutdown / crash monitor never ran.** The whole block sat inside the "another instance is
  already running" branch, so a normal start skipped it (the feature the docs described was dead
  code) — while starting a second copy *did* run it, wrongly reporting an unclean exit and deleting
  the running instance's flag file. Moved out of that branch; verified with a syntax-tree check.
- **Reinstalling could destroy your authorization code for good.** The old install (registry key and
  the `%APPDATA%` credentials — the only home of the auth-code hash) was deleted *before* the new
  location was validated. Reinstalling to an unwritable folder, or to one that already had that day's
  subfolder, left you with no new install and an unrecoverable authorization code. The new location is
  now checked and probed first; a failed drop cleans up after itself instead of leaving a folder that
  makes every retry say "already exists".
- **Choosing 简体中文 on a non-Chinese Windows never stuck.** `Str.Detect()` ran in the wizard's
  constructor, so reopening the wizard after a language switch overwrote the choice with the system
  language — and the `Lang` written to the registry was always `en`.
- The uninstaller looked for the runtime state in `%LOCALAPPDATA%\CAScreenGuard\state`, which never
  exists (the script writes `running.flag` / `crash-*.log` one level up), so uninstalling left those
  files behind. It now removes exactly those files — deleting the whole folder would have taken the
  install directory with it at the default location.
- The screen-saver setting could stay disabled forever: the original value only lived in memory, so a
  killed process or a power loss never restored it. It is now written to disk first.
- Timer errors went into a variable nobody read. They now go to `tick-errors.log` — putting them in
  `crash-*.log` would have had the next start report them as "the software crashed".
- `GetLastInputTick()` returned `0` on failure, which collides with a legal tick value and with the
  initial `BlankTick`; it now returns `uint.MaxValue` (the self-test accepts neither).
- `/silent` skipped every input check: `setup.exe /silent <dir> "" "" ""` installed an empty unlock
  password. It now runs the same validation as the wizard.
- Deleting the desktop shortcut did not notify the shell, so its global hotkey lingered until sign-out.
- English UI no longer leaks Chinese punctuation (`」。`, full-width brackets).
- `k59` split: the "your configuration was tampered with" paragraph is now only shown on the rebuild
  path, not in the ordinary change-password window.
- Installing disables the install button while it works; `Main` has a top-level `try/catch`; a missing
  payload now gives a readable error instead of a Base-64 exception.
- Dead code removed (`WaitForMonitorWork`, `HideConsole`); `monitorTarget` / `BlockSystemKeys` are
  `volatile`; `AttachThreadInput` is released in a `finally`.
- Version strings in popup titles are built from one constant instead of 18 hard-coded literals
  (also removes a second, independent `DisplayVersion` in the installer).

### Build pipeline

- The comment stripper no longer runs a per-line "drop blank lines / trim trailing whitespace" pass:
  it does not understand tokens and silently shortened the contents of here-strings and verbatim
  strings — with both the parse check and the compile check staying green.
- Block comments keep their line breaks (removing them could glue tokens: `int/**/y` → `inty`).
- BOM normalisation strictly validates UTF-8 instead of silently substituting bytes, which used to
  rewrite an ANSI/GBK source file in place, irreversibly.
- The compile staging directory must be an ASCII path (`csc` cannot handle non-ASCII arguments).
- The no-icon retry is checked for its exit code; `#Requires` matching is case-sensitive.
- The release workflow's file list is verified against `git ls-files`, so a new file cannot be
  silently dropped from the zip.

### Packaging

- Each release now ships two zips, both with a single top-level folder inside:
  `CAScreenGuard-All.zip` (the whole project) and `CAScreenGuard-Setup-windows-x86.zip`
  (installer + icon + the two READMEs, for a machine that only needs to install it).
- Release bodies carry the full English changelog, and the release title follows the
  `v<version> Navigator` naming.

### Docs

- Corrected the runtime state path, the offline package name, and the missing `-Ver` entry.
- **Removed the claim that `Ctrl+Alt+Del` is a weakness.** Nothing on that screen exposes the desktop:
  sign-out and shutdown end the session (or reboot), so it is never revealed, and the flag file records
  it; Task Manager does start, but the mask re-asserts itself on top every 250 ms and takes focus back,
  so there is nothing on it you can click.

## [1.0.0] — 2026-10-14

First public release.

### Core features

- **Display-off protection**: on launch it immediately turns the monitor off (**monitor only** — no sleep, no Windows session lock, the system stays awake) and covers the desktop with a full-screen black mask on the topmost layer. Only the correct unlock password restores the screen and exits.
- **Swallows system keys while masked**: `Win`, `Alt+Tab`, `Alt+Esc`, `Ctrl+Esc` are all intercepted, so nobody can peek at the desktop via the Start menu, task-switcher thumbnails, or `Win+G`.
- **Mistake-friendly**: `Ctrl+Backspace` clears what you typed; `Esc` blanks again immediately (typed text kept); after 25 s idle it blanks again automatically (typed text kept; configurable via `-IdleBlankSeconds` from 5 to 600 s).

### Password & authorization code

- Both the unlock password and the authorization code are stored only as **PBKDF2-SHA1 hashes (120,000 iterations + random salt)** — never in plaintext.
- The **authorization code** is the only fallback if you forget the unlock password; it is frozen at install time and cannot be changed afterwards. `Ctrl+Shift+Alt+E` uses the authorization code to set a new unlock password; the screen stays locked afterwards.
- Input boxes disable the IME; only ASCII characters (letters/digits/symbols) are accepted, so you never end up with a password you cannot type.
- Repeated wrong unlock passwords trigger escalating cooldowns (up to 30 seconds).

### Lockout (penalty mechanism)

- **8 wrong unlock passwords in a row**: further input is disabled; the bottom of the card shows "Password entry is disabled" plus "Power off using the physical power button, or press Ctrl+Alt+Del and shut down from the security screen".
- **A wrong authorization code produces no feedback at all** — it does not confirm that the guess was wrong, and it does not reveal how many attempts are left, so the dialog cannot be used as an oracle.
- **3 wrong authorization codes in a row**: in addition to a red warning, all input inside the dialog is disabled (input boxes and the confirm button greyed out, only Quit left), along with the same shutdown prompt.
- Two levels of severity:
  - "Change unlock password" via `Ctrl+Shift+Alt+E` — the lockout lasts only for the current run;
  - "Configuration needs to be rebuilt" (tampered config) — **permanent lockout**, written to both the registry and `%APPDATA%`; it survives closing the program and rebooting; only reinstalling clears it.
- Both cases advise you: if you are sure you did not misremember, consider whether you are facing a deliberate attack.

### Config integrity

- The config file `.cascreenguard.config.json` is hidden and carries an **HMAC-SHA256 digest** internally. The digest key is not stored in the config; it lives separately in two "external credentials": the registry key `HKCU\Software\CAScreenGuard` and `%APPDATA%\CAScreenGuard\store.json`.
- Config **deleted** or **modified by even one byte** → next launch classifies it as `deleted` / `modified`, **refuses to lock**, and shows the "Configuration needs to be rebuilt" dialog, requiring the authorization code to confirm identity before setting a new unlock password.
- External credentials missing → classified as `unprovable`, also refuses to lock and prompts you to reinstall.
- This also closes the "delete the config file to reset the password" shortcut.

### Unexpected shutdown / crash detection

- On entering lock, a flag file `%LOCALAPPDATA%\CAScreenGuard\running.flag` is written; it is deleted on a clean exit.
- If the next start finds the flag still present, the previous session did not end cleanly, and it tells you which of two things happened:
  - **a crash log exists** → the software itself failed; the log path is shown so you can report it with reproduction steps;
  - **no crash log** → it was not a crash: someone may have pressed the power button, signed out or shut down via `Ctrl+Alt+Del`, or simply killed the process — you are advised to change your Windows password, run an antivirus scan, and check the physical safety of your workspace.
- Crash logs are written to `%LOCALAPPDATA%\CAScreenGuard\crash-*.log` (including exception type, stack trace, PS/OS versions); only the 10 most recent are kept automatically.

### Sleep & hibernate

- While locked, the script holds `SetThreadExecutionState(ES_CONTINUOUS | ES_SYSTEM_REQUIRED)`, which blocks idle-triggered sleep / hibernate. It **deliberately omits** `ES_DISPLAY_REQUIRED`, which would fight the blanking.
- It does not block you from explicitly choosing Sleep (Start menu → Sleep, power button, lid close), and it does not touch your power plan.

### Installer

- Single-file `CAScreenGuard-Setup.exe`: no console window, app icon included, **fully bilingual (Chinese/English)**.
- **Welcome page**: app icon, welcome title, author and license info, short introduction, antivirus note, link to the docs, **interface language selector** (简体中文 / English — switching restarts the wizard); "Next" takes you to the install page.
- Install page: install location (with a live "will install to …" preview and a "Browse…" button), unlock password, authorization code, authorization hint, hotkey; input requirements (length, character set, case sensitivity) are stated on the page. Below is an **amber uninstall notice**: use only the uninstaller provided by this program; do not use third-party management tools to uninstall.
- After clicking "Install", the status line immediately turns green: "Installation may take 3–10 seconds. Please wait and do not close this window." — so users do not assume it is frozen and force-kill the process; on error the same line turns red with the reason.
- It installs into a dedicated sub-folder `<where you chose>\CAScreenGuard-<date>\`: if that sub-folder already exists, installation is **refused**; if already installed, it **reinstalls in place** (the previous copy is removed first).
- Automatically creates a desktop shortcut (icon + **global hotkey** `Ctrl+Alt+<letter/digit>`, stored in the shortcut's own "Shortcut key" field — no background process, no autostart entry).
- Registers in "Apps & features" (publisher `Conste11ation117`); uninstalling removes the registry keys, external credentials, desktop shortcut, **and the whole installation folder** (including the parent folder created at install time).
- The language chosen at install time is written into the external credentials; the installed program **displays in English even on a Chinese Windows system**.

### Bilingual UI & version number

- Both the main program and the installer ship with Chinese and English UI text built in. Language priority: command-line `-Lang` > chosen at install time > system display language.
- All popup window titles include the version number, e.g. `CAScreenGuard V2.0.0 · Configuration needs to be rebuilt`.

### Icon

- Inspired by JetBrains product icon composition: two tilted, rounded-corner colored squares (cyan-blue + purple) overlaid, with a black square pressed in the center containing the two large letters **SG** and the product name **CAScreenGuard** (JetBrains Mono, sky blue), plus a grey **key** (pointing up) inside a designated rectangular area on the right.
- At 128/256 px the full design is shown; at smaller sizes the product name is replaced by short white dashes to avoid blurring into a mess.
- Generated by `make-icon.ps1`, outputting seven sizes in one go: 16/24/32/48/64/128/256.

### Build & self-test

- `build-setup.ps1` does it all in one command: strips comments and blank lines from the main script using the PowerShell **syntax tree** → strips comments from both C# source files **and compiles them first to verify nothing broke** → embeds the four files into the installer → compiles a single-file exe.
- Before building, BOM and line endings are automatically normalised (to avoid editors eating the BOM and turning Chinese text into mojibake).
- `CAScreenGuard.ps1 -SelfTest` runs 8 checks: config read/write, wrong password rejected, integrity verdicts (ok / modified / deleted), mask size, UI construction, idle-time API, wrong-password handling, successful unlock.

### Command-line parameters

| Parameter | Meaning |
|---|---|
| `-ResetPassword` | Open "Change unlock password" right away (needs the authorization code; skips blanking this time) |
| `-IdleBlankSeconds <5..600>` | Idle timeout before blanking again, default 25 seconds |
| `-Lang auto\|zh\|en` | Force the UI language |
| `-SelfTest` | Self-test, does not blank the screen |

### Known limits (important)

- It is a **visual barrier**, not a security boundary: it does not encrypt the disk, does not hide running programs, and does not block network access.
- `Ctrl+Alt+Del` is not an opening: nothing on that screen exposes the desktop.
- Anyone who can modify the program can bypass it (swap the script, or just kill the process); elevating privileges would only block "a non-elevated process cannot kill it" — at the cost of a UAC prompt every launch, higher antivirus sensitivity, and a larger attack surface — which is not worth it for the goal of "stopping a passer-by from glancing at your screen".
- Known not to block: user-initiated Sleep, lid close (if lid close is set to Sleep in power settings), and a sign-out / shutdown started from the `Ctrl+Alt+Del` screen (they end the session rather than revealing it).

[2.0.0]: https://github.com/Conste11ation117/CAScreenGuard/releases/tag/v2.0.0
[1.1.0]: https://github.com/Conste11ation117/CAScreenGuard/releases/tag/v1.1.0
[1.0.0]: https://github.com/Conste11ation117/CAScreenGuard/releases/tag/v1.0.0
