# CAScreenGuard

**English** · [简体中文](README.zh-CN.md)

# From the author: what does this software do?

**Keep long-running workflows going while the PC is unattended, and protect your ongoing work and private files from any undetectable peeking, theft, or tampering.**

*How was this built?*

*Co-developed with DeepSeek v4.1 flash, Kimi Code, DeepSeek Harness, and WorkBuddy.*

A tiny Windows tool that keeps an eye on your screen while you are away: it turns the monitor off
(**only the monitor** — no sleep, no session lock, the machine stays awake), covers everything with a
full-screen mask, and only the correct unlock password brings the screen back.

That mask is backed by your own desktop wallpaper (dimmed and stretched over the whole screen; it falls
back to plain black when the wallpaper cannot be read), with the time and date above the card laid out
the way Windows 11 lays out its lock screen — so a blanked screen looks like the lock screen rather than
a black rectangle. Your desktop never shows through.

- Version: **V2.2.0**
- Author: **@Conste11ation117**
- Requirements: Windows 10 / 11 with Windows PowerShell 5.1 (built in — nothing to install)
- License: [MIT](LICENSE)
- Not affiliated with JetBrains. The icon style is a homage to their icon family.

![Lock screen](docs/lock-screen.en.jpg)

*What a blanked screen looks like: the wallpaper, dimmed, with the time and date above it (laid out to
Windows 11's proportions) and the password card in the middle. The screen goes dark first and the
wallpaper is composited afterwards, so you never catch it mid-draw; unlocking fades the mask out over
about 0.7 s.*

![Rebuild dialog](docs/rebuild-dialog.en.png)

*What you get when the config file was deleted or modified: CAScreenGuard refuses to unlock and asks you
to confirm with the authorization code before setting a new unlock password. The screenshot shows the
state **after three wrong codes** — every input is greyed out, only "Quit" is left, and the block has been
written to disk, so reopening the program will not lift it.*

**How to get it:** `git clone` this repository, or download from
[Releases](https://github.com/Conste11ation117/CAScreenGuard/releases) — the `CAScreenGuard-Setup.exe`
in the repo is the same file. Double-click the wizard and you are done in about two minutes.

Each release ships two zips, so you can pick the smallest thing that does the job:

- **`CAScreenGuard-Setup-windows-x86.zip`** — just the installer, the icon and the two READMEs, for a
  machine that only needs to install it
- **`CAScreenGuard-All.zip`** — the whole project (sources, installer, docs, screenshots), for copying
  to a machine offline

---

## 0. Meta-positioning

**Keep long-running workflows going while the PC is unattended, and protect your ongoing work and private files from any undetectable peeking, theft, or tampering.**

## 1. What it is good for — and what it is not

**Good for:** stepping away for a few minutes (coffee, meetings, phone calls), shared or public desks,
running long jobs where you want the screen hidden but the session alive.

**Not for:** real secrets, a determined attacker, remote sessions or other accounts, or anything where
you need an actual security boundary.

> It stops a passer-by from glancing at your screen. It does not stop someone who deliberately digs
> into your machine. It does not lock the Windows session and does not encrypt anything.
>
> Nor does it need to intercept `Ctrl+Alt+Del`: **nothing on that screen exposes your desktop.**
> Sign-out and shutdown end the session (or reboot) — the desktop never becomes visible, and the flag
> file records that it happened. Task Manager does start, but the mask re-asserts itself on top every
> 250 ms and takes focus straight back, so there is nothing on it you can click.

If you need confidentiality, use Windows lock (`Win+L`) plus BitLocker.

---

## 2. While it is locked

| Action | Behaviour |
|---|---|
| Any key / mouse move | Lights the screen, reveals the password box (the desktop stays covered) |
| Unlock password + `Enter` | Unlock: the mask fades out (~0.7 s) → restores the screen, restores your screen-saver settings, exits |
| `Ctrl + Backspace` (or `Ctrl + U`) | Clear what you typed |
| `Esc` | Blank again immediately (typed text kept) |
| 25 s idle (configurable) | Blanks again automatically (typed text kept) |
| `Ctrl + Shift + Alt + E` | Open "Change unlock password" (asks for the authorization code); stays locked afterwards |
| `Win` / `Alt+Tab` / `Alt+Esc` / `Ctrl+Esc` | **Swallowed**, so nobody can peek through the Start menu or task-switcher thumbnails |

**What the locked screen looks like** (see the screenshot at the top):

- **Wallpaper-backed.** At startup it reads the current desktop wallpaper (`SPI_GETDESKWALLPAPER`) and
  scales it to cover the whole virtual desktop, then dims it. A solid-colour wallpaper, a slideshow or a
  corrupt file means no image — it falls back to the plain black mask, silently, decided on every launch.
- **Time and date**, placed above the card using Windows 11's measured proportions (digit height 71 DIP,
  top margin 162 DIP, 32 DIP between the two lines). On a short screen it steps the size down instead of
  overflowing.
- **The card is dimmed harder** than the rest: one dark layer over the whole screen, another over the card,
  so the card is always darker than its surroundings and the text stays legible.
- The wallpaper is only composited and painted *after* the screen has gone dark, so you never see it being
  drawn from top to bottom.
- The backdrop is your own wallpaper — the same picture anyone would see after unlocking, so it leaks
  nothing new. If you would rather not have it there, set a solid-colour desktop background and the
  program falls back to black.

**Lockout.** Eight wrong unlock passwords disable further input; the screen then says
"Password entry is disabled" plus "Power off using the physical power button, or press Ctrl+Alt+Del and
shut down from the security screen". Three wrong authorization codes do the same inside the change/rebuild
dialogs (inputs and the confirm button greyed out, only Quit/Cancel left), after showing a red warning
that advises you to consider a deliberate attack, change your Windows password, run an antivirus scan
and check the physical safety of your workspace.

**A wrong authorization code produces no feedback at all** — it does not confirm that the guess was wrong,
and it does not tell you how many attempts are left, so the dialog cannot be used as an oracle. The
lockout kicks in the moment the attempts run out.

**The two lockouts are not equally strong:**

| Raised in | After three wrong codes |
|---|---|
| "Change unlock password" (`Ctrl+Shift+Alt+E`) | this run only — restarting the program clears it |
| "Configuration needs to be rebuilt" (tampered config) | **permanent** — recorded in the registry and in `%APPDATA%`, survives closing the program and rebooting; only reinstalling clears it |

The second one treats "the config was touched *and* three codes did not work" as a deliberate attempt
rather than a typo, so it does not hand out a second chance.

**Sleep.** While locked the script holds `SetThreadExecutionState(ES_CONTINUOUS | ES_SYSTEM_REQUIRED)`,
which blocks *idle-triggered* sleep and hibernate. It deliberately omits `ES_DISPLAY_REQUIRED` (that
would fight the blanking). It does not block you explicitly choosing Sleep, and it does not touch your
power plan.

---

## 3. Password, authorization code, and tamper detection

| | Unlock password | Authorization code |
|---|---|---|
| Purpose | Everyday unlocking | **The only way back if you forget the password** |
| Length / characters | at least 4, ASCII letters/digits/symbols only | at least 6, same rule |
| Storage | PBKDF2-SHA1, 120 000 iterations, random salt — hash only | same |
| Changeable | yes (requires the authorization code) | **frozen at install time** |

The config file `.cascreenguard.config.json` (hidden, next to the script) carries an **HMAC-SHA256
marker** whose key lives in external credentials — the registry key `HKCU\Software\CAScreenGuard` and
`%APPDATA%\CAScreenGuard\store.json`. Delete or modify the config and the next start refuses to lock,
warns loudly, and asks for the authorization code before rebuilding.

**No password is ever stored in the program.** It is collected by the setup wizard, hashed, and written
to the config plus the external credentials. Neither the script, the C# sources nor the exe contain any
password literal.

---

## 4. Unexpected shutdown / crash detection

- Entering the lock writes a flag file `%LOCALAPPDATA%\CAScreenGuard\running.flag`; a clean unlock
  deletes it.
- If the next start finds the flag still there, the previous session did not end cleanly, and it tells
  you which of two things happened:
  - **a crash log exists** → the software itself failed; the log path is shown so you can report it
    (with reproduction steps). Logs live in `%LOCALAPPDATA%\CAScreenGuard\crash-*.log`, newest 10 kept;
  - **no crash log** → it did not crash: someone may have pressed the power button, signed out or shut
    down via `Ctrl+Alt+Del`, or simply killed the process. You are advised to change your Windows
    password, run a virus scan, check the physical safety of your workspace, and reinstall.
- There is also a running log at `%LOCALAPPDATA%\CAScreenGuard\guard.log`: startup/exit, sleep resume,
  failed wake-request re-issues and UI-thread exceptions, truncated automatically past 64 KB. It contains
  **no user name, machine name, path or PID**, so it is safe to send in for troubleshooting (only
  `crash-*.log` carries `user@machine` and the pid — that one is a local file, no need to send it).

---

## 5. Install / uninstall

Double-click `CAScreenGuard-Setup.exe`:

1. **Welcome page** — app icon, welcome title, author and license, a short introduction, an antivirus
   note, a link to this README, and the **interface language** selector (简体中文 / English).
2. **Install page** — install location (with a live "will install to …" preview) · unlock password ·
   authorization code · authorization hint · hotkey.

Notes:

- It installs into a dedicated sub-folder `<where you chose>\CAScreenGuard-<date>\`
  - that sub-folder already exists → installation is **refused**
  - already installed → **reinstalls in place** (the previous copy is removed first)
- Creates a desktop shortcut with a **global hotkey** `Ctrl + Alt + <letter/digit>` (stored in the
  shortcut's own "Shortcut key" field — no background process, no autostart entry)
- Registers an entry in "Apps & features" (publisher `Conste11ation117`); uninstalling removes the registry
  keys, the external credentials, the desktop shortcut and **the whole installation folder**
- **If the location you picked is not writable** (say `C:\Program Files`) the installer shows the complete
  reason (exception type and `HResult` included, selectable and copyable) and offers **"Retry as
  administrator"**: once you approve the Windows permission prompt (UAC), an elevation helper creates the
  folder and grants write access to your current account, and the installation continues. The password and
  authorization code never travel on the command line; the installed files are owned by you, so later
  config writes, logs and uninstalling need no elevation.
- Launched through `conhost --headless`, so **no console window flashes**
- The language you pick is written into the external credentials, and the installed program follows it

### Antivirus

Measured: **360 shows a prompt but does not classify it as a virus; Windows Defender passes it
completely**. If you trust this software, add it to your antivirus whitelist — otherwise the installer
or the program may be blocked. The welcome page says the same thing.

---

## 6. Language

Both Chinese and English UI text ship inside the program.

- Chosen at install time, remembered in the external credentials
- Otherwise follows your Windows display language
- Force it for one run: `CAScreenGuard.ps1 -Lang zh` or `-Lang en`

---

## 7. Files

### The four files the program needs at runtime (same folder)

`CAScreenGuard.ps1` · `ScreenLockEarly.cs` · `ScreenLockNative.cs` · `CAScreenGuard.ico`

The script loads both `.cs` files at startup with `Add-Type -Path`; if one is missing it shows an
"incomplete files" message and exits — **do not copy the `.ps1` on its own**.

### Repository layout

| File | Notes |
|---|---|
| `CAScreenGuard-demo.ps1` | **The source** (commented) — this is what you edit |
| `CAScreenGuard.ps1` | **Generated**: same script with comments and blank lines stripped |
| `ScreenLockEarly.cs`, `ScreenLockNative.cs` | C# sources (commented) |
| `make-icon.ps1` | Regenerates the icon |
| `build-setup.ps1` | Build: strip comments → embed → compile a single-file exe |
| `Installer.cs` | Installer source (welcome page, wizard, install/uninstall, bilingual strings) |
| `CAScreenGuard.ico` | Icon |
| `CAScreenGuard-Setup.exe` | Build output — double-click to install |
| `docs/` | Screenshots used by this README |

> `CAScreenGuard.ps1` is **generated — do not edit it**; edit `CAScreenGuard-demo.ps1` instead.

---

## 8. Building and self-test

```powershell
powershell -File build-setup.ps1
```

One command:

1. strips every comment and blank line from `CAScreenGuard-demo.ps1` using the PowerShell **syntax tree**
   (so `#` inside strings survives), keeps `#Requires`, and writes `CAScreenGuard.ps1`
2. strips comments from both `.cs` files **and compiles them to prove nothing broke**
3. normalises BOM and line endings of all sources (editors like to eat the BOM, which turns Chinese
   text into mojibake)
4. embeds the four files into the installer and compiles `CAScreenGuard-Setup.exe`

Self-test (never touches monitor power):

```powershell
powershell -File CAScreenGuard.ps1 -SelfTest
```

Eight checks: config read/write, wrong password rejected, integrity verdicts (ok / modified / deleted),
mask size, UI construction, idle-time API, wrong-password handling, successful unlock.

| Parameter | Meaning |
|---|---|
| `-ResetPassword` | Open "Change unlock password" right away (needs the authorization code; skips blanking) |
| `-IdleBlankSeconds <5..600>` | Idle timeout before blanking again, default 25 |
| `-Lang auto\|zh\|en` | Force the UI language |
| `-Ver` | Print the version and author, then exit (nothing is blanked) |
| `-SelfTest` | Self-test, does not blank the screen |

---

## 9. Honest note on "cracking"

There is no secret in the script to crack. The unlock password is only stored as a PBKDF2 hash; the
marker key lives in the registry / `%APPDATA%` credentials. Reading the script gives you neither the
password nor a key that bypasses the check.

Stripping comments, obfuscating, or shipping an exe does **not** make it safer: a dropped `.ps1` is still
on disk, and .NET IL decompiles more easily than reading the script. The root cause is that **anyone who
can modify the program can bypass it** — swap the script for one that skips the password check, or just
kill the process. No user-mode screen cover escapes that.

What actually raises the bar: tighten the ACL of the install folder, never write the password on a sticky
note or in the hint, use `Win+L` + BitLocker when you really need secrecy, and use a managed account.

---

## 10. Known limits

- If someone wipes **both** the registry key and the `%APPDATA%` credentials, the machine degrades to
  "never installed" — the program then refuses to lock and asks you to reinstall (fail-safe, but the old
  configuration is gone)
- Every input box disables the IME; passwords and codes are ASCII-only
- The mask covers the whole virtual desktop (all monitors)
- The system is kept awake while locked, which drains a laptop battery
- `Ctrl+Alt+Del` is **not** an opening: nothing on that screen reveals the desktop (see §2)
- Not covered: someone who can modify the program files, or end the process by other means (another
  account, the disk mounted elsewhere) — the flag file only reports it afterwards
