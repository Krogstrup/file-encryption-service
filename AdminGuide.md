# IT Admin Guide: Deploy 7-Zip SendTo Encryption

## Prerequisites
- Windows Enterprise endpoints.
- 7-Zip installed on endpoints (recommended `C:\Program Files\7-Zip\7z.exe`).
- PowerShell 5.1+ available (built-in on Windows 10+). 

## Files included
- `EncryptFile.ps1` : core encryptor logic
- `EncryptWith7Zip.cmd` : SendTo wrapper
- `UserGuide.md`, `SecurityNotes.md` : documentation

## Deployment locations
- `shell:sendto` path for current user: `%APPDATA%\Microsoft\Windows\SendTo`
- For all users, deploy via GPO/Intune script into each user profile’s SendTo folder.

### Example PowerShell deploy script
```powershell
$sendTo = Join-Path $env:APPDATA 'Microsoft\Windows\SendTo'
Copy-Item -Path 'C:\Deploy\EncryptWith7Zip.cmd' -Destination $sendTo -Force
Copy-Item -Path 'C:\Deploy\EncryptFile.ps1' -Destination $sendTo -Force
```

## 7-Zip path resolution
Script checks:
1. `%ProgramFiles%\7-Zip\7z.exe`
2. `%ProgramFiles(x86)%\7-Zip\7z.exe`
3. `7z.exe` in PATH

If installed elsewhere, create a PATH entry or adjust script.

## GPO/Intune script sample (Machine context)
- Ensure 7-Zip installation is part of baseline image or package.
- Deploy files to `C:\ProgramData\SendTo` and then create per-user symlink to it if needed.

## Permissions
- Script runs as user with file access to source file and destination folder.
- No elevated privileges required for encryption currently.

## Logging / troubleshooting
- Script outputs to console and returns non-zero exit codes for error conditions.
- For remote troubleshooting, collect the user’s console output or run in admin PowerShell with `-Verbose`.
