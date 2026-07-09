#!/bin/bash
#
# Check that this Mac is properly connected to GitHub over SSH.
# This script changes NOTHING: it only inspects and reports each point.
#
# How to use it:
#   1. Open the "Terminal" app (search for it with Cmd + Space).
#   2. Type:  bash  (with a trailing space) -- do NOT press Enter yet.
#   3. Drag this file into the Terminal window and press Enter.
# (Dragging the file passes its full path, so it works no matter which folder
#  Terminal opened in.)
#

# --- Mac only ---
if [ "$(uname)" != "Darwin" ]; then
  echo "❌ This script is for Mac only."
  exit 1
fi

PROBLEMS=0

echo ""
echo "════════════════════════════════════════════════"
echo "   Checking the connection with GitHub"
echo "════════════════════════════════════════════════"
echo ""

# --- 1. Does the SSH key exist? ---
KEY="$HOME/.ssh/id_ed25519"
if [ -f "$KEY" ] && [ -f "$KEY.pub" ]; then
  echo "✅ 1. SSH key: exists (id_ed25519)"
elif ls "$HOME"/.ssh/*.pub > /dev/null 2>&1; then
  echo "🟡 1. SSH key: you have a key, but with a different name:"
  ls "$HOME"/.ssh/*.pub
  echo "      (it may work, but it isn't the one our script creates)"
else
  echo "❌ 1. SSH key: does not exist."
  echo "      → Run the  setup-github-ssh.sh  script"
  PROBLEMS=$((PROBLEMS + 1))
fi
echo ""

# --- 2. Is it configured so the key loads by itself? ---
if grep -qs "Host github.com" "$HOME/.ssh/config"; then
  echo "✅ 2. SSH config: ready (the key loads by itself after a restart)"
else
  echo "🟡 2. SSH config: the config file is missing."
  echo "      Not serious, but  setup-github-ssh.sh  sets it up for you."
fi
echo ""

# --- 3. Does the connection to GitHub work? ---
echo "   Testing the connection with GitHub (may take a few seconds)..."
RESULT=$(ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 -T git@github.com 2>&1)
if echo "$RESULT" | grep -q "successfully authenticated"; then
  USER=$(echo "$RESULT" | sed -n 's/^Hi \([^!]*\)!.*/\1/p')
  echo "✅ 3. GitHub connection: works. Signed in as: $USER"
else
  echo "❌ 3. GitHub connection: failed. GitHub replied:"
  echo "----------------------------------------"
  echo "$RESULT"
  echo "----------------------------------------"
  echo "      → Check that you added the key at github.com → Settings → SSH and GPG keys"
  PROBLEMS=$((PROBLEMS + 1))
fi
echo ""

# --- 4 and 5. Is Git installed and configured? ---
GIT_OK=0
if xcode-select -p > /dev/null 2>&1; then
  GIT_OK=1
else
  # Git installed some other way (e.g., Homebrew), not the macOS prompt
  GITBIN=$(command -v git 2>/dev/null)
  if [ -n "$GITBIN" ] && [ "$GITBIN" != "/usr/bin/git" ] && "$GITBIN" --version > /dev/null 2>&1; then
    GIT_OK=1
  fi
fi

if [ "$GIT_OK" -eq 1 ]; then
  echo "✅ 4. Git installed: $(git --version)"
  echo ""

  NAME=$(git config --global user.name 2>/dev/null)
  GITMAIL=$(git config --global user.email 2>/dev/null)
  if [ -n "$NAME" ] && [ -n "$GITMAIL" ]; then
    echo "✅ 5. Git configured: $NAME <$GITMAIL>"
  else
    echo "❌ 5. Git configured: your name or email is missing. Run these two commands:"
    echo '      git config --global user.name "Your Name"'
    echo '      git config --global user.email "your-email@example.com"'
    PROBLEMS=$((PROBLEMS + 1))
  fi
else
  echo "❌ 4. Git installed: no."
  echo "      → Run the  setup-github-ssh.sh  script (it now installs Git too),"
  echo "        or run this command directly and accept the install:  xcode-select --install"
  echo ""
  echo "❌ 5. Git configured: pending (install Git first, point 4)."
  PROBLEMS=$((PROBLEMS + 2))
fi
echo ""

# --- Summary ---
echo "════════════════════════════════════════════════"
if [ "$PROBLEMS" -eq 0 ]; then
  echo "🎉 All set. This Mac can already work with GitHub."
else
  echo "⚠️  There are $PROBLEMS point(s) to fix — look for the ❌ above."
fi
echo "════════════════════════════════════════════════"
echo ""
