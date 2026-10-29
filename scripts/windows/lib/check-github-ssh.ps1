# Check that this computer (Windows) is properly connected to GitHub over SSH.
# This script changes NOTHING: it only inspects and reports each point.
#
# How to use it: double-click the  check-github-ssh.bat  file (it's in the
# windows folder, one level above this lib folder).
#
# For AI agents: add -Agent so it doesn't wait for Enter at the end. Exit code 0
# means everything is ready; 1 means something has to be fixed (the lines
# marked ❌ say what).

param([switch]$Agent)

# Show accents and symbols correctly
try {
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

# Nobody can press Enter when the input isn't the keyboard (for example, when an
# AI agent runs the script), so it then works as with -Agent.
$UNATTENDED = [bool]$Agent
try { if ([Console]::IsInputRedirected) { $UNATTENDED = $true } } catch {}

$PROBLEMS = 0

Write-Host ""
Write-Host "════════════════════════════════════════════════"
Write-Host "   Checking the connection with GitHub"
Write-Host "════════════════════════════════════════════════"
Write-Host ""

# The connection is tested first: whether it works decides how serious a
# missing key file is (point 1).
Write-Host "   Testing the connection with GitHub (may take a few seconds)..."
Write-Host ""
$HAS_SSH = [bool](Get-Command ssh -ErrorAction SilentlyContinue)
$RESULT = ""
if ($HAS_SSH) {
  # GitHub's reply as plain text (without PowerShell's error decorations).
  # Without anyone at the keyboard, BatchMode keeps ssh from waiting for a passphrase.
  $batch = @()
  if ($UNATTENDED) { $batch = @("-o", "BatchMode=yes") }
  $RESULT = (& ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 @batch -T git@github.com 2>&1 |
    ForEach-Object { "$_" }) -join "`n"
}
$CONNECTED = ($RESULT -match "successfully authenticated")

# --- 1. Does the SSH key exist? ---
$KEY = Join-Path (Join-Path $HOME ".ssh") "id_ed25519"
$otherKeys = Get-ChildItem -Path (Join-Path $HOME ".ssh") -Filter "*.pub" -ErrorAction SilentlyContinue
if ((Test-Path $KEY) -and (Test-Path "$KEY.pub")) {
  Write-Host "✅ 1. SSH key: exists (id_ed25519)"
} elseif ($otherKeys) {
  Write-Host "🟡 1. SSH key: you have a key, but with a different name:"
  $otherKeys | ForEach-Object { Write-Host "      $($_.FullName)" }
  Write-Host "      (it may work, but it isn't the one our script creates)"
} elseif ($CONNECTED) {
  Write-Host "🟡 1. SSH key: there's no key file in .ssh, but the connection works"
  Write-Host "      (the key is kept somewhere else, such as an SSH agent)."
} else {
  Write-Host "❌ 1. SSH key: does not exist."
  Write-Host "      → Run the  setup-github-ssh.bat  script"
  $PROBLEMS = $PROBLEMS + 1
}
Write-Host ""

# --- 2. Is it configured so ssh uses the key? ---
$CONFIG = Join-Path (Join-Path $HOME ".ssh") "config"
$configured = $false
if (Test-Path $CONFIG) {
  if (Select-String -Path $CONFIG -Pattern "Host github.com" -SimpleMatch -Quiet) {
    $configured = $true
  }
}
if ($configured) {
  Write-Host "✅ 2. SSH config: ready"
} else {
  Write-Host "🟡 2. SSH config: the config file is missing."
  Write-Host "      Not serious, but  setup-github-ssh.bat  sets it up for you."
}
Write-Host ""

# --- 3. Does the connection to GitHub work? (tested at the top) ---
if ($HAS_SSH) {
  if ($CONNECTED) {
    $USER = ""
    if ($RESULT -match "Hi ([^!]+)!") { $USER = $Matches[1] }
    Write-Host "✅ 3. GitHub connection: works. Signed in as: $USER"
  } else {
    Write-Host "❌ 3. GitHub connection: failed. GitHub replied:"
    Write-Host "----------------------------------------"
    Write-Host $RESULT.Trim()
    Write-Host "----------------------------------------"
    Write-Host "      → Check that you added the key at github.com → Settings → SSH and GPG keys"
    $PROBLEMS = $PROBLEMS + 1
  }
} else {
  Write-Host "❌ 3. GitHub connection: this computer doesn't have the SSH tools."
  Write-Host "      → Turn them on at: Settings → Apps → Optional features"
  Write-Host "        → Add a feature → 'OpenSSH Client' → Install."
  $PROBLEMS = $PROBLEMS + 1
}
Write-Host ""

# --- 4 and 5. Is Git installed and configured? ---
# Reload the PATH saved in Windows, keeping the current one too.
$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
            [Environment]::GetEnvironmentVariable("Path", "User") + ";" + $env:Path
if (Get-Command git -ErrorAction SilentlyContinue) {
  Write-Host "✅ 4. Git installed: $(git --version)"
  Write-Host ""

  $NAME = git config --global user.name 2>$null
  $GITMAIL = git config --global user.email 2>$null
  if (-not [string]::IsNullOrWhiteSpace($NAME) -and -not [string]::IsNullOrWhiteSpace($GITMAIL)) {
    Write-Host "✅ 5. Git configured: $NAME <$GITMAIL>"
  } else {
    Write-Host "❌ 5. Git configured: your name or email is missing."
    Write-Host "      → Run the  setup-github-ssh.bat  script (it asks at the end)."
    $PROBLEMS = $PROBLEMS + 1
  }
} else {
  Write-Host "❌ 4. Git installed: no."
  Write-Host "      → Run the  setup-github-ssh.bat  script (it installs Git too)."
  Write-Host ""
  Write-Host "❌ 5. Git configured: pending (install Git first, point 4)."
  $PROBLEMS = $PROBLEMS + 2
}
Write-Host ""

# --- 6. Is the GitHub CLI (gh) installed? ---
# It only counts if it's on the PATH and actually runs.
$GH_VERSION = ""
if (Get-Command gh -ErrorAction SilentlyContinue) {
  try {
    $GH_VERSION = @(& gh --version 2>$null)[0]
    if ($LASTEXITCODE -ne 0) { $GH_VERSION = "" }
  } catch { $GH_VERSION = "" }
}
if (-not [string]::IsNullOrWhiteSpace($GH_VERSION)) {
  Write-Host "✅ 6. GitHub CLI installed: $GH_VERSION"
} else {
  # The installer to download depends on the processor (most PCs are amd64).
  $GH_MSI = "windows_amd64.msi"
  if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64" -or $env:PROCESSOR_ARCHITEW6432 -eq "ARM64") {
    $GH_MSI = "windows_arm64.msi"
  }
  Write-Host "❌ 6. GitHub CLI installed: no. To install it:"
  Write-Host "      → Open https://github.com/cli/cli/releases/latest and, under 'Assets',"
  Write-Host "        download the file that ends in  $GH_MSI . Open it and click 'Next'"
  Write-Host "        through to 'Install' (if Windows asks for permission, click 'Yes')."
  Write-Host "      → Or run this command in PowerShell:  winget install --id GitHub.cli --source winget"
  Write-Host "      → Then open a NEW PowerShell window so 'gh' is found."
  Write-Host "      (The  setup-github-ssh.bat  script walks you through it step by step.)"
  $PROBLEMS = $PROBLEMS + 1
}
Write-Host ""

# --- Summary ---
Write-Host "════════════════════════════════════════════════"
if ($PROBLEMS -eq 0) {
  Write-Host "🎉 All set. This computer can already work with GitHub."
} else {
  Write-Host "⚠️  There are $PROBLEMS point(s) to fix — look above for the lines"
  Write-Host "   marked with ❌ (the ones that say 'does not exist', 'failed' or 'missing')."
}
Write-Host "════════════════════════════════════════════════"
Write-Host ""
# With problems it ends with exit code 1, and the .bat keeps the window open.
if ($PROBLEMS -gt 0) { exit 1 }
if (-not $UNATTENDED) {
  try { Read-Host "Press Enter to close this window" | Out-Null } catch {}
}
exit 0
