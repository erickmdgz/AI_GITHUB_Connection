#!/bin/bash
#
# Connect this Mac to GitHub via SSH.
#
# How to use it:
#   1. Open the "Terminal" app (search for it with Cmd + Space).
#   2. Type:  bash  (with a trailing space)
#   3. Drag this file into the Terminal window and press Enter.
#

# --- Mac only ---
if [ "$(uname)" != "Darwin" ]; then
  echo "❌ This script is for Mac only. On Windows, use the  scripts/windows  folder in this same kit."
  exit 1
fi

KEY="$HOME/.ssh/id_ed25519"

echo ""
echo "════════════════════════════════════════════════"
echo "     Connect this Mac to GitHub (via SSH)"
echo "════════════════════════════════════════════════"
echo ""

# Rare case: the private key exists but the public half is missing.
# Rebuild it so we don't create a brand-new key on top of the existing one.
if [ -f "$KEY" ] && [ ! -f "$KEY.pub" ]; then
  ssh-keygen -y -P "" -f "$KEY" > "$KEY.pub" 2>/dev/null || rm -f "$KEY.pub"
fi

# --- Step 1: check whether a key already exists ---
if [ -f "$KEY" ] && [ -f "$KEY.pub" ]; then
  echo "✅ You already have an SSH key on this Mac. We'll use that one."
else
  echo "You don't have an SSH key yet. Let's create one."
  EMAIL=""
  while [ -z "$EMAIL" ]; do
    read -r -p "👉 Type the email of your GitHub account and press Enter: " EMAIL
  done
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY" -N "" -q
  echo "✅ Key created."
fi

# --- Step 2: load the key and store it in the Mac keychain ---
eval "$(ssh-agent -s)" > /dev/null
ssh-add --apple-use-keychain "$KEY" 2>/dev/null

# Make the key load by itself in the future (after a restart)
CONFIG="$HOME/.ssh/config"
if ! grep -qs "Host github.com" "$CONFIG"; then
  cat >> "$CONFIG" << 'EOF'

Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOF
fi

# --- Step 3: copy the public key to the clipboard ---
pbcopy < "$KEY.pub"
echo "📋 Your public key has been copied to the clipboard."
echo ""

# --- Step 4: add it on GitHub (in the browser) ---
echo "GitHub will now open in your browser. There you must:"
echo ""
echo "   1. Sign in if prompted."
echo "   2. In the 'Title' field type a name, for example: My Mac"
echo "   3. In the big 'Key' field paste the key with Cmd + V"
echo "   4. Click the green 'Add SSH key' button"
echo ""
read -r -p "Press Enter to open GitHub..."
open "https://github.com/settings/ssh/new"
echo ""
read -r -p "Once you've clicked 'Add SSH key', come back here and press Enter..."

# --- Step 5: verify the connection ---
echo ""
echo "Checking the connection with GitHub..."
while true; do
  RESULT=$(ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 -T git@github.com 2>&1)
  if echo "$RESULT" | grep -q "successfully authenticated"; then
    echo ""
    echo "🎉 Done! Your Mac is now connected to GitHub."
    echo "   GitHub replied: $(echo "$RESULT" | grep "successfully" )"
    break
  else
    echo ""
    echo "⚠️  Not working yet. GitHub replied:"
    echo "----------------------------------------"
    echo "$RESULT"
    echo "----------------------------------------"
    echo "Make sure you pasted the key and clicked 'Add SSH key' in the browser."
    read -r -p "Press Enter to try again (or Ctrl + C to quit)..."
  fi
done

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
  read -r -p "Press Enter to open the install window..."
  xcode-select --install 2>/dev/null || true
  echo ""
  while true; do
    read -r -p "When the install has FINISHED, press Enter to check (or type R and Enter if you cancelled the window and want to open it again): " RESP
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

if [ -z "$NAME" ]; then
  echo ""
  while [ -z "$NAME" ]; do
    read -r -p "👉 Type your name (this is how it appears on your changes) and press Enter: " NAME
  done
  git config --global user.name "$NAME"
fi

if [ -z "$GITMAIL" ]; then
  if [ -n "$EMAIL" ]; then
    GITMAIL="$EMAIL"
    echo "I'll use the same email you gave for the key: $GITMAIL"
  else
    while [ -z "$GITMAIL" ]; do
      read -r -p "👉 Type the email of your GitHub account and press Enter: " GITMAIL
    done
  fi
  git config --global user.email "$GITMAIL"
fi
echo "✅ Git configured as: $NAME <$GITMAIL>"

echo ""
echo "🎉 All set. You can now clone the repository using its SSH address"
echo "   (the one that starts with git@github.com)."
echo ""
