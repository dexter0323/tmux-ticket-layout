# tmux-ticket-layout

**One keybind. One ticket. Everything you need already open.**

---

## The Problem

tmux might not be new for some of you — but here's why I ended up needing it.

As we move faster with AI, I kept running into the same problem: Claude or Cursor is executing something in my terminal and I'm blocked. I can't work on anything else. So I started using **git worktrees** — separate checkouts per ticket so an agent can run in one while I write code in another.

But then a new problem: I'd come back to a worktree and have to rebuild my context from scratch. Which pane was running what? Did I already pull secrets? Was the dev server up? I was spending more time reconstructing my terminal than actually working.

So I added **tmux sessions** — one per ticket, named after the ticket ID. `tmux ls` tells you exactly what's in flight. Come back the next day, attach, and you're exactly where you left off.

But starting each session was still 4 manual commands every time. So I built a layout: **one keybind (`prefix + W`)**, type the ticket ID, and the whole environment comes up automatically:

- Worktree created automatically if it doesn't exist
- Secrets / init script staged in a pane, awaiting your Enter
- AI agent (Claude or whatever you use) already running in the main pane
- Build pane ready in the right column

Safe to run any time — if the session already exists it just re-attaches.

One thing I like a lot: **I keep Claude inside the worktree**. Each session has its own Claude, its own branch, its own secrets. No stray chats accumulating across tickets, and you can pre-load it with the ticket context so it starts planning before you type the first line.

---

## What You Get

```
┌─────────────────────┬─────────────────────┐
│                     │  pane 2: secrets /  │
│  pane 1: AI agent   │  init (staged*)     │
│  (claude -r)        ├─────────────────────┤
│                     │  pane 3: companion  │
│  runs in worktree   │  repo (staged*)     │
│                     ├─────────────────────┤
│                     │  pane 4: build      │
│                     │  (staged*)          │
└─────────────────────┴─────────────────────┘
         Session name = ticket ID
```

**Staged\*** = command is typed and ready but waits for your `Enter`. You control when secrets are fetched or builds run.

Panes 3 and 4 are optional — the installer lets you configure exactly what you need.

---

## Quick Start

```bash
curl -fsSL https://gitlab.com/juan.sanchez.ctr/tmux-ticket-layout/-/raw/main/install.sh | bash
```

Or clone and run:

```bash
git clone https://gitlab.com/juan.sanchez.ctr/tmux-ticket-layout
cd tmux-ticket-layout
bash install.sh
```

The installer will ask a few questions (your repo path, what commands to run in each pane) and generate `~/.config/tmux/layout.sh` for you.

---

## Usage

```bash
tw TICKET-123          # from your shell (if alias was installed)
```

Or from inside tmux: `prefix + W`, then type the ticket ID.

```bash
tmux ls                # see all in-flight sessions
tw TICKET-123          # re-attach to an existing session (idempotent)
```

---

## How It Works

- `install.sh` asks you questions and generates `~/.config/tmux/layout.sh` from `layout.template.sh`
- `layout.sh` is machine-local (not in git) — it contains your specific paths and commands
- `launch-layout.sh` is the dispatcher: uses your `layout.sh` if present, falls back to `work-layout.sh`
- `prefix + W` in tmux calls `launch-layout.sh` via `command-prompt`

```
prefix + W  →  launch-layout.sh <ticket-id>
                 └→ layout.sh (your machine-local config)
                      └→ creates worktree + session + panes
```

---

## Customization

**Re-run the installer** to regenerate `layout.sh` with new answers (backs up the old one automatically):

```bash
bash install.sh
```

**Edit `~/.config/tmux/layout.sh` directly** — it's plain bash. The installer backs it up before overwriting, so you won't lose changes if you re-run.

**Non-interactive mode** — set env vars and skip all prompts:

```bash
TMUX_LAYOUT_NONINTERACTIVE=1 \
TMUX_LAYOUT_PROJECT_ROOT=~/dev/my-project \
TMUX_LAYOUT_PANE1_CMD="cursor ." \
TMUX_LAYOUT_PANE2_CMD="bash scripts/secrets.sh" \
bash install.sh
```

| Variable | Default | Description |
|---|---|---|
| `TMUX_LAYOUT_PROJECT_ROOT` | (required) | Absolute path to your main git repo |
| `TMUX_LAYOUT_WORKTREE_BASE` | `$PROJECT_ROOT/.worktrees` | Where worktrees are created |
| `TMUX_LAYOUT_PANE1_CMD` | `claude -r` | Command to run in the main left pane |
| `TMUX_LAYOUT_SHELL_HELPERS` | (empty) | Shell helpers file to `source` before pane 1 cmd |
| `TMUX_LAYOUT_PANE2_CMD` | (empty) | Command staged in top-right pane |
| `TMUX_LAYOUT_PANE3_DIR` / `_CMD` | (empty = pane omitted) | Middle-right pane |
| `TMUX_LAYOUT_PANE4_DIR` / `_CMD` | (empty = pane omitted) | Bottom-right pane |
| `TMUX_LAYOUT_TMUX_MODE` | `a` | `a`=full tmux.conf, `b`=keybind only, `c`=skip |
| `TMUX_LAYOUT_TW_ALIAS` | `yes` | Add `tw` alias to shell config |

See `examples/` for filled-in layout scripts you can copy and adapt.

---

## Prerequisites

| Tool | Notes |
|---|---|
| tmux ≥ 3.0 | Installed automatically if Homebrew or apt is available |
| git ≥ 2.5 | For `git worktree` support |
| Homebrew | macOS — used to install tmux and gum if missing |
| gum | Optional — used for the interactive installer UI; falls back to plain prompts |

---

## tmux Plugins

The full `tmux.conf` (install mode `a`) includes these plugins via [TPM](https://github.com/tmux-plugins/tpm):

| Plugin | What it does |
|---|---|
| tmux-sensible | Sane defaults |
| tmux-resurrect | Restore sessions after reboot |
| tmux-continuum | Auto-save every 15 seconds |
| tmux-yank | Better copy/paste |
| catppuccin/tmux | Catppuccin Mocha status bar theme |
| tmux-fzf-url | Open URLs from terminal history with fzf |

**First time:** after opening tmux, press `prefix + I` (Ctrl-a then Shift-I) to install plugins.

If you don't want Catppuccin or prefer your own config, choose option `b` during install (keybind only) and keep your existing `~/.tmux.conf`.

---

## FAQ

**Can I use this without the Catppuccin theme?**  
Yes — choose option `b` in the installer. It only appends the `prefix+W` keybind to your existing config.

**What if I don't use git worktrees?**  
Edit `~/.config/tmux/layout.sh` and remove the worktree block. The session/pane setup still works.

**What ticket system does this work with?**  
Any — the ticket ID is just a string used to name the session and worktree branch. It works with Jira, ClickUp, Linear, GitHub Issues, or no system at all.

**Can I use a different AI tool instead of Claude?**  
Yes — set `TMUX_LAYOUT_PANE1_CMD` to whatever you want (`cursor .`, `aider`, `echo hi`, etc.).

---

## License

MIT