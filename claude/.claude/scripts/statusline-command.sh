#!/bin/sh

# ---------------------------------------------------------------------------
# Helper: extract a single field from the JSON input stored in $input.
#  Usage: jq_field '.some.path // empty'
# ---------------------------------------------------------------------------
jq_field() { echo "$input" | jq -r "$1"; }

# ---------------------------------------------------------------------------
# Helper: pick an ANSI color escape based on a percentage value.
#   $1 = integer percentage
#   $2 = color when >= 80  (default: red    \033[31m)
#   $3 = color when >= 50  (default: yellow \033[33m)
#   $4 = color when <  50  (default: green  \033[32m)
# Prints the chosen escape sequence (no newline).
# ---------------------------------------------------------------------------
threshold_color() {
  pct="$1"
  hi="${2:-\033[31m}"
  mid="${3:-\033[33m}"
  lo="${4:-\033[32m}"
  if [ "$pct" -ge 80 ]; then
    printf "%b" "$hi"
  elif [ "$pct" -ge 50 ]; then
    printf "%b" "$mid"
  else
    printf "%b" "$lo"
  fi
}

# ---------------------------------------------------------------------------
# Helper: format a unix epoch as "Xh YYm" remaining.
# systime() is a gawk extension not available in BSD awk (macOS default),
# so "now" is computed in the shell via date +%s and passed as a variable.
#   $1 = epoch seconds
# ---------------------------------------------------------------------------
format_reset_time() {
  epoch="$1"
  if [ -z "$epoch" ]; then return; fi
  now=$(date +%s)
  awk -v epoch="$epoch" -v now="$now" 'BEGIN {
    diff = epoch - now
    if (diff < 0) diff = 0
    h = int(diff / 3600)
    m = int((diff % 3600) / 60)
    printf "%dh%02dm", h, m
  }'
}

# ---------------------------------------------------------------------------
# Helper: format a raw token-count as "200k" or "1M" etc.
#   $1 = raw integer size
# ---------------------------------------------------------------------------
format_ctx_size() {
  size="$1"
  if [ -z "$size" ]; then return; fi
  awk -v s="$size" 'BEGIN {
    if (s >= 1000000) printf "%.0fM", s/1000000
    else if (s >= 1000) printf "%.0fk", s/1000
    else printf "%d", s
  }'
}

# ---------------------------------------------------------------------------
# Read all input once, then extract every field we need.
# ---------------------------------------------------------------------------
input=$(cat)

cwd=$(jq_field '.workspace.current_dir // .cwd // ""')
model=$(jq_field '.model.display_name // ""')
used_pct=$(jq_field '.context_window.used_percentage // empty')
ctx_size=$(jq_field '.context_window.context_window_size // empty')
effort=$(jq_field '.effort.level // empty')
thinking=$(jq_field '.thinking.enabled // empty')
five_pct=$(jq_field '.rate_limits.five_hour.used_percentage // empty')
five_resets=$(jq_field '.rate_limits.five_hour.resets_at // empty')
week_pct=$(jq_field '.rate_limits.seven_day.used_percentage // empty')
week_resets=$(jq_field '.rate_limits.seven_day.resets_at // empty')
cost=$(jq_field '.cost.total_cost_usd // empty')

# Shorten home directory to ~
short_cwd=$(echo "$cwd" | sed "s|^$HOME|~|")

# Git branch (skip optional locks to avoid stalling)
git_branch=""
if [ -d "$cwd/.git" ] || git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  git_branch=$(git -C "$cwd" -c gc.auto=0 symbolic-ref --short HEAD 2>/dev/null ||
    git -C "$cwd" -c gc.auto=0 rev-parse --short HEAD 2>/dev/null)
fi

# ---------------------------------------------------------------------------
# Build the status line by appending to $line, then emit it all at once.
# Color key:
#   cyan    = directory                   \033[36m
#   yellow  = git branch                  \033[33m
#   magenta = model / effort / thinking   \033[35m
#   green / yellow / red = usage thresholds
#   dim     = cost                        \033[2m
# ---------------------------------------------------------------------------
R="\033[0m" # reset

line=""

# -- Directory (always shown) -----------------------------------------------
line="${line}\033[36m${short_cwd}${R}"

# -- Git branch ---------------------------------------------------------------
if [ -n "$git_branch" ]; then
  line="${line} \033[33m(${git_branch})${R}"
fi

# -- Model name ---------------------------------------------------------------
if [ -n "$model" ]; then
  line="${line} | \033[35m${model}${R}"
fi

# -- Effort level (appended directly after model with a colon) ----------------
if [ -n "$effort" ]; then
  line="${line}\033[35m:${effort}${R}"
fi

# -- Thinking indicator -------------------------------------------------------
if [ "$thinking" = "true" ]; then
  line="${line} \033[35mthinking${R}"
fi

# -- Context window usage -----------------------------------------------------
if [ -n "$used_pct" ]; then
  used_int=$(printf "%.0f" "$used_pct")
  ctx_color=$(threshold_color "$used_int" "\033[31m" "\033[33m" "\033[32m")
  ctx_label="ctx:${used_int}%"
  if [ -n "$ctx_size" ]; then
    ctx_label="${ctx_label}/$(format_ctx_size "$ctx_size")"
  fi
  line="${line} | ${ctx_color}${ctx_label}${R}"
elif [ -n "$ctx_size" ]; then
  # No usage data yet, but we know the window size — show it in green
  line="${line} | \033[32mctx:$(format_ctx_size "$ctx_size")${R}"
fi

# -- 5-hour rate limit --------------------------------------------------------
if [ -n "$five_pct" ]; then
  five_int=$(printf "%.0f" "$five_pct")
  five_color=$(threshold_color "$five_int" "\033[31m" "\033[33m" "\033[36m")
  five_label="5h:${five_int}%"
  if [ -n "$five_resets" ]; then
    five_label="${five_label}($(format_reset_time "$five_resets"))"
  fi
  line="${line} ${five_color}${five_label}${R}"
fi

# -- 7-day rate limit ---------------------------------------------------------
if [ -n "$week_pct" ]; then
  week_int=$(printf "%.0f" "$week_pct")
  week_color=$(threshold_color "$week_int" "\033[31m" "\033[33m" "\033[34m")
  week_label="7d:${week_int}%"
  if [ -n "$week_resets" ]; then
    week_label="${week_label}($(format_reset_time "$week_resets"))"
  fi
  line="${line} ${week_color}${week_label}${R}"
fi

# -- Session cost -------------------------------------------------------------
if [ -n "$cost" ] && [ "$cost" != "0" ] && [ "$cost" != "null" ]; then
  # Format cost to 5 decimal places
  formatted_cost=$(printf "%.5f" "$cost")
  line="${line} | \033[2m\$${formatted_cost}${R}"
fi

# ---------------------------------------------------------------------------
# Single print of the fully-assembled status line.
# ---------------------------------------------------------------------------
printf "%b" "$line"
