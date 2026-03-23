# Security Notes for 7-Zip SendTo Encryption

## Password handling
- Password is collected by PowerShell `Read-Host -AsSecureString`.
- Password is converted to plain text only briefly for 7-Zip call then cleared.
- No passwords are stored in script files.

## Limitations
- 7-Zip command line has no native password pipe; the chosen approach uses `-p` parameter, which could briefly appear in process command-line. This is a known limitation of CLI mode.
- For stronger process-level protection, use full GUI or a dedicated credential provider.

## User guidance
- Use strong passwords (min 12 chars, mix of char classes).
- Never share password in same channel as file.
- Destroy plain text copies and use ephemeral secret channels (Teams private chat or secure password manager).

## Operational stability
- Non-technical users: the SendTo path plus one prompt lowers misuse.
- If archiving fails, verify file permissions and disk space.

## Best practices
- Rotate passwords per file/project.
- Do not rely on this as long-term key management.
- Consider integration with enterprise key escrow if needed.
