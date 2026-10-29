# Connect this computer (Windows) to GitHub via SSH.
#
# How to use it:
#   Double-click the  setup-github-ssh.bat  file (it's in the windows folder,
#   one level above this lib folder).
#   If Windows shows "Windows protected your PC", click
#   "More info" and then "Run anyway".
#
# For AI agents -- no questions and no waiting:
#   powershell -NoProfile -ExecutionPolicy Bypass -File setup-github-ssh.ps1 -Agent -Email "you@example.com" -Name "Your Name"
# Exit code 0 means everything is done; 2 means it's waiting for a step (its
# last lines say which; run the same command again once it's done); 1 means an
# error. Running it again is safe: it skips whatever is already done.

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

# PowerShell names ignore case ($Email and $EMAIL are the same typed variable),
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

# Stop because a step has to happen first (the lines above say which).
function Stop-Waiting([string]$What) {
  Write-Host ""
  Write-Host "⏸  Waiting for: $What"
  Write-Host "   When it's done, run this setup again. It skips whatever is already done."
  exit 2
}

# In agent mode a missing answer can't be asked for: it has to come as an option.
function Stop-Missing([string]$Option, [string]$What) {
  Write-Host ""
  Write-Host "❌ Missing $What. Run the setup again adding:  $Option `"...`""
  exit 1
}

$KEY = Join-Path (Join-Path $HOME ".ssh") "id_ed25519"
$KEY_EMAIL = $EMAIL_ARG

# The way to say "no passphrase" to ssh-keygen changes with the PowerShell
# version (passing empty arguments to native programs was fixed in 7.3; the
# .bat always uses 5.1, which needs '""').
if ($PSVersionTable.PSVersion -ge [version]"7.3") { $NOPASS = "" } else { $NOPASS = '""' }

# Test the connection with GitHub and return its reply as plain text (without
# PowerShell's error decorations). In agent mode nobody can type a passphrase,
# so BatchMode keeps ssh from waiting for one.
function Test-GitHub {
  $batch = @()
  if ($script:UNATTENDED) { $batch = @("-o", "BatchMode=yes") }
  return (& ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 @batch -T git@github.com 2>&1 |
    ForEach-Object { "$_" }) -join "`n"
}

function Get-GitHubUser([string]$Reply) {
  if ($Reply -match "Hi ([^!]+)!") { return $Matches[1] }
  return ""
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
  Stop-Waiting "the 'OpenSSH Client' feature to be installed (steps above)"
}

# --- Step 1: is this computer already connected? Then SSH needs nothing else ---
Write-Host "Checking the connection with GitHub..."
$RESULT = Test-GitHub
if ($RESULT -match "successfully authenticated") {
  Write-Host "✅ This computer is already connected to GitHub. Signed in as: $(Get-GitHubUser $RESULT)"
} else {
  # --- Step 2: create the SSH key, or reuse the one that exists ---
  # Rare case: the private key exists but the public half is missing. Rebuild it
  # so we don't create a brand-new key on top of the existing one.
  if ((Test-Path $KEY) -and (-not (Test-Path "$KEY.pub"))) {
    $pub = & ssh-keygen -y -P $NOPASS -f "$KEY" 2>$null
    if ($LASTEXITCODE -eq 0 -and $pub) {
      Set-Content -Path "$KEY.pub" -Value $pub -Encoding Ascii
    }
  }
  # If that failed, the key has a passphrase: only its owner can rebuild the
  # public half, and the key must never be overwritten.
  if ((Test-Path $KEY) -and (-not (Test-Path "$KEY.pub"))) {
    Write-Host "❌ There's an SSH key at $KEY, but its public half is missing and"
    Write-Host "   the key has a passphrase. To rebuild it, run this in PowerShell and type"
    Write-Host "   the key's passphrase:"
    Write-Host "      ssh-keygen -y -f `"$KEY`" | Set-Content -Encoding Ascii `"$KEY.pub`""
    Stop-Waiting "the public key to be rebuilt (see above)"
  }

  if (Test-Path $KEY) {
    Write-Host "✅ You already have an SSH key on this computer. We'll use that one."
  } else {
    Write-Host "You don't have an SSH key yet. Let's create one."
    while (-not (Test-Email $KEY_EMAIL)) {
      if ($KEY_EMAIL) { Write-Host "   That doesn't look like an email address. Please try again." }
      $KEY_EMAIL = Read-Answer "👉 Type the email of your GitHub account and press Enter"
      if ($null -eq $KEY_EMAIL) { Stop-Missing "-Email" "the email of your GitHub account" }
      $KEY_EMAIL = $KEY_EMAIL.Trim()
    }
    $sshDir = Join-Path $HOME ".ssh"
    if (-not (Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir | Out-Null }
    ssh-keygen -t ed25519 -C "$KEY_EMAIL" -f "$KEY" -N $NOPASS -q
    if (-not ((Test-Path $KEY) -and (Test-Path "$KEY.pub"))) {
      Write-Host "❌ Couldn't create the key. Close this window and try again."
      exit 1
    }
    Write-Host "✅ Key created."
  }

  # --- Step 3: make ssh use this key with GitHub ---
  $CONFIG = Join-Path (Join-Path $HOME ".ssh") "config"
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

  # --- Step 4: add the public key on GitHub, unless GitHub already has it ---
  $RESULT = Test-GitHub
  if ($RESULT -match "successfully authenticated") {
    Write-Host "✅ GitHub already knows this key. Signed in as: $(Get-GitHubUser $RESULT)"
  } else {
    # "Permission denied" means GitHub doesn't know the key. Any other reply
    # (no internet, a network that blocks SSH...) won't be fixed by adding it.
    if ($RESULT -match "Permission denied") {
      Write-Host ""
      Write-Host "Now the key has to be added to your GitHub account. This is its public half"
      Write-Host "(it's safe to share):"
      Write-Host ""
      Write-Host (Get-Content "$KEY.pub" -Raw).Trim()
      Write-Host ""
      try {
        Get-Content "$KEY.pub" -Raw | Set-Clipboard -ErrorAction Stop
        Write-Host "📋 Your public key has been copied to the clipboard."
        Write-Host ""
      } catch {}
      Write-Host "GitHub will now open in your browser (https://github.com/settings/ssh/new)."
      Write-Host "There you must:"
      Write-Host ""
      Write-Host "   1. Sign in if prompted."
      Write-Host "   2. In the 'Title' field type a name, for example: My laptop"
      Write-Host "   3. In the big 'Key' field paste the key with Ctrl + V"
      Write-Host "   4. Click the green 'Add SSH key' button"
      Write-Host ""
      Read-Answer "Press Enter to open GitHub" | Out-Null
      try { Start-Process "https://github.com/settings/ssh/new" -ErrorAction Stop } catch {}
      if ($UNATTENDED) { Stop-Waiting "the key to be added on GitHub (steps above)" }
      Write-Host ""
      Read-Answer "Once you've clicked 'Add SSH key', come back here and press Enter" | Out-Null
    }

    # --- Step 5: verify the connection ---
    Write-Host ""
    Write-Host "Checking the connection with GitHub..."
    while ($true) {
      $RESULT = Test-GitHub
      if ($RESULT -match "successfully authenticated") {
        Write-Host ""
        Write-Host "🎉 Done! Your computer is now connected to GitHub."
        Write-Host "   Signed in as: $(Get-GitHubUser $RESULT)"
        break
      }
      Write-Host ""
      Write-Host "⚠️  Not working yet. GitHub replied:"
      Write-Host "----------------------------------------"
      Write-Host $RESULT.Trim()
      Write-Host "----------------------------------------"
      if ($RESULT -match "Permission denied") {
        Write-Host "Make sure you pasted the key and clicked 'Add SSH key' in the browser."
        if ($null -eq (Read-Answer "Press Enter to try again (or close this window to quit)")) {
          Stop-Waiting "the key to be added on GitHub (steps above)"
        }
      } else {
        Write-Host "That's not a problem with the key: this computer can't reach GitHub. Check"
        Write-Host "the internet connection (some networks, like many offices, block SSH)."
        if ($null -eq (Read-Answer "Press Enter to try again (or close this window to quit)")) { exit 1 }
      }
    }
  }
}

# --- Step 6: check and install Git if needed ---
Write-Host ""
Write-Host "Checking whether Git is installed..."

# Reload the PATH saved in Windows (installers update it there), keeping the
# current one too so nothing that was already found gets lost.
function Update-Path {
  $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
              [Environment]::GetEnvironmentVariable("Path", "User") + ";" + $env:Path
}

function Test-GitAvailable {
  Update-Path
  return [bool](Get-Command git -ErrorAction SilentlyContinue)
}

function Open-GitPage {
  Write-Host "The official Git page will open (https://git-scm.com/download/win). There you must:"
  Write-Host ""
  Write-Host "   1. Click 'Click here to download'."
  Write-Host "   2. Open the downloaded file."
  Write-Host "   3. Click 'Next' through everything until it says 'Install', and wait for it to finish."
  Write-Host ""
  Read-Answer "Press Enter to open the Git page" | Out-Null
  try { Start-Process "https://git-scm.com/download/win" -ErrorAction Stop } catch {}
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
  if ($installed -and (Test-GitAvailable)) {
    Write-Host "✅ Git installed: $(git --version)"
  } else {
    if (-not $installed) { Open-GitPage }
    if ($UNATTENDED) { Stop-Waiting "Git to be installed (steps above)" }
    Write-Host ""
    while ($true) {
      $RESP = Read-Answer "When the install has FINISHED, press Enter to check (or type R and Enter to open the download page again)"
      if ($null -eq $RESP) { Stop-Waiting "Git to be installed (steps above)" }
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
}

# --- Step 7: set your name and email in Git (used on your commits) ---
$GIT_NAME = git config --global user.name 2>$null
$GITMAIL = git config --global user.email 2>$null
# Values given as options replace what was configured before.
if ($NAME_ARG) { $GIT_NAME = $NAME_ARG }
if ($EMAIL_ARG) { $GITMAIL = $EMAIL_ARG }

if ([string]::IsNullOrWhiteSpace($GIT_NAME)) {
  Write-Host ""
  while ([string]::IsNullOrWhiteSpace($GIT_NAME)) {
    $GIT_NAME = Read-Answer "👉 Type your name (this is how it appears on your changes) and press Enter"
    if ($null -eq $GIT_NAME) { Stop-Missing "-Name" "your name" }
  }
  $GIT_NAME = $GIT_NAME.Trim()
}

if ([string]::IsNullOrWhiteSpace($GITMAIL)) {
  if (-not [string]::IsNullOrWhiteSpace($KEY_EMAIL)) {
    $GITMAIL = $KEY_EMAIL
    Write-Host "I'll use the same email you gave for the key: $GITMAIL"
  } else {
    while (-not (Test-Email $GITMAIL)) {
      if ($GITMAIL) { Write-Host "   That doesn't look like an email address. Please try again." }
      $GITMAIL = Read-Answer "👉 Type the email of your GitHub account and press Enter"
      if ($null -eq $GITMAIL) { Stop-Missing "-Email" "the email of your GitHub account" }
      $GITMAIL = $GITMAIL.Trim()
    }
  }
}
git config --global user.name "$GIT_NAME"
$nameSaved = ($LASTEXITCODE -eq 0)
git config --global user.email "$GITMAIL"
if (-not $nameSaved -or $LASTEXITCODE -ne 0) {
  Write-Host "❌ Couldn't save your name and email in Git."
  exit 1
}
Write-Host "✅ Git configured as: $GIT_NAME <$GITMAIL>"

# --- Step 8: check the GitHub CLI (gh) and explain how to install it if needed ---
Write-Host ""
Write-Host "Checking whether the GitHub CLI (gh) is installed..."

# gh is available if it's on the PATH and actually runs.
function Test-GhAvailable {
  Update-Path
  if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { return $false }
  try { $null = & gh --version 2>$null } catch { return $false }
  return ($LASTEXITCODE -eq 0)
}

# The installer to download depends on the processor (most PCs are amd64).
$GH_MSI = "windows_amd64.msi"
if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64" -or $env:PROCESSOR_ARCHITEW6432 -eq "ARM64") {
  $GH_MSI = "windows_arm64.msi"
}

function Open-GhPage {
  Write-Host "The GitHub CLI download page will open (https://github.com/cli/cli/releases/latest)."
  Write-Host "There you must:"
  Write-Host ""
  Write-Host "   1. Under 'Assets', click the file whose name ends in  $GH_MSI"
  Write-Host "   2. Open the downloaded file."
  Write-Host "   3. Click 'Next' through everything until it says 'Install', and then 'Finish'."
  Write-Host "      If a window appears asking for permission, click 'Yes'."
  Write-Host ""
  Read-Answer "Press Enter to open the download page" | Out-Null
  try { Start-Process "https://github.com/cli/cli/releases/latest" -ErrorAction Stop } catch {}
}

if (Test-GhAvailable) {
  Write-Host "✅ GitHub CLI is already installed: $(@(gh --version)[0])"
} else {
  Write-Host ""
  Write-Host "The GitHub CLI (gh) is not installed. It's GitHub's official tool to work with"
  Write-Host "GitHub from the terminal (your AI assistant can use it too). Let's install it."
  Write-Host ""
  # An agent can install it with winget by itself; a person gets the installer.
  if ($UNATTENDED -and (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "winget is available, so it takes a single command:"
    Write-Host "   winget install --id GitHub.cli -e --source winget --accept-package-agreements --accept-source-agreements"
  } else {
    Open-GhPage
  }
  if ($UNATTENDED) { Stop-Waiting "the GitHub CLI to be installed (steps above)" }
  Write-Host ""
  while ($true) {
    $RESP = Read-Answer "When the install has FINISHED, press Enter to check (or type R and Enter to open the download page again, or S and Enter to skip it for now)"
    if ($null -eq $RESP) { Stop-Waiting "the GitHub CLI to be installed (steps above)" }
    if ($RESP -eq "R" -or $RESP -eq "r") { Open-GhPage; continue }
    if ($RESP -eq "S" -or $RESP -eq "s") {
      Write-Host "🟡 Skipped. Whenever you want to install it, run  check-github-ssh.bat  to see the steps."
      break
    }
    if (Test-GhAvailable) {
      Write-Host "✅ GitHub CLI installed: $(@(gh --version)[0])"
      break
    }
    Write-Host ""
    Write-Host "⚠️  The GitHub CLI still doesn't appear to be installed."
    Write-Host "   - If the installer is still working, wait for it to finish and press Enter again."
    Write-Host "   - If you couldn't install it, type R and Enter to open the download page."
    Write-Host "   - If you can't install it now, type S and Enter to skip it."
    Write-Host ""
  }
}

Write-Host ""
Write-Host "🎉 All set. You can now clone the repository using its SSH address"
Write-Host "   (the one that starts with git@github.com)."
Write-Host ""
Read-Answer "Press Enter to close this window" | Out-Null
exit 0
