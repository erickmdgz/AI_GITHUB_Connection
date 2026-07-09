#!/bin/bash
#
# Fix the email if it was mistyped when running setup-github-ssh.sh
#
# What it does:
#   - Fixes the email Git signs your changes with (this is the important part).
#   - Updates your SSH key's label (this is only cosmetic).
#   - Verifies the connection with GitHub still works.
# It does NOT touch your key, and you don't need to paste it into GitHub again.
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

KEY="$HOME/.ssh/id_ed25519"

echo ""
echo "════════════════════════════════════════════════"
echo "   Fix the email in your configuration"
echo "════════════════════════════════════════════════"
echo ""

# --- Requirement: setup script must have been run before ---
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

if ! git_available; then
  echo "❌ Git is not installed on this Mac."
  echo "   Run the  setup-github-ssh.sh  script first, then this one."
  exit 1
fi

# --- Show what's set right now ---
CURRENT_NAME=$(git config --global user.name 2>/dev/null)
CURRENT_EMAIL=$(git config --global user.email 2>/dev/null)
echo "Current configuration:"
echo "   Name:  ${CURRENT_NAME:-(not set)}"
echo "   Email: ${CURRENT_EMAIL:-(not set)}"
echo ""

# --- Ask for the correct email, with confirmation to avoid another typo ---
while true; do
  NEW=""
  while [ -z "$NEW" ]; do
    read -r -p "👉 Type the CORRECT email of your GitHub account and press Enter: " NEW
  done
  echo ""
  read -r -p "   Confirm the email is  $NEW ?  (type Y for yes, N to type it again): " CONF
  echo ""
  if [ "$CONF" = "Y" ] || [ "$CONF" = "y" ]; then
    break
  fi
done

# --- Fix the Git email (the important part) ---
git config --global user.email "$NEW"
echo "✅ Git email fixed: $NEW"

# --- If the name is missing, set it now too ---
if [ -z "$CURRENT_NAME" ]; then
  NAME=""
  while [ -z "$NAME" ]; do
    read -r -p "👉 Your name is also missing. Type it and press Enter: " NAME
  done
  git config --global user.name "$NAME"
  echo "✅ Name configured: $NAME"
fi

# --- Update the SSH key's label (cosmetic only) ---
if [ -f "$KEY" ]; then
  if ssh-keygen -c -C "$NEW" -f "$KEY" -P "" > /dev/null 2>&1; then
    echo "✅ SSH key label updated."
  else
    echo "🟡 Couldn't update the key label (this does not affect the connection at all)."
  fi
else
  echo "🟡 No SSH key found on this Mac. If you haven't run  setup-github-ssh.sh  yet, run it."
fi

# --- Verify the connection with GitHub still works ---
echo ""
echo "Checking the connection with GitHub..."
RESULT=$(ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 -T git@github.com 2>&1)
if echo "$RESULT" | grep -q "successfully authenticated"; then
  USER=$(echo "$RESULT" | sed -n 's/^Hi \([^!]*\)!.*/\1/p')
  echo "✅ GitHub connection: works. Signed in as: $USER"
else
  echo "⚠️  The GitHub connection didn't work. This is NOT caused by the email;"
  echo "   the key is probably not added on GitHub yet. Run  setup-github-ssh.sh"
fi

echo ""
echo "════════════════════════════════════════════════"
echo "🎉 Done. Your next changes will use the correct email."
echo ""
echo "📝 Last step (in the browser): make sure that email appears in"
echo "   github.com → Settings → Emails. If it isn't there, add it and verify it,"
echo "   so your changes show up linked to your GitHub profile."
echo "════════════════════════════════════════════════"
echo ""
