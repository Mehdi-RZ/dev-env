# Dev Environment Setup

My custom taskfile based development environment for Ubuntu (so far). Install dev tools, GUI apps, shell config, and dotfiles.

## Quick Start

```bash
git clone <repo> ~/dev-env && cd ~/dev-env
./bootstrap.sh
```

## Usage

```bash
# Setup
task setup:desktop          # Core + GUI apps
task setup:core             # Core tools only (no GUI)
task setup:desktop WORK=true   # + Microsoft Edge & Intune

# Individual
task install:core           # Docker, kubectl, AWS, uv, etc.
task install:gui            # VSCode, Brave, KeePassXC, Obsidian
task install:gui WORK=true # + Edge, Intune
task shell:configure        # oh-my-zsh + plugins

# Dotfiles
task dotfiles:deploy       # Copy configs to home (prompts backup)
task dotfiles:collect      # Copy configs back to repo
task dotfiles:diff         # Show differences

# Maintenance
task update:all            # Update everything
task verify                # Show installed versions
task --list               # All available tasks
```

## What's Installed

| Category | Tools |
|----------|-------|
| Core | git, zsh, vim, Docker, kubectl, kind, Helm, AWS CLI, uv, OpenTofu |
| GUI (personal) | VSCode, Brave, KeePassXC, Obsidian, Super Productivity |
| GUI (work) | Microsoft Edge, Intune (WORK=true) |
| Shell | oh-my-zsh + autosuggestions, syntax-highlighting |

## Directory Structure

```
dev-env/
├── bootstrap.sh              # Initial setup
├── Taskfile.yml             # Tasks
├── platform/ubuntu/          # Scripts
│   ├── install-core.sh
│   ├── install-gui.sh
│   ├── configure-shell.sh
│   ├── dotfiles-deploy.sh
│   ├── dotfiles-collect.sh
│   └── maintenance-*.sh
├── configs/                 # Dotfiles
└── lib/                    # Shared utilities
```

## Dotfiles Workflow

```bash
# Machine A: make changes and push
task dotfiles:collect
git add . && git commit -m "Update configs" && git push

# Machine B: pull and deploy
git pull && task dotfiles:deploy
```

Backups saved to `~/.dotfiles-backup/YYYYMMDD-HHMMSS/`

## Customization

### Adding GUI Apps

Edit `platform/ubuntu/install-gui.sh`:

```bash
# APT repo - add to APT_TOOLS_PERSONAL or APT_TOOLS_WORK
["my-tool"]="repo|GPG_KEY_URL|REPO_URL|DISTRIBUTION|PACKAGE_NAME"
["my-tool"]="ppa|PPA_STRING|PACKAGE_NAME"
["my-tool"]="sources|GPG_KEY_URL|SOURCES_URL|PACKAGE_NAME"

# GitHub release - add to DEB_TOOLS (always installed)
["My Tool"]="owner/repo|package-name|deb-filename-pattern"
```

For updates, also update `maintenance-update-bonus.sh` DEB_TOOLS array.

### Adding Core Tools

Edit `platform/ubuntu/install-core.sh` - add installation commands in the appropriate section.


## Requirements

- Ubuntu/Debian
- sudo privileges

## Troubleshooting

```bash
# Docker permissions
sudo usermod -aG docker $USER && logout

# oh-my-zsh not loading
exec zsh
```
