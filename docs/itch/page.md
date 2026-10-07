# itch.io page draft: Pomodial

## Settings

| Field | Value |
| --- | --- |
| Title | Pomodial |
| Short description / tagline | A visual timer for your Playdate, wound with the crank. |
| Classification | Tools |
| Kind of project | Downloadable |
| Pricing | No payments / Name your own price, minimum $0 (suggested $2) |
| Upload | `Pomodial-0.1.0.zip`, mark platform as Playdate if offered |
| Genre | (none, or "Other") |
| Tags | playdate, pomodoro, timer, productivity, focus, crank, 1-bit, open-source |
| Cover image | `cover.png` (1260×1000, 2× the 630×500 card) |
| Screenshots | `screenshot-1-ready.png`, `screenshot-2-running.png`, `screenshot-3-paused.png`, `screenshot-4-break.png` (800×480, 2× crisp) |
| Links | Source: https://github.com/sjobergfredrik/pomodial |

---

## Description (paste into the itch editor)

**Wind it up. Watch the time drain away. Take a break.**

Pomodial turns your Playdate into a desk timer you read at a glance. Crank it like an old kitchen timer, and a gray wedge on a square 60-minute dial shows how much time is left, shrinking toward 12 as the minutes pass. No need to read numbers: one look tells you how much focus is left.

It's built around the Pomodoro rhythm: 25 minutes of focus, a 5-minute break, and a longer 15-minute break after every fourth session.

### Features

- **Crank to wind.** A quarter turn adds 15 minutes, with a soft tick for every minute.
- **See time, don't read it.** A square visual-timer dial, inspired by classic visual timers like the Time Timer®.
- **Pomodoro cycle.** Focus, short break, long break, with dots that track your sessions.
- **Chime and flash** when a phase ends. The next phase is ready and waits for you.
- **Made for the desk.** The screen stays on while it runs, and timing uses the real clock, so it stays right even if your Playdate goes to sleep.
- **Free and open source** (MIT).

### Controls

- **Crank:** wind time up or down
- **Ⓐ:** start / pause
- **Ⓑ:** reset the current phase
- **⬅️ ➡️:** switch phase (focus / short break / long break)
- **⬆️ ⬇️:** nudge one minute
- **Menu:** *Skip phase*, *New cycle*

Tip: put your Playdate on its stand next to your keyboard, and plug it in for long sessions.

### Install

1. Download `Pomodial-0.1.0.zip`.
2. Go to [play.date/account/sideload](https://play.date/account/sideload/) and upload the zip.
3. On your Playdate, open **Settings → Games** to download it. It appears on your home screen.

Or, over USB: put your Playdate in Data Disk mode (**Settings → System → Reboot to Data Disk**) and copy `Pomodial.pdx` into the `Games` folder.

### Source

The code is on GitHub: [sjobergfredrik/pomodial](https://github.com/sjobergfredrik/pomodial). Issues and ideas are welcome.

---

*Pomodial is not affiliated with Panic or Time Timer LLC. Playdate is a trademark of Panic Inc.; Time Timer is a registered trademark of Time Timer LLC.*

---

## Devlog post (optional, for launch)

**Pomodial 0.1: a visual timer you wind with the crank**

I wanted a Pomodoro timer I could read without reading it. Pomodial puts a square 60-minute dial on the Playdate screen, and a gray wedge shows the time left. You wind it up with the crank.

One fun bug along the way: the countdown froze at 24:32. Playdate's Lua uses 32-bit floats, and seconds since the epoch (around 800 million) only resolve to 64-second steps at that size. Subtracting a starting time captured at launch fixed it.

Next up, maybe: custom lengths (50/10), a daily tally, and card art for the home screen.
