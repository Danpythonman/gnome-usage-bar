#!/usr/bin/env bash
# usage-bars: CPU, RAM, and Claude subscription usage for the GNOME top bar.
for dep in curl jq; do
  command -v "$dep" >/dev/null || { echo "usage-bars: $dep missing"; exit 1; }
done

fmt() { (( $1 >= 100 )) && echo "1.00" || printf '.%02d' "$1"; }

DIR=${XDG_RUNTIME_DIR:-/tmp}
CACHE=$DIR/claude-usage.tsv
STAMP=$DIR/claude-usage-tsv.stamp
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

# Claude: refresh at most every 600s (stamp also prevents retry spam on failure)
if [[ ! -f $STAMP || $(( $(date +%s) - $(stat -c %Y "$STAMP") )) -ge 600 ]]; then
  touch "$STAMP"
  TOKEN=$(jq -r '.claudeAiOauth.accessToken' ~/.claude/.credentials.json 2>/dev/null)
  resp=$(curl -s -w '\n%{http_code}' --max-time 10 https://api.anthropic.com/api/oauth/usage \
           -H "Authorization: Bearer $TOKEN" \
           -H "anthropic-beta: oauth-2025-04-20")
  # rate limited: stamp 20 min into the future, so the next try is in 30 min
  [[ ${resp##*$'\n'} == 429 ]] && touch -d '+20 minutes' "$STAMP"
  out=$(printf '%s' "${resp%$'\n'*}" |
        jq -er 'select(.five_hour) |
          def p: if . == null then "–" else (floor | if . >= 100 then "1.00" elif . < 10 then ".0\(.)" else ".\(.)" end) end;
          def t: if . == null then 0 else .[0:19] + "Z" | fromdateiso8601 end;
          [(.five_hour | (.utilization|p), (.resets_at|t)), (.seven_day | (.utilization|p), (.resets_at|t))] | @tsv') \
    && echo "$out" > "$CACHE"
fi

# time until a reset epoch, e.g. 3d2h / 2h13m / 45m (computed every run, not cached)
left() {
  local s=$(( $1 - $(date +%s) ))
  if (( $1 == 0 || s <= 0 )); then echo "–"
  elif (( s >= 86400 )); then echo "$((s / 86400))d$((s % 86400 / 3600))h"
  elif (( s >= 3600 )); then echo "$((s / 3600))h$((s % 3600 / 60))m"
  else echo "$(( (s + 59) / 60 ))m"; fi
}
if read -r u5 r5 u7 r7 2>/dev/null < "$CACHE" && [[ $r7 ]]; then
  claude="5h $u5 ($(left "$r5")) · 7d $u7 ($(left "$r7"))"
else
  claude="Claude ?"
fi

echo "CPU $(fmt "$cpu") · RAM $(fmt "$mem") · $claude"
