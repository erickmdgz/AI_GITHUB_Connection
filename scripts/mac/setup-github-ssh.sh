#!/bin/bash
#
# Connect this Mac to GitHub via SSH.
#
# How to use it:
#   1. Open the "Terminal" app (search for it with Cmd + Space).
#   2. Type:  bash  (with a trailing space) -- do NOT press Enter yet.
#   3. Drag this file into the Terminal window and press Enter.
# (Dragging the file passes its full path, so it works no matter which folder
#  Terminal opened in.)
#
# For AI agents -- no questions and no waiting:
#   bash setup-github-ssh.sh --agent --email "you@example.com" --name "Your Name"
# Exit code 0 means everything is done; 2 means it's waiting for a step (its
# last lines say which; run the same command again once it's done); 1 means an
# error. Running it again is safe: it skips whatever is already done.
#

# --- Mac only ---
if [ "$(uname)" != "Darwin" ]; then
  echo "❌ This script is for Mac only. On Windows, use the  scripts/windows  folder in this same kit."
  exit 1
fi

# --- Options (a person running the script doesn't need any) ---
USAGE='Usage: bash setup-github-ssh.sh [--agent] [--email "you@example.com"] [--name "Your Name"]'
EMAIL_ARG=""
NAME_ARG=""
AGENT=0
while [ $# -gt 0 ]; do
  case "$1" in
    --agent) AGENT=1 ;;
    --email|--name)
      if [ -z "$2" ] || [ "${2#--}" != "$2" ]; then
        echo "❌ $1 needs a value."
        echo "   $USAGE"
        exit 1
      fi
      if [ "$1" = "--email" ]; then EMAIL_ARG="$2"; else NAME_ARG="$2"; fi
      shift ;;
    --email=*) EMAIL_ARG="${1#*=}" ;;
    --name=*) NAME_ARG="${1#*=}" ;;
    -h|--help) echo "$USAGE"; exit 0 ;;
    *)
      echo "❌ Unknown option: $1"
      echo "   $USAGE"
      exit 1 ;;
  esac
  shift
done

# Email check: something@something.something, without spaces.
looks_like_email() {
  case "$1" in
    *" "*|*@*@*) return 1 ;;
    ?*@?*.?*) return 0 ;;
    *) return 1 ;;
  esac
}

if [ -n "$EMAIL_ARG" ] && ! looks_like_email "$EMAIL_ARG"; then
  echo "❌ --email doesn't look like an email address: $EMAIL_ARG"
  exit 1
fi

# Nobody can answer questions when the input isn't a terminal (for example,
# when an AI agent runs the script), so it then works as with --agent.
[ -t 0 ] || AGENT=1

# Ask the person something. It fails when nobody can answer (agent mode, or the
# input has ended), so no question is ever repeated forever.
ask() {
  [ "$AGENT" -eq 1 ] && return 1
  read -r -p "$1" "$2" && return 0
  AGENT=1
  echo ""
  return 1
}

# Stop because a step has to happen first (the lines above say which).
waiting_for() {
  echo ""
  echo "⏸  Waiting for: $1"
  echo "   When it's done, run this setup again. It skips whatever is already done."
  exit 2
}

# In agent mode a missing answer can't be asked for: it has to come as an option.
missing_option() {
  echo ""
  echo "❌ Missing $2. Run the setup again adding:  $1 \"...\""
  exit 1
}

KEY="$HOME/.ssh/id_ed25519"
EMAIL="$EMAIL_ARG"

echo ""
echo "════════════════════════════════════════════════"
echo "     Connect this Mac to GitHub (via SSH)"
echo "════════════════════════════════════════════════"
echo ""

# Test the connection with GitHub and print its reply. In agent mode nobody can
# type a passphrase, so BatchMode keeps ssh from waiting for one.
test_github() {
  BATCH=""
  [ "$AGENT" -eq 1 ] && BATCH="-o BatchMode=yes"
  ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 $BATCH -T git@github.com 2>&1
}

connected() { echo "$RESULT" | grep -q "successfully authenticated"; }
github_user() { echo "$RESULT" | sed -n 's/^Hi \([^!]*\)!.*/\1/p'; }

# --- Step 1: is this Mac already connected? Then SSH needs nothing else ---
echo "Checking the connection with GitHub..."
RESULT=$(test_github)
if connected; then
  echo "✅ This Mac is already connected to GitHub. Signed in as: $(github_user)"
else
  # --- Step 2: create the SSH key, or reuse the one that exists ---
  # Rare case: the private key exists but the public half is missing.
  # Rebuild it so we don't create a brand-new key on top of the existing one.
  if [ -f "$KEY" ] && [ ! -f "$KEY.pub" ]; then
    ssh-keygen -y -P "" -f "$KEY" > "$KEY.pub" 2>/dev/null || rm -f "$KEY.pub"
  fi
  # If that failed, the key has a passphrase: only its owner can rebuild the
  # public half, and the key must never be overwritten.
  if [ -f "$KEY" ] && [ ! -f "$KEY.pub" ]; then
    echo "❌ There's an SSH key at ~/.ssh/id_ed25519, but its public half is missing and"
    echo "   the key has a passphrase. To rebuild it, run this in Terminal and type the"
    echo "   key's passphrase:"
    echo "      ssh-keygen -y -f ~/.ssh/id_ed25519 > ~/.ssh/id_ed25519.pub"
    waiting_for "the public key to be rebuilt (see above)"
  fi

  if [ -f "$KEY" ]; then
    echo "✅ You already have an SSH key on this Mac. We'll use that one."
  else
    echo "You don't have an SSH key yet. Let's create one."
    while ! looks_like_email "$EMAIL"; do
      [ -n "$EMAIL" ] && echo "   That doesn't look like an email address. Please try again."
      ask "👉 Type the email of your GitHub account and press Enter: " EMAIL ||
        missing_option "--email" "the email of your GitHub account"
    done
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    # Input from /dev/null: ssh-keygen must never get a "yes" to "Overwrite?".
    if ! ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY" -N "" -q < /dev/null || [ ! -f "$KEY.pub" ]; then
      echo "❌ Couldn't create the key."
      exit 1
    fi
    echo "✅ Key created."
  fi

  # --- Step 3: load the key and store it in the Mac keychain ---
  # Start an agent only if none is running (ssh-add -l returns 2 without one).
  ssh-add -l > /dev/null 2>&1
  if [ $? -eq 2 ]; then
    eval "$(ssh-agent -s)" > /dev/null
  fi
  ssh-add --apple-use-keychain "$KEY" 2>/dev/null

  # Make the key load by itself in the future (after a restart). IgnoreUnknown
  # keeps an ssh that isn't Apple's (e.g. from Homebrew) from rejecting UseKeychain.
  CONFIG="$HOME/.ssh/config"
  if ! grep -qs "Host github.com" "$CONFIG"; then
    cat >> "$CONFIG" << 'EOF'

Host github.com
  AddKeysToAgent yes
  IgnoreUnknown UseKeychain
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOF
  fi

  # --- Step 4: add the public key on GitHub, unless GitHub already has it ---
  RESULT=$(test_github)
  if connected; then
    echo "✅ GitHub already knows this key. Signed in as: $(github_user)"
  else
    # "Permission denied" means GitHub doesn't know the key. Any other reply
    # (no internet, a network that blocks SSH...) won't be fixed by adding it.
    if echo "$RESULT" | grep -q "Permission denied"; then
      echo ""
      echo "Now the key has to be added to your GitHub account. This is its public half"
      echo "(it's safe to share):"
      echo ""
      cat "$KEY.pub"
      echo ""
      if pbcopy < "$KEY.pub" 2>/dev/null; then
        echo "📋 Your public key has been copied to the clipboard."
        echo ""
      fi
      echo "GitHub will now open in your browser (https://github.com/settings/ssh/new)."
      echo "There you must:"
      echo ""
      echo "   1. Sign in if prompted."
      echo "   2. In the 'Title' field type a name, for example: My Mac"
      echo "   3. In the big 'Key' field paste the key with Cmd + V"
      echo "   4. Click the green 'Add SSH key' button"
      echo ""
      ask "Press Enter to open GitHub..." ENTER
      open "https://github.com/settings/ssh/new"
      [ "$AGENT" -eq 1 ] && waiting_for "the key to be added on GitHub (steps above)"
      echo ""
      ask "Once you've clicked 'Add SSH key', come back here and press Enter..." ENTER
    fi

    # --- Step 5: verify the connection ---
    echo ""
    echo "Checking the connection with GitHub..."
    while true; do
      RESULT=$(test_github)
      if connected; then
        echo ""
        echo "🎉 Done! Your Mac is now connected to GitHub."
        echo "   GitHub replied: $(echo "$RESULT" | grep "successfully")"
        break
      fi
      echo ""
      echo "⚠️  Not working yet. GitHub replied:"
      echo "----------------------------------------"
      echo "$RESULT"
      echo "----------------------------------------"
      if echo "$RESULT" | grep -q "Permission denied"; then
        echo "Make sure you pasted the key and clicked 'Add SSH key' in the browser."
        ask "Press Enter to try again (or Ctrl + C to quit)..." ENTER ||
          waiting_for "the key to be added on GitHub (steps above)"
      else
        echo "That's not a problem with the key: this Mac can't reach GitHub. Check the"
        echo "internet connection (some networks, like many offices, block SSH)."
        ask "Press Enter to try again (or Ctrl + C to quit)..." ENTER || exit 1
      fi
    done
  fi
fi

# --- Step 6: check and install Git if needed ---
echo ""
echo "Checking whether Git is installed..."

# Git is available if Apple's command line tools exist, or if some other Git
# (for example via Homebrew) is installed and actually works.
git_available() {
  if xcode-select -p > /dev/null 2>&1; then
    return 0
  fi
  GITBIN=$(command -v git 2>/dev/null)
  if [ -n "$GITBIN" ] && [ "$GITBIN" != "/usr/bin/git" ] && "$GITBIN" --version > /dev/null 2>&1; then
    return 0
  fi
  return 1
}

if git_available; then
  echo "✅ Git is already installed: $(git --version)"
else
  echo ""
  echo "Git is not installed. A macOS window will open asking to install the"
  echo "'command line developer tools'. In that window:"
  echo ""
  echo "   1. Click 'Install' (NOT 'Get Xcode')."
  echo "   2. Accept the license."
  echo "   3. Wait until it finishes — it can take several minutes."
  echo ""
  ask "Press Enter to open the install window..." ENTER
  xcode-select --install 2>/dev/null || true
  [ "$AGENT" -eq 1 ] && waiting_for "Git to finish installing (steps above)"
  echo ""
  while true; do
    ask "When the install has FINISHED, press Enter to check (or type R and Enter if you cancelled the window and want to open it again): " RESP ||
      waiting_for "Git to finish installing (steps above)"
    if [ "$RESP" = "R" ] || [ "$RESP" = "r" ]; then
      xcode-select --install 2>/dev/null || true
      continue
    fi
    if git_available; then
      echo "✅ Git installed: $(git --version)"
      break
    fi
    echo ""
    echo "⚠️  Git still doesn't appear to be installed."
    echo "   - If the window is still working, wait for it to finish and press Enter again."
    echo "   - If no window is open, type R and Enter to open it again."
    echo "   - If it shows a download error, check your internet and try again."
    echo ""
  done
fi

# --- Step 7: set your name and email in Git (used on your commits) ---
NAME=$(git config --global user.name 2>/dev/null)
GITMAIL=$(git config --global user.email 2>/dev/null)
# Values given as options replace what was configured before.
if [ -n "$NAME_ARG" ]; then NAME="$NAME_ARG"; fi
if [ -n "$EMAIL_ARG" ]; then GITMAIL="$EMAIL_ARG"; fi

if [ -z "$NAME" ]; then
  echo ""
  while [ -z "$NAME" ]; do
    ask "👉 Type your name (this is how it appears on your changes) and press Enter: " NAME ||
      missing_option "--name" "your name"
  done
fi

if [ -z "$GITMAIL" ]; then
  if [ -n "$EMAIL" ]; then
    GITMAIL="$EMAIL"
    echo "I'll use the same email you gave for the key: $GITMAIL"
  else
    while ! looks_like_email "$GITMAIL"; do
      [ -n "$GITMAIL" ] && echo "   That doesn't look like an email address. Please try again."
      ask "👉 Type the email of your GitHub account and press Enter: " GITMAIL ||
        missing_option "--email" "the email of your GitHub account"
    done
  fi
fi
if ! git config --global user.name "$NAME" || ! git config --global user.email "$GITMAIL"; then
  echo "❌ Couldn't save your name and email in Git."
  exit 1
fi
echo "✅ Git configured as: $NAME <$GITMAIL>"

# --- Step 8: check the GitHub CLI (gh) and explain how to install it if needed ---
echo ""
echo "Checking whether the GitHub CLI (gh) is installed..."

# gh is available if it's on the PATH and actually runs.
gh_available() {
  GHBIN=$(command -v gh 2>/dev/null)
  [ -n "$GHBIN" ] && "$GHBIN" --version > /dev/null 2>&1
}

# With Homebrew it's one command. Without it, the official installer from
# GitHub, which macOS blocks the first time because it isn't signed yet.
show_gh_steps() {
  echo ""
  if command -v brew > /dev/null 2>&1; then
    if [ "$AGENT" -eq 1 ]; then
      echo "Homebrew is installed, so it takes a single command:   brew install gh"
    else
      echo "You have Homebrew, so it takes a single command:"
      echo ""
      echo "   1. Open another Terminal window (in the Terminal app, press Cmd + N)."
      echo "   2. Paste this command there and press Enter:   brew install gh"
      echo "   3. Wait until it finishes, then come back to this window."
    fi
  else
    echo "The GitHub CLI download page will open in your browser"
    echo "(https://github.com/cli/cli/releases/latest). There you must:"
    echo ""
    echo "   1. Under 'Assets', click the file whose name ends in  macOS_universal.pkg"
    echo "   2. Open the downloaded file (it's in Downloads). macOS will block it the"
    echo "      first time, because GitHub doesn't sign this installer yet. Close that message."
    echo "   3. Open System Settings → Privacy & Security, scroll down and click"
    echo "      'Open Anyway'. Type your Mac password if it asks."
    echo "   4. Follow the installer until it says the installation was successful."
    echo ""
    ask "Press Enter to open the download page..." ENTER
    open "https://github.com/cli/cli/releases/latest"
  fi
}

if gh_available; then
  echo "✅ GitHub CLI is already installed: $("$GHBIN" --version | head -n 1)"
else
  echo ""
  echo "The GitHub CLI (gh) is not installed. It's GitHub's official tool to work with"
  echo "GitHub from the Terminal (your AI assistant can use it too). Let's install it."
  show_gh_steps
  [ "$AGENT" -eq 1 ] && waiting_for "the GitHub CLI to be installed (steps above)"
  echo ""
  while true; do
    ask "When the install has FINISHED, press Enter to check (or type R and Enter to see the steps again, or S and Enter to skip it for now): " RESP ||
      waiting_for "the GitHub CLI to be installed (steps above)"
    if [ "$RESP" = "R" ] || [ "$RESP" = "r" ]; then
      show_gh_steps
      echo ""
      continue
    fi
    if [ "$RESP" = "S" ] || [ "$RESP" = "s" ]; then
      echo "🟡 Skipped. Whenever you want to install it, run  check-github-ssh.sh  to see the steps."
      break
    fi
    if gh_available; then
      echo "✅ GitHub CLI installed: $("$GHBIN" --version | head -n 1)"
      break
    fi
    echo ""
    echo "⚠️  The GitHub CLI still doesn't appear to be installed."
    echo "   - If the installer is still working, wait for it to finish and press Enter again."
    echo "   - If something went wrong, type R and Enter to see the steps again."
    echo "   - If you can't install it now, type S and Enter to skip it."
    echo ""
  done
fi

echo ""
echo "🎉 All set. You can now clone the repository using its SSH address"
echo "   (the one that starts with git@github.com)."
echo ""
exit 0
