# AGENTS.md — Set up this computer for GitHub

**Who this is for:** You are the AI assistant helping **someone** connect their
computer to GitHub. They gave you this kit — usually just its link,
<https://github.com/erickmdgz/AI_GITHUB_Connection>, sometimes its folder on
their disk — and asked you to "set up my computer for GitHub." Read this whole
file first, then do the work **for them**: run the commands yourself and hand
over only the steps that need a human (listed below).

Work patiently and explain each action in plain language. The person may not
know what a terminal, key, or commit is — that's expected.

## What you will accomplish

By the end, the person's computer will have:

1. **Git** installed.
2. An **SSH key** (ed25519) generated locally.
3. That key's **public** half registered on their **GitHub account**.
4. **Git identity** configured (`user.name` and `user.email`).
5. A **verified SSH connection** to GitHub.
6. The **GitHub CLI** (`gh`) installed.
7. *(Optional)* a repository of their choice **cloned** to their computer.

## Steps you CANNOT do — hand these to the person (human-in-the-loop)

You must **pause and ask them** to do these themselves. Do not claim to have
done them, and never ask for their password or 2FA codes:

- **Signing in to github.com** (username + password).
- **Two-factor authentication (2FA)** approval.
- **Pasting the public SSH key** into GitHub at
  <https://github.com/settings/ssh/new> and clicking **Add SSH key**.
- **Creating the GitHub account** (if they don't have one) at
  <https://github.com/signup>.
- **Clicking the system windows that installs open:** **Install** in the macOS
  "command line developer tools" window, **Yes** in Windows permission (UAC)
  prompts, and the buttons of a downloaded installer — including unblocking the
  GitHub CLI installer on a Mac without Homebrew (**Open Anyway** in System
  Settings, with their Mac password typed into macOS, never to you).

Everything else you can either do yourself or generate exact commands for —
depending on whether you can run commands (see the two modes below).

## Before you start — collect this from the person

Ask (do **not** guess or invent these):

- the **email** of their GitHub account, and
- the **display name** they want on their commits (e.g., "Ana López").

If you don't yet know whether it's a Mac or a Windows PC, ask that too. Then
tell them in a sentence or two what's coming: you'll run the setup, a GitHub
page will open where they paste a key, and you may need them to click a button
or two.

## Two modes of operation

**Mode A — you can run terminal/shell commands** on their computer (for example,
an agent with a shell, or an IDE assistant with an integrated terminal). Run the
ready-made setup script in agent mode (*Fast path* below); the explicit commands
in Steps 2–7 are the fallback.

**Mode B — you cannot run commands** (a chat-only assistant). Give the person
the exact commands from Steps 2–7 to copy and paste, **one block at a time, in
order**, tell them what to expect, and wait for them to report the result
before moving on.

The sequence of steps and the human-in-the-loop handoffs are identical in both
modes.

---

## Step 1 — Detect the operating system

- **Mac:** `uname` prints `Darwin`; the machine has a **Terminal** app.
- **Windows:** `$env:OS` is `Windows_NT`; the person uses **PowerShell**. Some
  agents run commands in **Git Bash** on Windows instead (`uname` then prints
  something starting with `MINGW` or `MSYS`): that's still Windows, so use the
  Windows commands and run the PowerShell scripts through `powershell.exe`.

If you can't detect it, ask: "Is this a Mac or a Windows PC?" Then follow the
matching commands in every step.

---

## Fast path (Mode A): run the setup script in agent mode

The kit has one setup script per system that does Steps 2–7. Run it **in agent
mode** (`--agent` on Mac, `-Agent` on Windows): it never asks a question or
waits for Enter — you pass the email and name as options — and its **exit
code** tells you what to do next:

| Exit code | Meaning | What you do |
|---|---|---|
| `0` | Everything is done. | Confirm with the check script (point 4 below). |
| `2` | It's waiting for a step. Its last lines say which (`⏸  Waiting for: ...`), with the instructions above them. | If the person has to do it, relay the instructions and wait until they confirm. If it's the GitHub CLI, install it yourself (Step 7). Then run **the same command again**. |
| `1` | Error: a missing or wrong option, or GitHub can't be reached. | Read the output, fix the cause (see *Troubleshooting*), and run it again. |

Running it again is always safe: it skips whatever is already done, and it
never overwrites an existing SSH key. The setup needs to reach github.com: if
your commands can't access the internet (some apps sandbox them), ask the
person to allow network access for this task.

**1. Get the scripts.** If the kit's folder is on disk (the one that contains
this `AGENTS.md`), use its `scripts/` folder. If you only have the link,
download the two scripts into the current working folder — no Git needed:

- **Mac:**
  ```bash
  curl -fsSLO https://raw.githubusercontent.com/erickmdgz/AI_GITHUB_Connection/main/scripts/mac/setup-github-ssh.sh
  curl -fsSLO https://raw.githubusercontent.com/erickmdgz/AI_GITHUB_Connection/main/scripts/mac/check-github-ssh.sh
  ```
- **Windows** (the same lines work in PowerShell and in Git Bash):
  ```powershell
  curl.exe -fsSLO https://raw.githubusercontent.com/erickmdgz/AI_GITHUB_Connection/main/scripts/windows/lib/setup-github-ssh.ps1
  curl.exe -fsSLO https://raw.githubusercontent.com/erickmdgz/AI_GITHUB_Connection/main/scripts/windows/lib/check-github-ssh.ps1
  ```

**2. Run the setup** from the folder where the scripts are. In the kit's folder
they're `scripts/mac/setup-github-ssh.sh` and
`scripts\windows\lib\setup-github-ssh.ps1`; never assume the terminal starts
there.

- **Mac:**
  ```bash
  bash setup-github-ssh.sh --agent --email "USER_EMAIL" --name "USER_NAME"
  ```
- **Windows** — first warn the person that a Windows permission window may
  appear and they should click **Yes**:
  ```powershell
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File setup-github-ssh.ps1 -Agent -Email "USER_EMAIL" -Name "USER_NAME"
  ```

**3. Repeat while it exits with `2`** (see the table). On a brand-new computer
expect up to three rounds — adding the key on GitHub, installing Git, and
installing the GitHub CLI — each one needing the person (or you) before the
next run.

**4. Confirm** with the check script. It changes nothing: exit code `0` means
everything is ready, `1` means something is missing (the lines marked ❌ say
what).

- **Mac:** `bash check-github-ssh.sh`
- **Windows:** `powershell.exe -NoProfile -ExecutionPolicy Bypass -File check-github-ssh.ps1 -Agent`

Without `--agent` / `-Agent` the scripts are interactive: they're meant for a
person typing in a terminal, so don't run them that way from a shell where the
person can't type. If you can't run the scripts at all, use the explicit
commands in Steps 2–7 instead; they do the same thing.

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

**Mac** (and Git Bash on Windows):
```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -t ed25519 -C "USER_EMAIL" -f ~/.ssh/id_ed25519 -N ""
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```
(The last two lines are for the Mac only.)

**Windows (PowerShell):**
```powershell
if (!(Test-Path "$HOME\.ssh")) { New-Item -ItemType Directory "$HOME\.ssh" | Out-Null }
if ($PSVersionTable.PSVersion -ge [version]"7.3") { $nopass = "" } else { $nopass = '""' }
ssh-keygen -t ed25519 -C "USER_EMAIL" -f "$HOME\.ssh\id_ed25519" -N $nopass
```
The second line matters: PowerShell 5.1 needs `'""'` to pass an empty
passphrase, while 7.3+ takes `""` — and `'""'` on 7.3+ would set a passphrase
made of two quote characters.

Replace `USER_EMAIL` with the email they gave you. An empty `-N` means "no
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
ssh -o StrictHostKeyChecking=accept-new -T git@github.com
```
The first time, ssh asks whether to trust GitHub's fingerprint;
`StrictHostKeyChecking=accept-new` answers it automatically. (A person typing
the plain `ssh -T git@github.com` answers `yes`.)

**Success looks like:**
```
Hi USERNAME! You've successfully authenticated, but GitHub does not provide shell access.
```
That message **is** success — the "does not provide shell access" part is normal
for GitHub, and so is the exit code `1` that comes with it. If you instead see
`Permission denied (publickey)`, the key wasn't added correctly in Step 4 —
recheck it and retry.

At this point the computer is connected to GitHub. Continue with Step 7.

## Step 7 — Check and install the GitHub CLI (`gh`)

The GitHub CLI is GitHub's official command-line tool: with it, the person (and
you) can work with GitHub from the terminal — create repositories, open pull
requests, and so on. Check whether it's installed (same command on both
systems):
```bash
gh --version
```
If it prints a version (`gh version 2.x.x ...`), it's installed → go to Step 8.
If not, install it:

**Mac** — if Homebrew is installed (`brew --version` prints a version), use it
(it's one of GitHub's official install methods):
```bash
brew install gh
```
Without Homebrew, use GitHub's official installer. You can open the download
page for them (`open "https://github.com/cli/cli/releases/latest"`); then
**ask the person** to:

1. Under **Assets**, click the file whose name ends in `_macOS_universal.pkg`.
2. Open the downloaded file. macOS blocks it the first time, because GitHub
   doesn't sign this installer yet
   ([cli/cli#9139](https://github.com/cli/cli/issues/9139)). They close the
   warning.
3. Open **System Settings → Privacy & Security**, scroll down and click
   **Open Anyway** (Apple shows that button for about an hour after the blocked
   attempt), then type their Mac password into the macOS window — never to you.
4. Follow the installer until it says the installation was successful.

**Windows (PowerShell)** — install with winget (a permission/UAC window may
appear — the person clicks **Yes**):
```powershell
winget install --id GitHub.cli -e --source winget --accept-package-agreements --accept-source-agreements
```
If winget isn't available or fails, ask the person to open
<https://github.com/cli/cli/releases/latest>, download the file under
**Assets** that ends in `_windows_amd64.msi` (`_windows_arm64.msi` on PCs with
an ARM processor), open it and click **Next** through to **Install**, then
**Finish**. Afterwards, open a **new** PowerShell window so `gh` is found (in
Windows Terminal, a new tab is not enough). If you're running the commands
yourself, you can instead refresh the PATH of your current session:
```powershell
$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User") + ";" + $env:Path
```

Run `gh --version` again to confirm.

This kit only installs the GitHub CLI. Signing it in to their account
(`gh auth login`) is a separate step that needs the person in the browser — do
it only if they ask.

## Step 8 — (Optional) Clone a repository

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
Run it from the folder where it is (the kit's `scripts/` folder, or where you
downloaded it in the *Fast path*); exit code `0` means everything is ready:

- **Mac:** `bash check-github-ssh.sh` (in the kit: `bash scripts/mac/check-github-ssh.sh`)
- **Windows:** `powershell.exe -NoProfile -ExecutionPolicy Bypass -File check-github-ssh.ps1 -Agent`
  (in the kit: `scripts\windows\lib\check-github-ssh.ps1`)

## Troubleshooting

| Symptom | What to do |
|---|---|
| `Permission denied (publickey)` | The key isn't on GitHub yet. Redo Step 4 (paste the public key and click **Add SSH key**), then retry Step 6. |
| `git: command not found` / "not recognized" | Git isn't installed or the PATH wasn't refreshed. Redo Step 2 and open a **new** terminal/PowerShell window. |
| macOS popup: "command line developer tools" | That's the Git install from Step 2. They click **Install** and wait. |
| `ssh: command not found` (Windows) | Install the **OpenSSH Client** optional feature (Step 2). |
| `gh: command not found` / "not recognized" | The GitHub CLI isn't installed, or the terminal was opened before installing it. Do Step 7, then open a **new** terminal/PowerShell window (in Windows Terminal, a new tab isn't enough). |
| macOS won't open the GitHub CLI installer (`…_macOS_universal.pkg`) | Expected: GitHub doesn't sign that installer yet. **System Settings → Privacy & Security → Open Anyway**, then open it again (Step 7). If Homebrew is installed, `brew install gh` avoids it. |
| The setup exits with `1` and says `Missing ... Run the setup again adding: --email "..."` (or `--name`, `-Email`, `-Name`) | Add that option with the value the person gave you and run it again. |
| The setup says it can't reach GitHub, or ssh shows `Connection timed out` / `Could not resolve hostname` | A network problem, not the key: check the internet connection. Some networks (many offices) block SSH's port 22; GitHub also accepts SSH on port 443 — add `Hostname ssh.github.com`, `Port 443` and `User git` under `Host github.com` in `~/.ssh/config` ([GitHub's guide](https://docs.github.com/en/authentication/troubleshooting-ssh/using-ssh-over-the-https-port)). |
| `REMOTE HOST IDENTIFICATION HAS CHANGED` / `Host key verification failed` for github.com | GitHub replaced its RSA host key in March 2023 ([announcement](https://github.blog/2023-03-23-we-updated-our-rsa-ssh-host-key/)). Remove the old entry with `ssh-keygen -R github.com` and test again (Step 6). |
| The setup waits for "the public key to be rebuilt" | There's an older key with a passphrase whose `.pub` file is missing. The person runs the command the setup shows and types their passphrase; you never see it. Then run the setup again. |
| Wrong email on commits | Rerun the two `git config --global` commands from Step 5 (they work from any folder). Or use the kit's fix script: `bash scripts/mac/fix-github-email.sh --agent --email "..."` (Mac) or `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\windows\lib\fix-github-email.ps1 -Agent -Email "..."` (Windows), from the kit's folder. |
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
- Don't run the scripts without `--agent` / `-Agent` from a shell the person
  can't type into: they would wait for answers that never come.
- Don't invent GitHub UI steps or menu names; if the interface differs from
  what's described, tell them what you're looking for and ask them to find the
  closest match.
