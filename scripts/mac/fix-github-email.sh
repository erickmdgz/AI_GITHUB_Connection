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
# For AI agents -- no questions:
#   bash fix-github-email.sh --agent --email "you@example.com" [--name "Your Name"]
#

# --- Mac only ---
if [ "$(uname)" != "Darwin" ]; then
  echo "❌ This script is for Mac only."
  exit 1
fi

# --- Options (a person running the script doesn't need any) ---
USAGE='Usage: bash fix-github-email.sh [--agent] [--email "you@example.com"] [--name "Your Name"]'
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

# In agent mode a missing answer can't be asked for: it has to come as an option.
missing_option() {
  echo ""
  echo "❌ Missing $2. Run the script again adding:  $1 \"...\""
  exit 1
}

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

# --- The correct email: given as an option, or asked with confirmation to avoid another typo ---
NEW="$EMAIL_ARG"
while [ -z "$NEW" ]; do
  CANDIDATE=""
  while ! looks_like_email "$CANDIDATE"; do
    [ -n "$CANDIDATE" ] && echo "   That doesn't look like an email address. Please try again."
    ask "👉 Type the CORRECT email of your GitHub account and press Enter: " CANDIDATE ||
      missing_option "--email" "the correct email"
  done
  echo ""
  ask "   Confirm the email is  $CANDIDATE ?  (type Y for yes, N to type it again): " CONF ||
    missing_option "--email" "the correct email"
  echo ""
  if [ "$CONF" = "Y" ] || [ "$CONF" = "y" ]; then
    NEW="$CANDIDATE"
  fi
done

# --- Fix the Git email (the important part) ---
if ! git config --global user.email "$NEW"; then
  echo "❌ Couldn't save the email in Git."
  exit 1
fi
echo "✅ Git email fixed: $NEW"

# --- Set the name if it was given, or if it's missing ---
NAME="$NAME_ARG"
if [ -z "$NAME" ] && [ -z "$CURRENT_NAME" ]; then
  while [ -z "$NAME" ]; do
    ask "👉 Your name is also missing. Type it and press Enter: " NAME ||
      missing_option "--name" "your name"
  done
fi
if [ -n "$NAME" ]; then
  git config --global user.name "$NAME"
  echo "✅ Name configured: $NAME"
fi

# --- Update the SSH key's label (cosmetic only) ---
if [ -f "$KEY" ]; then
  if ssh-keygen -c -C "$NEW" -f "$KEY" -P "" < /dev/null > /dev/null 2>&1; then
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
BATCH=""
[ "$AGENT" -eq 1 ] && BATCH="-o BatchMode=yes"
RESULT=$(ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 $BATCH -T git@github.com 2>&1)
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
