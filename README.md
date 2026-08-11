# BetterClipboard

A lightweight, native clipboard manager for macOS.

Fast. Private. Native.

No ads • No subscriptions • No telemetry

Supports macOS 14.6+

<img width="861" height="563" alt="2026-08-0422 03 58-ezgif com-crop" src="https://github.com/user-attachments/assets/cc235750-7c30-4472-8742-948eb9ea601e" />
---

BetterClipboard is a lightweight native clipboard manager built for macOS.

It provides instant access to your clipboard history through a clean popup window designed to feel like a built-in macOS feature.

Everything is processed locally.

No cloud.  
No tracking.  
No analytics.

---

### Features

- 📋 Clipboard history (up to **500** items, or unlimited)
- 📌 Pin important items
- 🖼️ Supports text, images, files and links
- 📂 Automatic content grouping by type
- 🔍 Search history (button or type-to-search)
- 📅 Filter by date (calendar)
- 🌍 English & Russian languages
- 🚀 Launch at login
- ⌘ Double Command global shortcut
- 📍 Two popup positioning modes
  - Remember last window position
  - Open in screen corner
- 💾 Window position is remembered between launches
- 🕒 Displays copy date and time (up to 3 recent times for repeated copies)
- 📝 Paste without formatting (⌘ + Click / Right Click)
- 🗑️ Clear all history or by date range
- ⚡ Lightweight native SwiftUI application
- 🍎 Designed specifically for macOS

---

### Performance

- Application size (.app + .dmg): **under 5 MB**
- Typical memory usage: **under 50 MB**
- Up to **100 MB** with a full clipboard history

P.S. The repository does not contain the most up-to-date source code; attempting to run it via Xcode may result in errors.

---

### System Requirements

- macOS **14.6 or newer**

---

### Accessibility Permission

BetterClipboard requests Accessibility permission only to detect the global **Double Command** shortcut.

Without this permission the application will continue to work normally.

The only unavailable feature will be the global keyboard shortcut.

You can still access BetterClipboard at any time from the menu bar icon.

---

### Privacy

- No telemetry
- No analytics
- No advertising
- No cloud synchronization
- Everything stays on your Mac

---

### Installation

**Option A — Download**

1. Download the latest `.dmg` or `.zip` from [Releases](https://github.com/5hzdqd4788-afk/betterclipboard/releases)
2. Open the file and move **BetterClipboard** to Applications
3. Launch the app
4. Grant Accessibility access if you want Double ⌘

**Option B — Terminal**

```bash
curl -fsSL https://raw.githubusercontent.com/5hzdqd4788-afk/betterclipboard/main/install.sh | bash


