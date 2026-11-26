# Enable Undercurls in Neovim + Ghostty + tmux (macOS)

### 1. Export existing tmux terminfo

Run inside tmux, outside Neovim:

```bash
infocmp -x tmux-256color > /tmp/tmux-256color.src
```

### 2. Edit the terminfo file

```bash
nvim /tmp/tmux-256color.src
```

Add these two capabilities to the existing `tmux-256color` entry, before its final comma:

```text
Smulx=\E[4\:%p1%dm,
Setulc=\E[58\:\:2\:\:%p1%{65536}%/%d\:\:%p1%{256}%/%{255}%&%d\:\:%p1%{255}%&%d%;m,
```

### 3. Create local terminfo directory

```bash
mkdir -p ~/.terminfo
```

### 4. Compile the modified terminfo

```bash
tic -x -o ~/.terminfo /tmp/tmux-256color.src
```

### 5. Verify capabilities

```bash
infocmp -x tmux-256color | grep -E 'Smulx|Setulc'
```

Both `Smulx` and `Setulc` should appear.

### 6. Configure terminfo lookup

Add this to `~/.zshrc`:

```bash
export TERMINFO_DIRS="$HOME/.terminfo:$TERMINFO_DIRS"
```

Reload:

```bash
source ~/.zshrc
```

### 7. Restart tmux

```bash
tmux kill-server
tmux
```

### 8. Test undercurl

```bash
printf '\e[4:3mUNDERCURL TEST\e[4:0m\n'
```

You should see a wavy underline.

### Required tmux configuration (~/.tmux.conf)

```tmux
set -g default-terminal "tmux-256color"

set -as terminal-features ",xterm-ghostty:RGB"
set -as terminal-features ",xterm-ghostty:usstyle"
```

**Result:** Ghostty → tmux → Neovim supports undercurl through the corrected `tmux-256color` terminfo entry.
