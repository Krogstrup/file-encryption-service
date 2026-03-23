# End-User Guide: Encrypt files with 7-Zip (SendTo)

## Goal
Quickly create a secure `.7z` file with password protection from any file using right-click > Send to.

## Steps for users
1. Install 7-Zip if not already installed (ask IT). Use the 64-bit installer from https://www.7-zip.org.
2. Open `shell:sendto` (Windows + R, type `shell:sendto`, press Enter).
3. Copy `EncryptWith7Zip.cmd` into that folder (IT can deploy via script).
4. In File Explorer, right-click the file to encrypt.
5. Choose `Send to > EncryptWith7Zip` from the menu.
6. Enter the password when prompted, then confirm it.
7. Wait for the `Encryption complete` message.
8. Find the output `.7z` archive in the same folder as the original file.

## Notes
- The resulting archive uses AES-256 and hides filenames.
- Keep the password safe and share it only through a secure separate channel (not email).
- Do not delete the original file until you confirm the archive works.

## Troubleshooting
- If message says `7-Zip not found`, ensure 7z is installed.
- If operation fails, call IT and provide the error shown in the popup/console.
