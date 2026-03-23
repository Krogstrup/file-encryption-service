# file-encryption-service

A lightweight Windows utility that lets any user encrypt files using strong AES-256 encryption directly from the right-click Send To menu in File Explorer — no command-line knowledge required. The user selects a file, chooses a password, and receives a protected `.7z` archive in the same folder. Intended for encrypting sensitive files before sharing them over email, USB, or cloud storage.

---

## Architecture overview

```
File Explorer (right-click > Send To)
        │
        ▼
EncryptWith7Zip.cmd          ← thin CMD wrapper; lives in %APPDATA%\...\SendTo
        │  passes file path(s) as arguments
        ▼
EncryptFile.ps1              ← PowerShell script; validates paths, collects password
        │  spawns subprocess
        ▼
7z.exe (7-Zip CLI)           ← performs AES-256 encryption with header encryption
        │  writes output
        ▼
<original folder>/<filename>.7z
```

No services, no background processes, no registry entries. Everything runs in the user's own session with their own file permissions.

---

## Prerequisites

| Requirement | Details |
|---|---|
| OS | Windows 10 or Windows 11 (64-bit) |
| PowerShell | 5.1+ (built-in on Windows 10+) |
| 7-Zip | 19.00 or later, installed at `%ProgramFiles%\7-Zip\7z.exe` or on PATH |
| Permissions | Standard user — no elevation required |

---

## Setup instructions

### For end users (single machine)

1. Install 7-Zip from <https://www.7-zip.org> if not already present.
2. Open the SendTo folder: press `Win + R`, type `shell:sendto`, press Enter.
3. Copy `EncryptWith7Zip.cmd` into that folder.
4. Copy `EncryptFile.ps1` into the **same folder** as `EncryptWith7Zip.cmd` (the SendTo folder).
5. Test by right-clicking any file and choosing `Send to > EncryptWith7Zip`.

### For IT / mass deployment via PowerShell

```powershell
$sendTo = Join-Path $env:APPDATA 'Microsoft\Windows\SendTo'
Copy-Item -Path '\\server\share\EncryptWith7Zip.cmd' -Destination $sendTo -Force
Copy-Item -Path '\\server\share\EncryptFile.ps1'    -Destination $sendTo -Force
```

Run this as the target user (not as SYSTEM) so it lands in the correct profile.

---

## Configuration reference

There are no configuration files or environment variables. All behaviour is controlled by constants in `EncryptFile.ps1`:

| Location | Setting | Default | Effect |
|---|---|---|---|
| `EncryptFile.ps1` line ~125 | 7-Zip compression level `-mx=9` | 9 (Ultra) | Lower values (1–5) trade size for speed |
| `EncryptFile.ps1` line ~125 | Header encryption `-mhe=on` | on | Hides filenames inside the archive |
| `EncryptFile.ps1` line ~125 | Multithreading `-mmt=on` | on | Uses all CPU cores |
| `EncryptFile.ps1` line ~17 | 7-Zip search paths | `%ProgramFiles%`, `%ProgramFiles(x86)%`, PATH | Extend the `$candidates` array if 7-Zip is installed elsewhere |

---

## Operational procedures

**Encrypt a file**
Right-click file in Explorer → Send to → EncryptWith7Zip → enter and confirm password → `.7z` appears in the same folder.

**Encrypt multiple files at once**
Select multiple files, right-click any of them → Send to → EncryptWith7Zip. Each file produces its own `.7z` archive.

**If output archive name already exists**
The script automatically appends `(1)`, `(2)`, etc. rather than overwriting.

**Verify the archive**
Open 7-Zip File Manager, locate the `.7z` file, press `T` (Test) and enter the password. A clean test means the archive is intact.

**Remove the Send To entry**
Delete `EncryptWith7Zip.cmd` (and optionally `EncryptFile.ps1`) from `shell:sendto`.

**Update to a new version**
Overwrite both `.cmd` and `.ps1` files in `shell:sendto` with the new versions.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `7-Zip not found` | 7-Zip not installed or not on PATH | Install 7-Zip to `%ProgramFiles%\7-Zip` or add it to the system PATH |
| `No valid files selected` | Only folders were passed (folders are not supported) | Select individual files, not directories |
| `Passwords do not match` | Typo during confirmation | Re-run and type both passwords carefully |
| `Failed to encrypt … (7z exit 2)` | Invalid 7-Zip arguments or corrupt archive path | Check for unusual characters in the file path; verify 7-Zip version is 19+ |
| Nothing happens when using Send To | `EncryptFile.ps1` is missing from the same folder as the `.cmd` | Ensure both files are in the same directory |
| Window appears and closes instantly | PowerShell execution policy blocks the script | Ask IT to set `ExecutionPolicy Bypass` or re-deploy via the provided CMD wrapper which already passes `-ExecutionPolicy Bypass` |
| Archive created but cannot open it | Wrong password entered at decrypt time | Passwords are not recoverable; the file must be re-encrypted with a known password |

---

## Backup and restore

This utility does not maintain any state, databases, or configuration files to back up.

**What to back up:** the source files `EncryptFile.ps1` and `EncryptWith7Zip.cmd` from this repository. The SendTo shortcuts are user-profile data and are typically covered by roaming profile or OneDrive backup if enabled.

**Restore after OS reinstall:**
1. Re-install 7-Zip.
2. Repeat the [setup instructions](#setup-instructions) above.

---

## Known limitations

- **No folder support** — only individual files can be selected. Select all files inside a folder manually, or zip the folder first.
- **Password is briefly visible in process arguments** — the 7-Zip CLI receives the password via the `-p` flag, which can appear in process-listing tools (e.g. Process Explorer) for the duration of the 7-Zip process. See [SecurityNotes.md](SecurityNotes.md) for details.
- **No key escrow** — if the password is lost, the encrypted file cannot be recovered.
- **Windows only** — the `.cmd` wrapper and SendTo integration are Windows-specific. The `EncryptFile.ps1` script can be run on PowerShell 7 on other platforms but without a Send To equivalent.
- **Single-file output per input file** — there is no option to combine multiple selected files into one archive.
