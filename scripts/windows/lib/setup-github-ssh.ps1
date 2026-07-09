# Connect this computer (Windows) to GitHub via SSH.
#
# How to use it:
#   Double-click the  setup-github-ssh.bat  file (it's in the windows folder,
#   one level above this lib folder).
#   If Windows shows "Windows protected your PC", click
#   "More info" and then "Run anyway".

# Show accents and symbols correctly
try {
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

$KEY = Join-Path $HOME ".ssh\id_ed25519"

# The way to say "no passphrase" to ssh-keygen changes with the PowerShell
# version (passing empty arguments to native programs was fixed in 7.3; the
# .bat always uses 5.1, which needs '""').
if ($PSVersionTable.PSVersion -ge [version]"7.3") { $NOPASS = "" } else { $NOPASS = '""' }

# Test the connection with GitHub and return its reply as plain text
# (without PowerShell's error decorations).
function Test-GitHub {
  return (& ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 -T git@github.com 2>&1 |
    ForEach-Object { "$_" }) -join "`n"
}

Write-Host ""
Write-Host "════════════════════════════════════════════════"
Write-Host "  Connect this computer to GitHub (via SSH)"
Write-Host "════════════════════════════════════════════════"
Write-Host ""

# --- Step 0: check that Windows has the SSH tools ---
if (-not (Get-Command ssh-keygen -ErrorAction SilentlyContinue)) {
  Write-Host "❌ This computer doesn't have the Windows SSH tools."
  Write-Host "   Turn them on like this: Settings → Apps → Optional features"
  Write-Host "   → Add a feature → search for 'OpenSSH Client' → Install."
  Write-Host "   When it's done, double-click the .bat file again."
  Read-Host "Press Enter to close"
  exit 1
}

# --- Step 1: check whether a key already exists ---
# Rare case: the private key exists but the public half is missing. Rebuild it
# so we don't create a brand-new key on top of the existing one.
if ((Test-Path $KEY) -and (-not (Test-Path "$KEY.pub"))) {
  $pub = & ssh-keygen -y -P $NOPASS -f "$KEY" 2>$null
  if ($LASTEXITCODE -eq 0 -and $pub) {
    Set-Content -Path "$KEY.pub" -Value $pub -Encoding Ascii
  }
}

$EMAIL = ""
if ((Test-Path $KEY) -and (Test-Path "$KEY.pub")) {
  Write-Host "✅ You already have an SSH key on this computer. We'll use that one."
} else {
  Write-Host "You don't have an SSH key yet. Let's create one."
  while ([string]::IsNullOrWhiteSpace($EMAIL)) {
    $EMAIL = Read-Host "👉 Type the email of your GitHub account and press Enter"
  }
  $sshDir = Join-Path $HOME ".ssh"
  if (-not (Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir | Out-Null }
  ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY" -N $NOPASS -q
  if (-not ((Test-Path $KEY) -and (Test-Path "$KEY.pub"))) {
    Write-Host "❌ Couldn't create the key. Close this window and try again."
    Read-Host "Press Enter to close"
    exit 1
  }
  Write-Host "✅ Key created."
}

# --- Step 2: make ssh use this key with GitHub ---
$CONFIG = Join-Path $HOME ".ssh\config"
$alreadyConfigured = $false
if (Test-Path $CONFIG) {
  if (Select-String -Path $CONFIG -Pattern "Host github.com" -SimpleMatch -Quiet) {
    $alreadyConfigured = $true
  }
}
if (-not $alreadyConfigured) {
  # Important: no BOM — ssh doesn't understand config files with a BOM.
  $block = "`nHost github.com`n  IdentityFile ~/.ssh/id_ed25519`n"
  Add-Content -Path $CONFIG -Value $block -Encoding Ascii
}

# --- Step 3: copy the public key to the clipboard ---
Get-Content "$KEY.pub" -Raw | Set-Clipboard
Write-Host "📋 Your public key has been copied to the clipboard."
Write-Host ""

# --- Step 4: add it on GitHub (in the browser) ---
Write-Host "GitHub will now open in your browser. There you must:"
Write-Host ""
Write-Host "   1. Sign in if prompted."
Write-Host "   2. In the 'Title' field type a name, for example: My laptop"
Write-Host "   3. In the big 'Key' field paste the key with Ctrl + V"
Write-Host "   4. Click the green 'Add SSH key' button"
Write-Host ""
Read-Host "Press Enter to open GitHub" | Out-Null
Start-Process "https://github.com/settings/ssh/new"
Write-Host ""
Read-Host "Once you've clicked 'Add SSH key', come back here and press Enter" | Out-Null

# --- Step 5: verify the connection ---
Write-Host ""
Write-Host "Checking the connection with GitHub..."
while ($true) {
  $RESULT = Test-GitHub
  if ($RESULT -match "successfully authenticated") {
    Write-Host ""
    Write-Host "🎉 Done! Your computer is now connected to GitHub."
    if ($RESULT -match "Hi ([^!]+)!") {
      Write-Host "   Signed in as: $($Matches[1])"
    }
    break
  } else {
    Write-Host ""
    Write-Host "⚠️  Not working yet. GitHub replied:"
    Write-Host "----------------------------------------"
    Write-Host $RESULT.Trim()
    Write-Host "----------------------------------------"
    Write-Host "Make sure you pasted the key and clicked 'Add SSH key' in the browser."
    Read-Host "Press Enter to try again (or close this window to quit)" | Out-Null
  }
}

# --- Step 6: check and install Git if needed ---
Write-Host ""
Write-Host "Checking whether Git is installed..."

function Update-Path {
  $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
              [Environment]::GetEnvironmentVariable("Path", "User")
}

function Test-GitAvailable {
  Update-Path
  return [bool](Get-Command git -ErrorAction SilentlyContinue)
}

function Open-GitPage {
  Write-Host "The official Git page will open. There you must:"
  Write-Host ""
  Write-Host "   1. Click 'Click here to download'."
  Write-Host "   2. Open the downloaded file."
  Write-Host "   3. Click 'Next' through everything until it says 'Install', and wait for it to finish."
  Write-Host ""
  Read-Host "Press Enter to open the Git page" | Out-Null
  Start-Process "https://git-scm.com/download/win"
}

if (Test-GitAvailable) {
  Write-Host "✅ Git is already installed: $(git --version)"
} else {
  Write-Host ""
  Write-Host "Git is not installed. Let's install it."
  $installed = $false
  if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "Installing Git with the Windows installer (this may take several minutes)."
    Write-Host "If a window appears asking for permission, click 'Yes'."
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0) { $installed = $true }
    if (-not $installed) {
      Write-Host ""
      Write-Host "⚠️  The automatic installer couldn't finish (this can happen if your"
      Write-Host "   account doesn't have administrator rights). Let's do it manually."
      Write-Host ""
    }
  }
  if (-not $installed) { Open-GitPage }
  Write-Host ""
  while ($true) {
    $RESP = Read-Host "When the install has FINISHED, press Enter to check (or type R and Enter to open the download page again)"
    if ($RESP -eq "R" -or $RESP -eq "r") { Open-GitPage; continue }
    if (Test-GitAvailable) {
      Write-Host "✅ Git installed: $(git --version)"
      break
    }
    Write-Host ""
    Write-Host "⚠️  Git still doesn't appear to be installed."
    Write-Host "   - If the installer is still working, wait for it to finish and press Enter again."
    Write-Host "   - If you couldn't install it, type R and Enter to open the download page."
    Write-Host "   - If nothing works, close this window and ask for help with a screenshot."
    Write-Host ""
  }
}

# --- Step 7: set your name and email in Git (used on your commits) ---
$NAME = git config --global user.name 2>$null
$GITMAIL = git config --global user.email 2>$null

if ([string]::IsNullOrWhiteSpace($NAME)) {
  Write-Host ""
  while ([string]::IsNullOrWhiteSpace($NAME)) {
    $NAME = Read-Host "👉 Type your name (this is how it appears on your changes) and press Enter"
  }
  git config --global user.name "$NAME"
}

if ([string]::IsNullOrWhiteSpace($GITMAIL)) {
  if (-not [string]::IsNullOrWhiteSpace($EMAIL)) {
    $GITMAIL = $EMAIL
    Write-Host "I'll use the same email you gave for the key: $GITMAIL"
  } else {
    while ([string]::IsNullOrWhiteSpace($GITMAIL)) {
      $GITMAIL = Read-Host "👉 Type the email of your GitHub account and press Enter"
    }
  }
  git config --global user.email "$GITMAIL"
}
Write-Host "✅ Git configured as: $NAME <$GITMAIL>"

Write-Host ""
Write-Host "🎉 All set. You can now clone the repository using its SSH address"
Write-Host "   (the one that starts with git@github.com)."
Write-Host ""
Read-Host "Press Enter to close this window" | Out-Null
