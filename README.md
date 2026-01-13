<p align="center">
  <img src="zestsync_logo.png" alt="ZestSync" width="200">
</p>

<p align="center">
  A lightweight, menu-driven backup manager for macOS.<br>
  Zero dependencies, just bash + rsync.
</p>

## Features

- **Interactive TUI** - Easy menu-driven interface
- **Multiple backup jobs** - Manage as many backups as you need
- **Flexible scheduling** - Daily, weekly, or monthly
- **Smart catch-up** - Missed a backup? It runs when you wake your Mac
- **Incremental** - Only syncs what changed (powered by rsync)
- **Low priority** - Won't slow down your Mac

## Installation

### Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/jakerains/zestsync/main/install.sh | bash
```

### Manual install

```bash
git clone https://github.com/jakerains/zestsync.git
cd zestsync
./install.sh
```

## Usage

### Open the menu

```bash
zestsync
```

### CLI options

```bash
zestsync                  # Open interactive menu
zestsync --run <job>      # Run a specific job
zestsync --run-all        # Run all enabled jobs
zestsync --list           # List all jobs
zestsync --help           # Show help
```

## Menu

```
╔═══════════════════════════════════════════════╗
║              🍋 ZestSync                       ║
╚═══════════════════════════════════════════════╝

  1) View backup jobs
  2) Add new job
  3) Edit job
  4) Delete job
  5) Run backup now
  6) View logs
  7) Settings

  q) Quit
```

## How it works

1. **Add a job** - Choose source folder, destination, and schedule
2. **Automatic scheduling** - Uses macOS `launchd` (no cron needed)
3. **Smart sync** - rsync only transfers changed files
4. **Catch-up** - If your Mac was asleep, backup runs on wake

## Example: Backup Projects to Dropbox

```
Job name: Projects Backup
Source folder: ~/Projects
Destination folder: ~/Dropbox/Backups/Projects
Schedule: Weekly on Monday at 08:00
```

## Config

All config lives in `~/.config/zestsync/`:

```
~/.config/zestsync/
├── jobs/           # Job configurations
│   └── projects.conf
└── logs/           # Backup logs
    └── projects.log
```

## Requirements

- macOS (uses `launchd` for scheduling)
- `rsync` (included with macOS)
- `bash` 4.0+ (included with macOS)

## Uninstall

```bash
# Remove the app
rm -rf ~/.local/share/zestsync
rm ~/.local/bin/zestsync

# Remove config and logs
rm -rf ~/.config/zestsync

# Remove scheduled jobs
rm ~/Library/LaunchAgents/com.zestsync.*.plist
```

## License

MIT
