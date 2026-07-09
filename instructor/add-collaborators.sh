#!/usr/bin/env bash
# add-collaborators.sh — bulk-invite collaborators to a personal GitHub repo.
#
# Requires the GitHub CLI (https://cli.github.com), logged in as the repo
# owner:  gh auth login
#
# NOTE: the GitHub API only accepts USERNAMES here, not email addresses.
# Put one GitHub username per line in the USERNAMES list below.
set -euo pipefail

# --- Set this to your repository (owner/name) ---
REPO="OWNER/REPO"
# Example only: REPO="jeffeyet/Team-Check-in-TdM-072026-"

USERNAMES=(
  student-github-username-1
  # student-github-username-2
  # student-github-username-3
  # ...
)

# --- Preflight checks (fail with a clear message, not one error per name) ---
command -v gh > /dev/null 2>&1 || {
  echo "ERROR: the GitHub CLI (gh) is not installed — see https://cli.github.com"
  exit 1
}
gh auth status > /dev/null 2>&1 || {
  echo "ERROR: gh is not logged in. Run:  gh auth login"
  exit 1
}
if [ "$REPO" = "OWNER/REPO" ]; then
  echo "Set the REPO variable at the top of this script to your repository (owner/name) first."
  exit 1
fi
if [ "${#USERNAMES[@]}" -eq 0 ]; then
  echo "The USERNAMES list is empty — edit this script and add the usernames first."
  exit 1
fi

for u in "${USERNAMES[@]}"; do
  if ERR=$(gh api -X PUT "repos/$REPO/collaborators/$u" --silent 2>&1); then
    echo "invited: $u"
  else
    echo "FAILED:  $u  — $ERR"
  fi
done

echo
echo "Done. Each person must now accept the invitation (email or github.com/notifications)."
echo "Invitations expire after 7 days."
