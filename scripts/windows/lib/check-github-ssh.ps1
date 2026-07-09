# Check that this computer (Windows) is properly connected to GitHub over SSH.
# This script changes NOTHING: it only inspects and reports each point.
#
# How to use it: double-click the  check-github-ssh.bat  file (it's in the
# windows folder, one level above this lib folder).

# Show accents and symbols correctly
try {
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

$PROBLEMS = 0

Write-Host ""
Write-Host "════════════════════════════════════════════════"
Write-Host "   Checking the connection with GitHub"
Write-Host "════════════════════════════════════════════════"
Write-Host ""

# --- 1. Does the SSH key exist? ---
$KEY = Join-Path $HOME ".ssh\id_ed25519"
$otherKeys = Get-ChildItem -Path (Join-Path $HOME ".ssh") -Filter "*.pub" -ErrorAction SilentlyContinue
if ((Test-Path $KEY) -and (Test-Path "$KEY.pub")) {
  Write-Host "✅ 1. SSH key: exists (id_ed25519)"
} elseif ($otherKeys) {
  Write-Host "🟡 1. SSH key: you have a key, but with a different name:"
  $otherKeys | ForEach-Object { Write-Host "      $($_.FullName)" }
  Write-Host "      (it may work, but it isn't the one our script creates)"
} else {
  Write-Host "❌ 1. SSH key: does not exist."
  Write-Host "      → Run the  setup-github-ssh.bat  script"
  $PROBLEMS = $PROBLEMS + 1
}
Write-Host ""

# --- 2. Is it configured so ssh uses the key? ---
$CONFIG = Join-Path $HOME ".ssh\config"
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

# --- 3. Does the connection to GitHub work? ---
Write-Host "   Testing the connection with GitHub (may take a few seconds)..."
if (Get-Command ssh -ErrorAction SilentlyContinue) {
  # GitHub's reply as plain text (without PowerShell's error decorations)
  $RESULT = (& ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 -T git@github.com 2>&1 |
    ForEach-Object { "$_" }) -join "`n"
  if ($RESULT -match "successfully authenticated") {
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
$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
            [Environment]::GetEnvironmentVariable("Path", "User")
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
Read-Host "Press Enter to close this window" | Out-Null
