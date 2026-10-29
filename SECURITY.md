# Security Policy

## What this project is (and is not)

Meta-positioning: keep long-running workflows going while the PC is unattended, and protect your
ongoing work and private files from any undetectable peeking, theft, or tampering.

CAScreenGuard is a visual privacy barrier for an unattended screen. It is not a security boundary.

It does:

- store the unlock password and the authorization code only as PBKDF2-SHA1 hashes (120 000 iterations,
  random salt)
- keep the marker key used for tamper detection outside the configuration file, in external credentials
  (registry plus `%APPDATA%`)
- detect a deleted or modified configuration file and refuse to lock until the authorization code is
  supplied
- swallow `Win`, `Alt+Tab`, `Alt+Esc` and `Ctrl+Esc` while locked

It deliberately does not:

- record anything you type. The keyboard hook (`WH_KEYBOARD_LL`) reads only the virtual-key code to decide
  whether to swallow one of those four shortcuts. Nothing is stored, logged or transmitted.
- talk to the network. There is no HTTP client, socket, telemetry or update check in the PowerShell script,
  the C# sources or the installer; the program works entirely offline.
- lock the Windows session, encrypt the disk, hide running processes or block network access
- intercept `Ctrl+Alt+Del`, and it does not need to: nothing on that screen exposes the desktop. Sign-out
  and shutdown end the session (or reboot), so it is never revealed and the flag file records it; Task
  Manager does start, but the mask re-asserts itself on top every 250 ms and takes focus back.
- protect against anyone who can modify the program files, or end the process by other means (another
  account, the disk mounted elsewhere). Any user-mode screen cover works this way. The flag file tells you
  afterwards.

The optional agent-status chip reads a local JSON file written by a separate plugin. It carries state only
(`working` / `waiting`) plus a timestamp — never prompt text, replies, project names or file names. The
program shows nothing at all when that file is absent, unreadable or older than ten minutes.

For real confidentiality use the Windows lock (`Win+L`) together with BitLocker, and do not rely on a
screen-covering tool.

## Supported versions

Only the latest release is supported.

| Version | Supported |
|---|---|
| 3.x | yes |
| older | no |

## Storage locations (for auditing)

| What | Where |
|---|---|
| Config (hidden, HMAC-marked) | `<install dir>\.cascreenguard.config.json` |
| External credentials | `HKCU\Software\CAScreenGuard` and `%APPDATA%\CAScreenGuard\store.json` |
| Program files | `<chosen location>\CAScreenGuard-<date>\` |
| Upgrade backup | `<install dir>\backup-<timestamp>\` |
| Desktop shortcut | `%USERPROFILE%\Desktop\CAScreenGuard.lnk` |
| Uninstall entry | `HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\CAScreenGuard` |
| Runtime state (flag, logs, agent status) | `%LOCALAPPDATA%\CAScreenGuard\` |

No password, authorization code or hint is stored in plain text. The one exception is the authorization
**hint**, which is plain text because you write it yourself — do not put the code itself in it.

`guard.log` is deliberately free of user name, machine name, paths and PIDs so that it can be attached to
a bug report. `crash-*.log` does contain `user@machine` and the PID: it is a local file, review it before
sharing.

## Reporting a vulnerability

Open a private security advisory on GitHub (Security → Advisories → "Report a vulnerability") rather than
a public issue.

Helpful details:

- what you did, what happened, what you expected
- the affected version (see `CHANGELOG.md`) and your Windows build
- whether the machine had an existing installation

Do not include real passwords or authorization codes in a report; reproduce with throwaway values.

There is no bug bounty. Credit is given in the changelog unless you prefer not to be named.
