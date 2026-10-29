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
#
# For AI agents -- no questions:
#   powershell -NoProfile -ExecutionPolicy Bypass -File fix-github-email.ps1 -Agent -Email "you@example.com" [-Name "Your Name"]

param(
  [string]$Email = "",
  [string]$Name = "",
  [switch]$Agent
)

# Show accents and symbols correctly
try {
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

# PowerShell names ignore case ($Name and $NAME are the same typed variable),
# so the options are copied here and the rest of the script uses other names.
$EMAIL_ARG = $Email.Trim()
$NAME_ARG = $Name.Trim()

# Email check: something@something.something, without spaces.
function Test-Email([string]$Value) {
  return ($Value -match '^[^@\s]+@[^@\s]+\.[^@\s]+$')
}

if ($EMAIL_ARG -and -not (Test-Email $EMAIL_ARG)) {
  Write-Host "❌ -Email doesn't look like an email address: $EMAIL_ARG"
  exit 1
}

# Nobody can answer questions when the input isn't the keyboard (for example,
# when an AI agent runs the script), so it then works as with -Agent.
$UNATTENDED = [bool]$Agent
try { if ([Console]::IsInputRedirected) { $UNATTENDED = $true } } catch {}

# Ask the person something. Returns $null when nobody can answer (agent mode, or
# the input has ended), so no question is ever repeated forever.
function Read-Answer([string]$Prompt) {
  if ($script:UNATTENDED) { return $null }
  $answer = $null
  try { $answer = Read-Host $Prompt } catch {}
  if ($null -eq $answer) {
    $script:UNATTENDED = $true
    Write-Host ""
  }
  return $answer
}

# In agent mode a missing answer can't be asked for: it has to come as an option.
function Stop-Missing([string]$Option, [string]$What) {
  Write-Host ""
  Write-Host "❌ Missing $What. Run the script again adding:  $Option `"...`""
  exit 1
}

$KEY = Join-Path (Join-Path $HOME ".ssh") "id_ed25519"

Write-Host ""
Write-Host "════════════════════════════════════════════════"
Write-Host "   Fix the email in your configuration"
Write-Host "════════════════════════════════════════════════"
Write-Host ""

# --- Requirement: Git must be installed ---
# Reload the PATH saved in Windows, keeping the current one too.
$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
            [Environment]::GetEnvironmentVariable("Path", "User") + ";" + $env:Path
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Host "❌ Git is not installed on this computer."
  Write-Host "   Run  setup-github-ssh.bat  first, then this one."
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

# --- The correct email: given as an option, or asked with confirmation to avoid another typo ---
$NEW = $EMAIL_ARG
while (-not $NEW) {
  $CANDIDATE = ""
  while (-not (Test-Email $CANDIDATE)) {
    if ($CANDIDATE) { Write-Host "   That doesn't look like an email address. Please try again." }
    $CANDIDATE = Read-Answer "👉 Type the CORRECT email of your GitHub account and press Enter"
    if ($null -eq $CANDIDATE) { Stop-Missing "-Email" "the correct email" }
    $CANDIDATE = $CANDIDATE.Trim()
  }
  Write-Host ""
  $CONF = Read-Answer "   Confirm the email is  $CANDIDATE ?  (type Y for yes, N to type it again)"
  if ($null -eq $CONF) { Stop-Missing "-Email" "the correct email" }
  Write-Host ""
  if ($CONF -eq "Y" -or $CONF -eq "y") { $NEW = $CANDIDATE }
}

# --- Fix the Git email (the important part) ---
git config --global user.email "$NEW"
if ($LASTEXITCODE -ne 0) {
  Write-Host "❌ Couldn't save the email in Git."
  exit 1
}
Write-Host "✅ Git email fixed: $NEW"

# --- Set the name if it was given, or if it's missing ---
$NEW_NAME = $NAME_ARG
if (-not $NEW_NAME -and $CURRENT_NAME -eq "(not set)") {
  while ([string]::IsNullOrWhiteSpace($NEW_NAME)) {
    $NEW_NAME = Read-Answer "👉 Your name is also missing. Type it and press Enter"
    if ($null -eq $NEW_NAME) { Stop-Missing "-Name" "your name" }
  }
  $NEW_NAME = $NEW_NAME.Trim()
}
if ($NEW_NAME) {
  git config --global user.name "$NEW_NAME"
  Write-Host "✅ Name configured: $NEW_NAME"
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
  # GitHub's reply as plain text (without PowerShell's error decorations).
  # Without anyone at the keyboard, BatchMode keeps ssh from waiting for a passphrase.
  $batch = @()
  if ($UNATTENDED) { $batch = @("-o", "BatchMode=yes") }
  $RESULT = (& ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 @batch -T git@github.com 2>&1 |
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
Read-Answer "Press Enter to close this window" | Out-Null
exit 0
