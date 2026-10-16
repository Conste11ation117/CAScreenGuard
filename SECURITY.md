# Security Policy

## What this project is (and is not)

Meta-positioning：Keep long-running workflows going while the PC is unattended, and protect your ongoing work and private files from any /undetectable peeking, theft, or tampering.

CAScreenGuard is a **visual privacy barrier for an unattended screen**. It is *not* a security boundary.

It *does*:

- keep the unlock password and the authorization code as PBKDF2-SHA1 hashes (120 000 iterations, random salt)
- keep the marker key used for tamper detection in external credentials (registry + `%APPDATA%`), never in the config file
- detect a deleted or modified config file and refuse to lock until the authorization code is supplied
- swallow `Win`, `Alt+Tab`, `Alt+Esc` and `Ctrl+Esc` while locked

It deliberately does *not*:

- lock the Windows session, encrypt the disk, hide running processes, or block network access
- intercept `Ctrl+Alt+Del` — and it does not need to: nothing on that screen exposes the desktop.
  Sign-out and shutdown end the session (or reboot), so it is never revealed and the flag file records
  it; Task Manager does start, but the mask re-asserts itself on top every 250 ms and takes focus back
- protect against anyone who can modify the program files, or end the process by other means (another
  account, the disk mounted elsewhere). **Any user-mode screen cover works this way.** The flag file
  tells you afterwards.

If you need real confidentiality, use Windows lock (`Win+L`) together with BitLocker, and do not rely on
a screen-covering tool.

## Supported versions

Only the latest release is supported.

| Version | Supported |
|---|---|
| 1.0.x | yes |

## Storage locations (for auditing)

| What | Where |
|---|---|
| Config (hidden, HMAC-marked) | `<install dir>\.cascreenguard.config.json` |
| External credentials | `HKCU\Software\CAScreenGuard` and `%APPDATA%\CAScreenGuard\store.json` |
| Program files | `<chosen location>\CAScreenGuard-<date>\` |
| Desktop shortcut | `%USERPROFILE%\Desktop\CAScreenGuard.lnk` |
| Uninstall entry | `HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\CAScreenGuard` |

No password, authorization code or hint is ever stored in plain text. The only plain-text secret is the
authorization **hint** you type yourself — do not put the code itself there.

## Reporting a vulnerability

Please open a **private security advisory** on GitHub
(Security → Advisories → "Report a vulnerability") rather than a public issue.

Helpful details:

- what you did, what happened, and what you expected
- the affected version (see `CHANGELOG.md`) and your Windows build
- whether the machine had an existing installation

Please **do not include real passwords or authorization codes** in a report — reproduce with throwaway
values instead.

There is no bug bounty. Credit will be given in the changelog unless you prefer otherwise.
