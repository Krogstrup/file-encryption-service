<#
.SYNOPSIS
  Encrypt files using 7-Zip AES-256 — graphical Windows Forms interface.
.DESCRIPTION
  Designed for SendTo right-click usage. Shows a dialog for password entry
  and displays per-file progress and status.
.PARAMETER FilePaths
  One or more full file paths passed from SendTo.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
    [string[]]$FilePaths
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ── Core helpers ──────────────────────────────────────────────────────────────

function Get-7ZipPath {
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

function Test-FilePath {
    param([string[]]$Paths)
    $valid   = [System.Collections.Generic.List[string]]::new()
    $skipped = [System.Collections.Generic.List[string]]::new()
    foreach ($p in $Paths) {
        if (-not (Test-Path -LiteralPath $p)) {
            $skipped.Add("$p (does not exist)")
            continue
        }
        if ((Get-Item -LiteralPath $p).PSIsContainer) {
            $skipped.Add("$p (folders not supported)")
            continue
        }
        $valid.Add($p)
    }
    return $valid, $skipped
}

# ── Palette & fonts ───────────────────────────────────────────────────────────

$clrAccent = [System.Drawing.Color]::FromArgb(0, 120, 212)
$clrHover  = [System.Drawing.Color]::FromArgb(0, 100, 180)
$clrBg     = [System.Drawing.Color]::White
$clrText   = [System.Drawing.Color]::FromArgb(32, 32, 32)
$clrSubtle = [System.Drawing.Color]::FromArgb(110, 110, 110)
$clrOk     = [System.Drawing.Color]::FromArgb(16, 124, 16)
$clrErr    = [System.Drawing.Color]::FromArgb(196, 43, 28)
$clrWarn   = [System.Drawing.Color]::FromArgb(154, 85, 0)
$clrPanel  = [System.Drawing.Color]::FromArgb(248, 249, 251)

$fntMain   = New-Object System.Drawing.Font('Segoe UI', 9)
$fntSmall  = New-Object System.Drawing.Font('Segoe UI', 8.25)
$fntLabel  = New-Object System.Drawing.Font('Segoe UI', 7.5, [System.Drawing.FontStyle]::Bold)
$fntHeader = New-Object System.Drawing.Font('Segoe UI', 13)

# ── Form ──────────────────────────────────────────────────────────────────────

$form                 = New-Object System.Windows.Forms.Form
$form.Text            = 'File Encryption'
$form.ClientSize      = New-Object System.Drawing.Size(460, 520)
$form.MinimumSize     = New-Object System.Drawing.Size(460, 520)
$form.MaximumSize     = New-Object System.Drawing.Size(460, 520)
$form.StartPosition   = 'CenterScreen'
$form.BackColor       = $clrBg
$form.Font            = $fntMain
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox     = $false
$form.KeyPreview      = $true

# Header
$pnlHeader           = New-Object System.Windows.Forms.Panel
$pnlHeader.Dock      = 'Top'
$pnlHeader.Height    = 64
$pnlHeader.BackColor = $clrAccent
$form.Controls.Add($pnlHeader)

$lblTitle           = New-Object System.Windows.Forms.Label
$lblTitle.Text      = 'File Encryption'
$lblTitle.Font      = $fntHeader
$lblTitle.ForeColor = [System.Drawing.Color]::White
$lblTitle.AutoSize  = $true
$lblTitle.Location  = New-Object System.Drawing.Point(20, 11)
$pnlHeader.Controls.Add($lblTitle)

$lblSub           = New-Object System.Windows.Forms.Label
$lblSub.Text      = 'AES-256  ·  Hidden filenames  ·  Powered by 7-Zip'
$lblSub.Font      = New-Object System.Drawing.Font('Segoe UI', 8)
$lblSub.ForeColor = [System.Drawing.Color]::FromArgb(195, 225, 255)
$lblSub.AutoSize  = $true
$lblSub.Location  = New-Object System.Drawing.Point(22, 40)
$pnlHeader.Controls.Add($lblSub)

# Content panel
$pnl           = New-Object System.Windows.Forms.Panel
$pnl.Location  = New-Object System.Drawing.Point(0, 64)
$pnl.Size      = New-Object System.Drawing.Size(460, 456)
$pnl.BackColor = $clrBg
$form.Controls.Add($pnl)

# Helper: section caption
function New-Caption([string]$text, [int]$x, [int]$y) {
    $l           = New-Object System.Windows.Forms.Label
    $l.Text      = $text
    $l.Font      = $fntLabel
    $l.ForeColor = $clrSubtle
    $l.AutoSize  = $true
    $l.Location  = New-Object System.Drawing.Point($x, $y)
    return $l
}

# ── Section: files ────────────────────────────────────────────────────────────

$pnl.Controls.Add((New-Caption 'FILES TO ENCRYPT' 20 14))

$lstFiles               = New-Object System.Windows.Forms.ListBox
$lstFiles.Location      = New-Object System.Drawing.Point(20, 34)
$lstFiles.Size          = New-Object System.Drawing.Size(420, 82)
$lstFiles.Font          = $fntSmall
$lstFiles.BorderStyle   = 'FixedSingle'
$lstFiles.BackColor     = $clrPanel
$lstFiles.SelectionMode = 'None'
$pnl.Controls.Add($lstFiles)

# ── Section: password ─────────────────────────────────────────────────────────

$pnl.Controls.Add((New-Caption 'PASSWORD' 20 128))

$txtPw              = New-Object System.Windows.Forms.TextBox
$txtPw.Location     = New-Object System.Drawing.Point(20, 148)
$txtPw.Size         = New-Object System.Drawing.Size(420, 24)
$txtPw.PasswordChar = [char]0x25CF
$txtPw.BorderStyle  = 'FixedSingle'
$pnl.Controls.Add($txtPw)

$txtCfm              = New-Object System.Windows.Forms.TextBox
$txtCfm.Location     = New-Object System.Drawing.Point(20, 180)
$txtCfm.Size         = New-Object System.Drawing.Size(420, 24)
$txtCfm.PasswordChar = [char]0x25CF
$txtCfm.BorderStyle  = 'FixedSingle'
$pnl.Controls.Add($txtCfm)

$lblMatch           = New-Object System.Windows.Forms.Label
$lblMatch.Location  = New-Object System.Drawing.Point(20, 211)
$lblMatch.AutoSize  = $true
$lblMatch.Font      = $fntSmall
$lblMatch.ForeColor = $clrSubtle
$lblMatch.Text      = ''
$pnl.Controls.Add($lblMatch)

# ── Progress bar ──────────────────────────────────────────────────────────────

$bar          = New-Object System.Windows.Forms.ProgressBar
$bar.Location = New-Object System.Drawing.Point(20, 237)
$bar.Size     = New-Object System.Drawing.Size(420, 6)
$bar.Style    = 'Continuous'
$bar.Visible  = $false
$pnl.Controls.Add($bar)

# ── Section: status log ───────────────────────────────────────────────────────

$pnl.Controls.Add((New-Caption 'STATUS' 20 252))

$rtb             = New-Object System.Windows.Forms.RichTextBox
$rtb.Location    = New-Object System.Drawing.Point(20, 272)
$rtb.Size        = New-Object System.Drawing.Size(420, 110)
$rtb.ReadOnly    = $true
$rtb.BackColor   = $clrPanel
$rtb.BorderStyle = 'FixedSingle'
$rtb.Font        = $fntSmall
$rtb.ScrollBars  = 'Vertical'
$pnl.Controls.Add($rtb)

# ── Buttons ───────────────────────────────────────────────────────────────────

$btnCancel                            = New-Object System.Windows.Forms.Button
$btnCancel.Text                       = 'Cancel'
$btnCancel.Size                       = New-Object System.Drawing.Size(96, 32)
$btnCancel.Location                   = New-Object System.Drawing.Point(228, 398)
$btnCancel.FlatStyle                  = 'Flat'
$btnCancel.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
$btnCancel.BackColor                  = $clrBg
$btnCancel.ForeColor                  = $clrText
$pnl.Controls.Add($btnCancel)

$btnEncrypt                          = New-Object System.Windows.Forms.Button
$btnEncrypt.Text                     = 'Encrypt'
$btnEncrypt.Size                     = New-Object System.Drawing.Size(116, 32)
$btnEncrypt.Location                 = New-Object System.Drawing.Point(334, 398)
$btnEncrypt.FlatStyle                = 'Flat'
$btnEncrypt.FlatAppearance.BorderSize = 0
$btnEncrypt.BackColor                = $clrAccent
$btnEncrypt.ForeColor                = [System.Drawing.Color]::White
$pnl.Controls.Add($btnEncrypt)

# ── Log helper ────────────────────────────────────────────────────────────────

function Write-Log {
    param([string]$Message, [string]$Level = 'Info')
    $col = switch ($Level) {
        'Success' { $clrOk }
        'Error'   { $clrErr }
        'Warning' { $clrWarn }
        default   { $clrText }
    }
    $rtb.SelectionStart  = $rtb.TextLength
    $rtb.SelectionLength = 0
    $rtb.SelectionColor  = $col
    $rtb.AppendText("$Message`n")
    $rtb.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

# ── Encryption ────────────────────────────────────────────────────────────────

function Invoke-Encryption {
    $sevenZip = Get-7ZipPath
    if (-not $sevenZip) {
        Write-Log '7-Zip not found. Install it or add to PATH.' 'Error'
        return
    }

    $pw  = $txtPw.Text
    $cfm = $txtCfm.Text

    if ([string]::IsNullOrEmpty($pw)) { Write-Log 'Password cannot be empty.' 'Error'; return }
    if ($pw -ne $cfm)                 { Write-Log 'Passwords do not match.'    'Error'; return }

    $btnEncrypt.Enabled = $false
    $txtPw.Enabled      = $false
    $txtCfm.Enabled     = $false
    $bar.Visible        = $true
    $bar.Maximum        = $script:validFiles.Count
    $bar.Value          = 0
    $allOk              = $true

    $i = 0
    foreach ($filePath in $script:validFiles) {
        $i++
        $dir  = Split-Path -Parent $filePath
        $base = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
        $out  = Join-Path $dir "$base.7z"

        if (Test-Path -LiteralPath $out) {
            $n = 1
            do { $out = Join-Path $dir "$base ($n).7z"; $n++ } while (Test-Path -LiteralPath $out)
        }

        Write-Log "Encrypting: $(Split-Path -Leaf $filePath) ..." 'Info'

        $zipArgs = @('a', '-t7z', '-mx=9', '-mhe=on', "-p$pw", '-mmt=on', "`"$out`"", "`"$filePath`"")
        $psi                      = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName             = $sevenZip
        $psi.Arguments            = $zipArgs -join ' '
        $psi.UseShellExecute      = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError  = $true
        $psi.CreateNoWindow       = $true

        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo = $psi
        $proc.Start() | Out-Null
        $proc.StandardOutput.ReadToEnd() | Out-Null
        $stderr = $proc.StandardError.ReadToEnd()
        $proc.WaitForExit()

        if ($proc.ExitCode -ne 0) {
            Write-Log "Failed: $(Split-Path -Leaf $filePath) (exit $($proc.ExitCode))" 'Error'
            if ($stderr) { Write-Log $stderr.Trim() 'Error' }
            $allOk = $false
        } else {
            Write-Log "Done: $(Split-Path -Leaf $filePath) → $(Split-Path -Leaf $out)" 'Success'
        }

        $bar.Value = $i
        [System.Windows.Forms.Application]::DoEvents()
    }

    # Clear password from memory
    $pw = $null; $cfm = $null
    $txtPw.Text = ''; $txtCfm.Text = ''

    if ($allOk) {
        Write-Log 'All files encrypted successfully.' 'Success'
        $btnCancel.Text = 'Close'
    } else {
        Write-Log 'Some files failed — see above.' 'Warning'
        $btnEncrypt.Text    = 'Retry'
        $btnEncrypt.Enabled = $true
        $txtPw.Enabled      = $true
        $txtCfm.Enabled     = $true
    }
}

# ── Event handlers ────────────────────────────────────────────────────────────

$txtCfm.Add_TextChanged({
    if ($txtPw.TextLength -eq 0) { $lblMatch.Text = ''; return }
    if ($txtCfm.Text -eq $txtPw.Text) {
        $lblMatch.ForeColor = $clrOk
        $lblMatch.Text      = 'Passwords match'
    } else {
        $lblMatch.ForeColor = $clrErr
        $lblMatch.Text      = 'Passwords do not match'
    }
})

$btnEncrypt.Add_Click({ Invoke-Encryption })
$btnCancel.Add_Click({ $form.Close() })
$form.Add_KeyDown({ if ($_.KeyCode -eq 'Escape') { $form.Close() } })
$btnEncrypt.Add_MouseEnter({ $btnEncrypt.BackColor = $clrHover })
$btnEncrypt.Add_MouseLeave({ $btnEncrypt.BackColor = $clrAccent })

# ── Populate file list ────────────────────────────────────────────────────────

$script:validFiles = @()

if ($FilePaths) {
    $valid, $skipped = Test-FilePath -Paths $FilePaths
    $script:validFiles = @($valid)
    foreach ($f in $valid)   { $lstFiles.Items.Add([System.IO.Path]::GetFileName($f)) | Out-Null }
    foreach ($s in $skipped) { $lstFiles.Items.Add("Skipped: $s") | Out-Null }
}

if ($script:validFiles.Count -eq 0) {
    if ($lstFiles.Items.Count -eq 0) { $lstFiles.Items.Add('No valid files selected.') | Out-Null }
    $btnEncrypt.Enabled = $false
}

# ── Launch ────────────────────────────────────────────────────────────────────

[System.Windows.Forms.Application]::Run($form)
