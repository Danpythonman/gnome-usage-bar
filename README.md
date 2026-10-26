# usage-bars

Shows CPU, RAM, and Claude subscription usage (5-hour and 7-day) in the GNOME top bar.

## Install

1. Install dependencies:

       sudo apt install curl jq just git gnome-shell-extension-manager

2. Sign into Claude Code (`claude`) with a Pro/Max account, so
   `~/.claude/.credentials.json` exists.

3. Clone and install the script to `~/.local/bin/usage-bars`:

       git clone https://github.com/Danpythonman/gnome-usage-bar.git
       cd gnome-usage-bar
       just install

4. Open Extension Manager, go to **Browse**, and install **Executor**.

5. In Executor's settings, add the command `/home/<user>/.local/bin/usage-bars`
   (full path; `~` may not expand) with a 2 s interval.

If the bar doesn't appear, log out and back in.

## Update

    git pull
    just install

No restart needed; Executor runs the new version on its next tick.

## Notes

Uses an undocumented endpoint (`/api/oauth/usage`) that may change without notice.
Claude usage is cached and refreshed at most every 10 minutes (30 after a rate limit).
