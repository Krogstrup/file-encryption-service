<#
.SYNOPSIS
  Encrypt files using 7-Zip AES-256 with encrypted filenames.
.DESCRIPTION
  Designed for SendTo right-click usage. Prompts user for password securely.
  Copies 7z output into same directory for each selected file.
.PARAMETER FilePaths
  One or more full file paths passed from SendTo.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)]
    [string[]]$FilePaths
)

function Get-7ZipPath {
    # Prefer explicit install locations, then PATH lookup.
    $candidates = @(
        "$env:ProgramFiles\7-Zip\7z.exe",
        "$env:ProgramFiles(x86)\7-Zip\7z.exe"
    )

    foreach ($path in $candidates) {
        if (Test-Path $path) { return (Resolve-Path $path).Path }
    }

    $which = Get-Command 7z.exe -ErrorAction SilentlyContinue
    if ($which) { return $which.Path }

    return $null
}

function Validate-FilePaths {
    param([string[]]$Paths)

    if (-not $Paths) {
        throw "No files were selected. Please rerun from SendTo with at least one file."
    }

    $existingPaths = @()
    foreach ($p in $Paths) {
        if (-not (Test-Path -LiteralPath $p)) {
            Write-Warning "Skipping: '$p' does not exist."
            continue
        }
        if ((Get-Item -LiteralPath $p).PSIsContainer) {
            Write-Warning "Skipping folder: '$p' (only files are supported)."
            continue
        }
        $existingPaths += $p
    }

    return $existingPaths
}

function SecureRead-Password {
    [CmdletBinding()]
    param(
        [string]$Prompt = "Enter password:"
    )

    $securePassword = Read-Host -AsSecureString -Prompt $Prompt
    if (($securePassword.Length) -eq 0) {
        throw "Password cannot be empty."
    }

    return $securePassword
}

function Convert-SecureStringToPlainText {
    param([System.Security.SecureString]$SecureString)

    if (-not $SecureString) { return $null }
    $passwordPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    try {
        return [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPtr)
    }
    finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPtr)
    }
}

# Entry
try {
    $sevenZipExe = Get-7ZipPath
    if (-not $sevenZipExe) {
        Write-Error "7-Zip not found. Install 7-Zip, or add it to PATH."
        exit 2
    }

    $selectedFiles = Validate-FilePaths -Paths $FilePaths
    if (-not $selectedFiles) {
        Write-Error "No valid files selected."
        exit 1
    }

    # Ask once for password, confirm once to reduce mistakes.
    $pw1 = SecureRead-Password -Prompt "Enter encryption password"
    $pw2 = SecureRead-Password -Prompt "Confirm password"

    $plain1 = Convert-SecureStringToPlainText $pw1
    $plain2 = Convert-SecureStringToPlainText $pw2

    if ($plain1 -ne $plain2) {
        throw "Passwords do not match. Please try again."
    }

    Write-Host "Encrypting $($selectedFiles.Count) file(s) with AES-256, hidden filenames..." -ForegroundColor Cyan

    foreach ($filePath in $selectedFiles) {
        $dir = Split-Path -Parent $filePath
        $name = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
        $outArchive = Join-Path -Path $dir -ChildPath "$name.7z"

        # If destination already exists, create <name> (1).7z to avoid overwrite by default
        if (Test-Path -LiteralPath $outArchive) {
            $index = 1
            do {
                $outArchive = Join-Path -Path $dir -ChildPath "$name ($index).7z"
                $index++
            } while (Test-Path -LiteralPath $outArchive)
        }

        $arguments = @( 'a', '-t7z', '-mx=9', '-mhe=on', "-p$plain1", "-mmt=on", "`"$outArchive`"", "`"$filePath`"" )

        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = $sevenZipExe
        $processInfo.Arguments = $arguments -join ' '
        $processInfo.UseShellExecute = $false
        $processInfo.RedirectStandardOutput = $true
        $processInfo.RedirectStandardError = $true
        $processInfo.CreateNoWindow = $true

        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = $processInfo
        $p.Start() | Out-Null
        $stdout = $p.StandardOutput.ReadToEnd()
        $stderr = $p.StandardError.ReadToEnd()
        $p.WaitForExit()

        if ($p.ExitCode -ne 0) {
            Write-Warning "Failed to encrypt '$filePath' (7z exit $($p.ExitCode))."
            if ($stdout) { Write-Host $stdout }
            if ($stderr) { Write-Host $stderr }
            continue
        }

        Write-Host "Encrypted: $filePath -> $outArchive" -ForegroundColor Green
    }

    Write-Host "Done. Please review output files above." -ForegroundColor Green
}
catch {
    Write-Error "Error: $($_.Exception.Message)"
    exit 10
}
finally {
    # Clear password from memory
    if ($plain1) { $plain1 = "" }
    if ($plain2) { $plain2 = "" }
    if ($pw1) { $pw1.Dispose() }
    if ($pw2) { $pw2.Dispose() }
}
