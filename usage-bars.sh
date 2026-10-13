#!/usr/bin/env bash
# usage-bars: CPU, RAM, and Claude subscription usage for the GNOME top bar.
for dep in curl jq; do
  command -v "$dep" >/dev/null || { echo "usage-bars: $dep missing"; exit 1; }
done

DIR=${XDG_RUNTIME_DIR:-/tmp}
CACHE=$DIR/claude-usage.txt
STAMP=$DIR/claude-usage.stamp
CPUSTATE=$DIR/cpu-prev

# CPU: usage since the previous run
read -r _ u n s i w q sq st _ < /proc/stat
idle=$((i + w)); total=$((u + n + s + i + w + q + sq + st))
[[ -f $CPUSTATE ]] && read -r pidle ptotal < "$CPUSTATE"
echo "$idle $total" > "$CPUSTATE"
dt=$((total - ${ptotal:-0})); di=$((idle - ${pidle:-0}))
cpu=$(( dt > 0 ? 100 * (dt - di) / dt : 0 ))

# RAM: used = total - available
mem=$(awk '/^MemTotal/{t=$2} /^MemAvailable/{a=$2} END{printf "%d", 100*(t-a)/t}' /proc/meminfo)

# Claude: refresh at most every 300s (stamp also prevents retry spam on failure)
if [[ ! -f $STAMP || $(( $(date +%s) - $(stat -c %Y "$STAMP") )) -ge 300 ]]; then
  touch "$STAMP"
  TOKEN=$(jq -r '.claudeAiOauth.accessToken' ~/.claude/.credentials.json 2>/dev/null)
  out=$(curl -s --max-time 10 https://api.anthropic.com/api/oauth/usage \
          -H "Authorization: Bearer $TOKEN" \
          -H "anthropic-beta: oauth-2025-04-20" |
        jq -er 'select(.five_hour) |
          def p: if . == null then "–" elif . <= 1 then "\(.*100|floor)%" else "\(floor)%" end;
          "5h \(.five_hour.utilization|p) · 7d \(.seven_day.utilization|p)"') \
    && echo "$out" > "$CACHE"
fi
claude=$(cat "$CACHE" 2>/dev/null || echo "Claude ?")

echo "CPU ${cpu}% · RAM ${mem}% · $claude"
