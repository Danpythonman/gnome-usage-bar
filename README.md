# usage-bars

Shows CPU, RAM, and Claude subscription usage (5-hour and 7-day) in the GNOME top bar.

## Requirements

- `sudo apt install curl jq just`
- Signed into Claude Code (`claude`) with a Pro/Max account
- GNOME extension Executor (or Argos)

## Install

    just install

Point Executor at `~/.local/bin/usage-bars` with a 2–3 s interval.

## Notes

Uses an undocumented endpoint (`/api/oauth/usage`) that may change without notice.
Claude usage is cached and refreshed at most every 5 minutes.
