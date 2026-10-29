# Connect your computer to GitHub — with your AI assistant

> **AI agent reading this?** Your instructions are in [`AGENTS.md`](AGENTS.md)
> (plain text: <https://raw.githubusercontent.com/erickmdgz/AI_GITHUB_Connection/main/AGENTS.md>).
> Follow that file; this README is for the person.

You don't need to know how to code, and you don't need to open a terminal or
type any commands yourself. You open one AI app, give it the link to this page,
and it does the setup for you — it just asks you to click **Approve** along the
way.

By the end, your computer will be connected to GitHub: Git installed, an SSH key
created and registered on your account, your Git identity set, the connection
verified, and the GitHub CLI (`gh`, GitHub's command-line tool) installed.

## What you'll need

- **A GitHub account.** If you don't have one, create it at
  [github.com/signup](https://github.com/signup). You'll sign in near the end.
- **One AI app** — pick the one you already have, or one of the free ones if
  you're starting fresh:

| App | Cost | Works on |
|---|---|---|
| **Claude** desktop app — the *Code* tab | Paid Claude plan | Mac, Windows |
| **ChatGPT** — the *Codex* app | Paid ChatGPT plan (or API key) | Mac, Windows |
| **Cursor** | Free tier | Mac, Windows |
| **VS Code + GitHub Copilot** | Free tier | Mac, Windows |

All four work the same way: you send it one message with the link, and approve
each step. None of them make *you* type terminal commands.

## Step 1 — Open your AI app in a folder

These apps work inside a folder on your computer. Any folder is fine — for
example your **Documents** folder; the AI saves two small setup files there.
Find your app below and follow its steps. If a menu name looks slightly
different in your version, look for the closest match.

### Claude — desktop app *(needs a paid Claude plan)*

1. Install the Claude desktop app and sign in. Get it from the
   [download page](https://code.claude.com/docs/en/desktop-quickstart) (Mac and
   Windows), then open it from **Applications** (Mac) or the **Start menu**
   (Windows).
2. **Windows only:** install **Git for Windows** first from
   [git-scm.com/downloads/win](https://git-scm.com/downloads/win) (run the
   installer, click **Next** through to **Install**), then restart Claude. On
   Windows the Code tab won't open a local project until Git is present. (Most
   Macs already have Git.)
3. Click the **Code** tab at the top center. (If it asks you to upgrade, the
   Code tab needs a paid plan.)
4. Choose **Local**, click **Select folder**, and pick a folder (for example,
   **Documents**).
5. Continue to **Step 2**. Claude shows each action and waits — click **Accept**
   to approve it.

### ChatGPT — the Codex app *(needs a paid ChatGPT plan)*

1. Install the **Codex app** from
   [developers.openai.com/codex/app](https://developers.openai.com/codex/app)
   (Mac download, or the Microsoft Store on Windows) and sign in with your
   ChatGPT account. This needs a paid ChatGPT plan (Plus / Pro / Business / Edu /
   Enterprise) or an OpenAI API key.
2. In Codex, open a folder (for example, **Documents**) as the project folder.
3. Make sure **Local** (run on your computer) is selected, not a cloud option.
4. Continue to **Step 2**; approve each action when it asks.

> This is the **Codex** app, not the regular ChatGPT chat. The normal ChatGPT
> window can read files but can't run the setup on your computer.

### Cursor *(free tier available)*

1. Install Cursor from [cursor.com](https://cursor.com) and open it.
2. In the menu bar, choose **File → Open Folder** and select a folder (for
   example, **Documents**).
3. Open the AI chat panel (on the right) and make sure it's set to **Agent**
   mode.
4. Continue to **Step 2**; when it wants to run a command, click **Run** /
   **Accept**.

### VS Code + GitHub Copilot *(free tier available)*

1. Install VS Code from
   [code.visualstudio.com](https://code.visualstudio.com). Click the **Copilot**
   icon and sign in with your GitHub account (the free tier is enough to start).
2. Choose **File → Open Folder** and select a folder (for example,
   **Documents**).
3. Open **Copilot Chat** (the Copilot icon), then switch the mode dropdown to
   **Agent**.
4. Continue to **Step 2**; approve terminal commands when prompted.

## Step 2 — Give it the link

In your app's chat box, send this message:

> Set up my computer for GitHub by following the instructions at https://github.com/erickmdgz/AI_GITHUB_Connection

*(If you also want to download a specific project afterward, add: "then clone it
from `<the project's SSH URL>`".)*

## Step 3 — Answer its questions and do the few steps only you can do

Your AI will ask you for:

- the **email** of your GitHub account, and
- the **name** you want shown on your work (e.g., "Ana López").

As it works, **approve each action** it shows you (**Accept** / **Run**). At one
point it will display a **"public key"** and ask you to:

- **paste that key into your GitHub account** in the browser, and
- **sign in to GitHub and approve two-factor authentication (2FA)**.

**Only you can do those** — your AI cannot sign in to your account for you.
Follow its on-screen instructions, then tell it when you're done so it can
continue.

It may also ask you to click a button in a window that an installer opens:
**Install** on a Mac, or **Yes** on Windows when it asks for permission.

At the end it checks the **GitHub CLI**. If it's missing, your AI installs it or
shows you the steps. On a Mac without Homebrew you'll download an installer that
macOS blocks the first time — that's expected: open **System Settings → Privacy
& Security**, click **Open Anyway**, and type your Mac password.

## Step 4 — Done

Your computer is now connected to GitHub. Your AI can confirm it with the
read-only check described in `AGENTS.md`.

## If something doesn't work

Tell your AI what happened, or paste the exact error message it showed you — it
can re-read `AGENTS.md` and walk you through the fix.

## Prefer to download the kit?

If your AI app can't open web links, or you'd rather run the setup yourself:

1. At the top of this page, click the green **`<> Code`** button (just above the
   list of files), then click **Download ZIP**. Open it from your **Downloads**
   folder — **Mac:** double-click the `.zip` file; **Windows:** right-click it →
   **Extract All…** → **Extract**. You get a folder named
   **`AI_GITHUB_Connection-main`**.
2. Then either:
   - open that folder in your AI app (Step 1) and send: *"Follow `AGENTS.md` in
     this project to set up my computer for GitHub."*, or
   - run the setup yourself, without an AI. **Mac:** open the **Terminal** app,
     type `bash ` (with a trailing space), drag the file
     `scripts/mac/setup-github-ssh.sh` into the window and press Enter.
     **Windows:** double-click `scripts\windows\setup-github-ssh.bat` (if
     Windows shows "Windows protected your PC", click **More info** and then
     **Run anyway**).

---

*The technical setup instructions your AI follows are in `AGENTS.md`.*
