# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and versioning adheres to [Semantic Versioning](https://semver.org/).

## [1.0.1] — 2026-10-15

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
- All popup window titles include the version number, e.g. `CAScreenGuard V1.0.1 · Configuration needs to be rebuilt`.

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

[1.0.1]: https://github.com/Conste11ation117/CAScreenGuard/releases/tag/v1.0.1
[1.0.0]: https://github.com/Conste11ation117/CAScreenGuard/releases/tag/v1.0.0
