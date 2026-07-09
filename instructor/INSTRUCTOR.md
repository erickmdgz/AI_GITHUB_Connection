# Instructor guide — Student onboarding kit (AI-driven)

This kit lets each student connect their own computer to GitHub with the help
of **their own AI assistant** (Claude, ChatGPT, Cursor, or GitHub Copilot). The
student gives their AI access to your repository and tells it to follow
`AGENTS.md`; the AI then installs Git, creates an SSH key, configures the Git
identity, tests the connection, and clones the repo — pausing for the few steps
only a human can do (signing in to GitHub, pasting the public key, 2FA).

Everything student-facing is written in **plain English** for people who have
never opened a terminal.

## The moving parts

| File | Who it's for | Purpose |
|---|---|---|
| `README.md` | Student | 5-step, non-technical "give your AI this repo and this message". |
| `AGENTS.md` | The student's **AI** | The full runbook the AI executes step by step. |
| `scripts/mac/` | Mac | `setup` / `check` / `fix` scripts (the AI can run these). |
| `scripts/windows/` | Windows | Same three, as `.bat` launchers + `lib/*.ps1`. |
| `instructor/` | You | This guide + `add-collaborators.sh`. |

The scripts are optional accelerators: if a student's AI can run a terminal, it
runs the matching script; if it can't, `AGENTS.md` gives the AI the exact
commands to hand the student instead.

## How to publish the kit

1. Copy the contents of this folder to the **root of your repository**, on the
   default branch (`main`). Keeping `AGENTS.md` at the repo root matters — most
   AI tools look for it there.
2. **Set the repository URL** in two places:
   - `AGENTS.md` → the `REPO_SSH_URL` line in the *Configuration* block. Replace
     `git@github.com:OWNER/REPO.git` with your repo's SSH URL. (If you leave the
     placeholder, the AI is told to fall back to the URL of the repo it was
     given access to, or to ask the student.)
   - `instructor/add-collaborators.sh` → the `REPO="OWNER/REPO"` line.

   > The example `jeffeyet/Team-Check-in-TdM-072026-` that appears in a few
   > places is only an example — replace it with your own repository.
3. **Fill in the coordinator line** in `README.md` (step 5): who students send
   their username to, and through which channel.
4. Tell students to open the repo, give their AI access to it, and send the
   one-line message from `README.md`.
5. Collect each student's **GitHub username** (a Google Form with name, email,
   and username works well).

## Adding students as collaborators (bulk)

Because this is a personal repository, students can only push after you invite
them as collaborators. With the [GitHub CLI](https://cli.github.com) logged in
as the repo owner (`gh auth login`):

```bash
bash instructor/add-collaborators.sh   # edit the REPO and USERNAMES values first
```
(Run it from the repository root; adjust the path if you're elsewhere.)

The script invites every username in its list and reports each result. Notes:

- The API only accepts **usernames, not emails**. Email→username lookup is
  unreliable (it only works when a student's email is public on their profile).
- Students must **accept** the invitation (email or github.com/notifications).
  Unaccepted invitations expire after 7 days — tell them to accept the same day.
- Collaborators on a personal repo get write access (push, branches, PRs) but
  cannot delete the repo, change settings, or invite others.
- Optional hardening: protect `main` (Settings → Branches → Add rule) so student
  work stays on team branches.

## Optional: manual paths (no AI, or AI without a terminal)

Students without an AI assistant can still use the kit by hand:

- **ZIP:** open the repo page → green **`<> Code`** button → **Download ZIP**,
  then extract it (Mac: double-click the `.zip`; Windows: right-click →
  **Extract All…**). The extracted folder is named after the repository — for a
  GitHub download that's usually **`<repo>-main`**, not a fixed name, so don't
  rely on a specific folder name.
  - **Mac:** Terminal does **not** open inside that folder (it starts in the
    home folder `~`), so point it there first. In Terminal type `cd ` (the
    letters c-d and a **space**), then **drag the extracted folder** from Finder
    onto the Terminal window so its path pastes in, press **Enter**, and only
    then run:
    ```bash
    bash scripts/mac/setup-github-ssh.sh
    ```
    Even simpler (no typing a path): type `bash ` (with a space) and **drag the
    `setup-github-ssh.sh` file itself** onto Terminal, then press Enter.
  - **Windows:** just **double-click** `scripts\windows\setup-github-ssh.bat`
    inside the extracted folder. It locates its own files (via `%~dp0`), so the
    current directory doesn't matter. If SmartScreen appears: **More info → Run
    anyway**.
- **One-line install** (after the kit is on `main`; replace `OWNER/REPO`):

  **Mac** (Terminal):
  ```bash
  curl -fsSL https://raw.githubusercontent.com/OWNER/REPO/main/scripts/mac/setup-github-ssh.sh -o /tmp/kit-github.sh && bash /tmp/kit-github.sh
  ```

  **Windows** (PowerShell — Start menu → type "PowerShell"):
  ```powershell
  iwr -UseBasicParsing https://raw.githubusercontent.com/OWNER/REPO/main/scripts/windows/lib/setup-github-ssh.ps1 -OutFile "$env:TEMP\kit-github.ps1"; powershell -NoProfile -ExecutionPolicy Bypass -File "$env:TEMP\kit-github.ps1"
  ```

  (`-UseBasicParsing` avoids an interactive security prompt on some patched
  Windows PowerShell 5.1 builds.) Both download the script to a file first and
  then run it. Do **not** shorten them to `curl ... | bash` — piping breaks the
  scripts' interactive questions.

## Folder contents

| File | Purpose |
|---|---|
| `add-collaborators.sh` | Bulk-invite collaborators by GitHub username |
| `INSTRUCTOR.md` | This guide |
