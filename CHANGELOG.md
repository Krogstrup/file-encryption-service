# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-03-23

### Added
- `EncryptFile.ps1`: core PowerShell encryptor using 7-Zip AES-256 with header encryption (`-mhe=on`)
- `EncryptWith7Zip.cmd`: SendTo wrapper that invokes the PowerShell script
- Password confirmation prompt to reduce misencryption
- Automatic output filename collision handling (`filename (1).7z`, etc.)
- Folder-input guard with warning instead of silent failure
- `UserGuide.md`: end-user instructions for Send To setup and usage
- `AdminGuide.md`: IT deployment guide including GPO/Intune sample
- `SecurityNotes.md`: password handling notes and known CLI limitations

### Fixed
- `Split-Path -LeafBase` replaced with `[System.IO.Path]::GetFileNameWithoutExtension()` for compatibility with Windows PowerShell 5.1
- Removed invalid `-mcu` flag (ZIP-only) from 7-Zip arguments to resolve exit code 2
- Added path quoting in 7-Zip argument list to handle paths with spaces
- Escaped parentheses in CMD error echo to prevent batch syntax crash
