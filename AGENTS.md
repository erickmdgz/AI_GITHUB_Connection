# AGENTS.md — Set up this computer for GitHub

**Who this is for:** You are the AI assistant helping **someone** connect their
computer to GitHub. They gave you access to this repository and asked you to
"set up my computer for GitHub." Read this whole file first, then execute the
steps.

Work patiently and explain each action in plain language. The person may not
know what a terminal, key, or commit is — that's expected.

## What you will accomplish

By the end, the person's computer will have:

1. **Git** installed.
2. An **SSH key** (ed25519) generated locally.
3. That key's **public** half registered on their **GitHub account**.
4. **Git identity** configured (`user.name` and `user.email`).
5. A **verified SSH connection** to GitHub.
6. *(Optional)* a repository of their choice **cloned** to their computer.

## Steps you CANNOT do — hand these to the person (human-in-the-loop)

You must **pause and ask them** to do these themselves. Do not claim to have
done them, and never ask for their password or 2FA codes:

- **Signing in to github.com** (username + password).
- **Two-factor authentication (2FA)** approval.
- **Pasting the public SSH key** into GitHub at
  <https://github.com/settings/ssh/new> and clicking **Add SSH key**.
- **Creating the GitHub account** (if they don't have one) at
  <https://github.com/signup>.

Everything else you can either do yourself or generate exact commands for —
depending on whether you can run commands (see the two modes below).

## Before you start — collect this from the person

Ask (do **not** guess or invent these):

- the **email** of their GitHub account, and
- the **display name** they want on their commits (e.g., "Ana López").

If you don't yet know whether it's a Mac or a Windows PC, ask that too.

## Two modes of operation

**Mode A — you can run terminal/shell commands** on their computer (for example,
an agent with a shell, or an IDE assistant with an integrated terminal). Detect
the OS, then either run the ready-made script (fastest) or the explicit commands
in Steps 2–6.

**Mode B — you cannot run commands** (a chat-only assistant). Give the person
the exact commands to copy and paste, **one block at a time, in order**, tell
them what to expect, and wait for them to report the result before moving on.

The sequence of steps and the human-in-the-loop handoffs are identical in both
modes.

---

## Step 1 — Detect the operating system

- **Mac:** `uname` prints `Darwin`; the machine has a **Terminal** app.
- **Windows:** `$env:OS` is `Windows_NT`; the person uses **PowerShell**.

If you can't detect it, ask: "Is this a Mac or a Windows PC?" Then follow the
matching commands in every step.

---

## Fast path (Mode A): run the ready-made script

This repo already includes scripts that perform Steps 2–6 with friendly prompts
and automatic retries. If you can run commands, prefer these:

> **Working directory matters — do not assume it.** The paths below are relative
> to the **repository root** (the folder that contains this `AGENTS.md`). A
> terminal rarely starts there: on Mac it opens in the home folder (`~`), not in
> the repo. So first move into the repo, then run the script. Replace
> `/full/path/to/the/repo` with the actual path (if you cloned it, it's the
> folder `git clone` created; if the person downloaded the ZIP from GitHub, the
> extracted folder is usually named `<repo>-main`).

- **Mac:**
  ```bash
  cd "/full/path/to/the/repo"          # the folder that contains AGENTS.md
  bash scripts/mac/setup-github-ssh.sh
  ```
- **Windows (PowerShell):**
  ```powershell
  cd "C:\full\path\to\the\repo"         # the folder that contains AGENTS.md
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows\lib\setup-github-ssh.ps1
  ```

(Alternatively, pass the script's **full path** instead of `cd`-ing first — either
way, never rely on the terminal's starting directory.)

The script is **interactive**: it asks for the email and name, then opens GitHub
and waits at the key step. Make sure the person can see the terminal and answer
the prompts, and **stop at the browser step** — pasting the key and signing in
are human-in-the-loop tasks. When the script finishes, the machine is connected;
go to **Step 7** only if the person wants to clone a repository.

If you can't run interactive scripts (or you're in Mode B), use the explicit
commands in Steps 2–6 instead. They do the same thing.

---

## Step 2 — Check and install Git

**Mac** — check:
```bash
git --version
```
If it prints a version, Git is installed → go to Step 3. If not, install it:
```bash
xcode-select --install
```
This opens a macOS window. **Ask the person** to click **Install** (not "Get
Xcode"), accept the license, and wait (a few minutes). You cannot click that
button. When it's done, run `git --version` again to confirm.

**Windows (PowerShell)** — check:
```powershell
git --version
```
If missing, install with winget (a permission/UAC window may appear — the
person clicks **Yes**):
```powershell
winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
```
If winget isn't available or fails, ask the person to download Git from
<https://git-scm.com/download/win> and run the installer (**Next** through to
**Install**). After installing, open a **new** PowerShell window so `git` is
found. Also confirm the SSH client is present:
```powershell
Get-Command ssh
```
If it's missing: **Settings → Apps → Optional features → Add a feature →
"OpenSSH Client" → Install**.

## Step 3 — Generate the SSH key (ed25519)

First check whether a key already exists — **do not overwrite** an existing one:

- **Mac:** `ls -la ~/.ssh/id_ed25519.pub`
- **Windows:** `Test-Path "$HOME\.ssh\id_ed25519.pub"`

If it already exists, reuse it and skip to Step 4. Otherwise create it, using
their GitHub **email**:

**Mac:**
```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -t ed25519 -C "USER_EMAIL" -f ~/.ssh/id_ed25519 -N ""
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

**Windows (PowerShell):**
```powershell
if (!(Test-Path "$HOME\.ssh")) { New-Item -ItemType Directory "$HOME\.ssh" | Out-Null }
ssh-keygen -t ed25519 -C "USER_EMAIL" -f "$HOME\.ssh\id_ed25519" -N '""'
```
Note: on **Windows PowerShell 5.1** the empty passphrase must be written
`-N '""'`. On PowerShell 7.3+ use `-N ""`.

Replace `USER_EMAIL` with the email they gave you. `-N ""` means "no
passphrase," which keeps things simple for a newcomer.

## Step 4 — [HUMAN] Add the public key to GitHub

Show them their **public** key. Never display or send the private key (the file
**without** `.pub`).

- **Mac:** `cat ~/.ssh/id_ed25519.pub`
  (optional: `pbcopy < ~/.ssh/id_ed25519.pub` copies it to the clipboard)
- **Windows:** `Get-Content "$HOME\.ssh\id_ed25519.pub"`
  (optional: `Get-Content "$HOME\.ssh\id_ed25519.pub" | Set-Clipboard`)

Then ask them to do this themselves (you cannot):

1. Open <https://github.com/settings/ssh/new> and **sign in** (complete 2FA if
   prompted).
2. **Title:** any name, e.g., "My laptop".
3. **Key:** paste the whole line (it starts with `ssh-ed25519`).
4. Click the green **Add SSH key** button.

**Wait** for them to confirm they clicked **Add SSH key** before you continue.

## Step 5 — Configure Git identity

Same on both systems. Use the name and email they gave you:
```bash
git config --global user.name "USER_NAME"
git config --global user.email "USER_EMAIL"
```

## Step 6 — Test the SSH connection

```bash
ssh -T git@github.com
```
The first time, it asks whether to trust GitHub's fingerprint — they answer
`yes`. (In Mode A you can add `-o StrictHostKeyChecking=accept-new` to answer
automatically.)

**Success looks like:**
```
Hi USERNAME! You've successfully authenticated, but GitHub does not provide shell access.
```
That message **is** success — the "does not provide shell access" part is normal
for GitHub. If you instead see `Permission denied (publickey)`, the key wasn't
added correctly in Step 4 — recheck it and retry.

At this point the computer is connected to GitHub. If the person doesn't need to
download a repository, you're done.

## Step 7 — (Optional) Clone a repository

Only if the person wants to download a specific project from GitHub. Ask them for
its **SSH URL** (on the repo page: green **Code** button → **SSH** tab, the
address starting with `git@github.com:`). Choose a sensible folder (e.g., their
Documents or home folder), then:
```bash
git clone git@github.com:OWNER/PROJECT.git
```
When it finishes, tell them the full path of the new folder. (Cloning a public
repo works right away; pushing changes to a repo you don't own requires its owner
to grant you access first.)

---

## Verify everything (recommended)

A read-only check script confirms all of the above without changing anything.
Run it **from the repository root** (`cd` into the repo first — see the
working-directory note under *Fast path*; the terminal does not start there):

- **Mac:** `bash scripts/mac/check-github-ssh.sh`
- **Windows:** `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\windows\lib\check-github-ssh.ps1`

## Troubleshooting

| Symptom | What to do |
|---|---|
| `Permission denied (publickey)` | The key isn't on GitHub yet. Redo Step 4 (paste the public key and click **Add SSH key**), then retry Step 6. |
| `git: command not found` / "not recognized" | Git isn't installed or the PATH wasn't refreshed. Redo Step 2 and open a **new** terminal/PowerShell window. |
| macOS popup: "command line developer tools" | That's the Git install from Step 2. They click **Install** and wait. |
| `ssh: command not found` (Windows) | Install the **OpenSSH Client** optional feature (Step 2). |
| Wrong email on commits | From the repo root, run `scripts/mac/fix-github-email.sh` (Mac) or `scripts\windows\lib\fix-github-email.ps1` (Windows) — `cd` into the repo first. Or just rerun the two `git config --global` commands from Step 5 (those work from any folder). |
| A key already exists | Reuse the existing `~/.ssh/id_ed25519`. Do **not** overwrite it. |
| The person's tool can't run commands | Switch to **Mode B**: give copy-paste commands one block at a time. |

## Things you must NOT do or invent

- Do not sign in to GitHub, paste the key, or complete 2FA on their behalf —
  always hand those off (see the human-in-the-loop list above).
- Do not ask for or store their password or 2FA codes.
- Never display, copy, or upload the **private** key (`~/.ssh/id_ed25519`
  without `.pub`). Only the `.pub` file is shared with GitHub.
- If a step needs a value they haven't given (email, name, repo URL),
  **ask for it** — don't assume one.
- Don't invent GitHub UI steps or menu names; if the interface differs from
  what's described, tell them what you're looking for and ask them to find the
  closest match.
