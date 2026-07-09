# Fix the email if it was mistyped when running setup-github-ssh.
#
# What it does:
#   - Fixes the email Git signs your changes with (this is the important part).
#   - Updates your SSH key's label (this is only cosmetic).
#   - Verifies the connection with GitHub still works.
# It does NOT touch your key, and you don't need to paste it into GitHub again.
#
# How to use it: double-click the  fix-github-email.bat  file (it's in the
# windows folder, one level above this lib folder).

# Show accents and symbols correctly
try {
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

$KEY = Join-Path $HOME ".ssh\id_ed25519"

Write-Host ""
Write-Host "════════════════════════════════════════════════"
Write-Host "   Fix the email in your configuration"
Write-Host "════════════════════════════════════════════════"
Write-Host ""

# --- Requirement: Git must be installed ---
$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
            [Environment]::GetEnvironmentVariable("Path", "User")
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Host "❌ Git is not installed on this computer."
  Write-Host "   Run  setup-github-ssh.bat  first, then this one."
  Read-Host "Press Enter to close" | Out-Null
  exit 1
}

# --- Show what's set right now ---
$CURRENT_NAME = git config --global user.name 2>$null
$CURRENT_EMAIL = git config --global user.email 2>$null
if ([string]::IsNullOrWhiteSpace($CURRENT_NAME)) { $CURRENT_NAME = "(not set)" }
if ([string]::IsNullOrWhiteSpace($CURRENT_EMAIL)) { $CURRENT_EMAIL = "(not set)" }
Write-Host "Current configuration:"
Write-Host "   Name:  $CURRENT_NAME"
Write-Host "   Email: $CURRENT_EMAIL"
Write-Host ""

# --- Ask for the correct email, with confirmation to avoid another typo ---
$NEW = ""
while ($true) {
  $NEW = ""
  while ([string]::IsNullOrWhiteSpace($NEW)) {
    $NEW = Read-Host "👉 Type the CORRECT email of your GitHub account and press Enter"
  }
  Write-Host ""
  $CONF = Read-Host "   Confirm the email is  $NEW ?  (type Y for yes, N to type it again)"
  Write-Host ""
  if ($CONF -eq "Y" -or $CONF -eq "y") { break }
}

# --- Fix the Git email (the important part) ---
git config --global user.email "$NEW"
Write-Host "✅ Git email fixed: $NEW"

# --- If the name is missing, set it now too ---
if ($CURRENT_NAME -eq "(not set)") {
  $NAME = ""
  while ([string]::IsNullOrWhiteSpace($NAME)) {
    $NAME = Read-Host "👉 Your name is also missing. Type it and press Enter"
  }
  git config --global user.name "$NAME"
  Write-Host "✅ Name configured: $NAME"
}

# --- Update the SSH key's label (cosmetic only) ---
if ((Test-Path $KEY) -and (Get-Command ssh-keygen -ErrorAction SilentlyContinue)) {
  if ($PSVersionTable.PSVersion -ge [version]"7.3") { $NOPASS = "" } else { $NOPASS = '""' }
  $null = & ssh-keygen -c -C "$NEW" -f "$KEY" -P $NOPASS 2>&1
  if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ SSH key label updated."
  } else {
    Write-Host "🟡 Couldn't update the key label (this does not affect the connection at all)."
  }
} else {
  Write-Host "🟡 No SSH key found on this computer. If you haven't run  setup-github-ssh.bat  yet, run it."
}

# --- Verify the connection with GitHub still works ---
Write-Host ""
Write-Host "Checking the connection with GitHub..."
if (Get-Command ssh -ErrorAction SilentlyContinue) {
  # GitHub's reply as plain text (without PowerShell's error decorations)
  $RESULT = (& ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 -T git@github.com 2>&1 |
    ForEach-Object { "$_" }) -join "`n"
  if ($RESULT -match "successfully authenticated") {
    $USER = ""
    if ($RESULT -match "Hi ([^!]+)!") { $USER = $Matches[1] }
    Write-Host "✅ GitHub connection: works. Signed in as: $USER"
  } else {
    Write-Host "⚠️  The GitHub connection didn't work. This is NOT caused by the email;"
    Write-Host "   the key is probably not added on GitHub yet. Run  setup-github-ssh.bat"
  }
} else {
  Write-Host "⚠️  This computer doesn't have the Windows SSH tools turned on."
}

Write-Host ""
Write-Host "════════════════════════════════════════════════"
Write-Host "🎉 Done. Your next changes will use the correct email."
Write-Host ""
Write-Host "📝 Last step (in the browser): make sure that email appears in"
Write-Host "   github.com → Settings → Emails. If it isn't there, add it and verify it,"
Write-Host "   so your changes show up linked to your GitHub profile."
Write-Host "════════════════════════════════════════════════"
Write-Host ""
Read-Host "Press Enter to close this window" | Out-Null
