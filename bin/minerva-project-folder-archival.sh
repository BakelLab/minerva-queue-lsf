#!/bin/sh

# 07.09.2026 14:37:36 EDT

#!/usr/bin/env bash
#
# minerva-project-folder-archival.sh — archive a project folder to TSM/Spectrum Protect via dsmc
#                      and email the log when finished.
#
# Usage:
#   minerva-project-folder-archival.sh --project <folder> --email <address> [options]
#
# Required:
#   -p, --project <folder>   Full path to the project folder (e.g. /sc/arion/projects/MYPROJECT)
#   -e, --email <address>    Address to send the completion report to
#
# Options:
#   -s, --server <node>      TSM node name for -se= (default: $USER)
#   -l, --log-dir <dir>      Directory for run logs (default: ~/archive-logs)
#   -n, --dry-run            Print the dsmc command without running it (email still sent)
#   -h, --help               Show this help
#
# Example:
#   minerva-project-folder-archival.sh --project /sc/arion/bakellab --email you@example.org
#   -> dsmc archive -se=$USER -sub=yes -description="2026-09-07_MYPROJECT" /sc/arion/projects/MYPROJECT/
#
#
# Suggested cron (1st of every month at 02:00, one line per project):
#   0 2 1 * * /path/to/minerva-project-folder-archival.sh --project /sc/arion/projects/MYPROJECT --email you@example.org

set -uo pipefail

# ------------------------------------------------------------- defaults ---
DSMC_PATH="/opt/tivoli/tsm/client/ba/bin/dsmc"
SERVER="${USER:-$(id -un)}"
LOG_DIR="/sc/arion/work/$USER/minerva-archival-logs"
PROJECT_DIR=""
EMAIL=""
DRY_RUN=0

usage() { sed -n '2,29p' "$0"; exit "${1:-0}"; }
die()   { echo "Error: $*" >&2; echo >&2; usage 1; }

# --------------------------------------------------------- parse options ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--project)   [[ $# -ge 2 ]] || die "$1 requires a value"; PROJECT_DIR="$2"; shift 2 ;;
    -e|--email)     [[ $# -ge 2 ]] || die "$1 requires a value"; EMAIL="$2";       shift 2 ;;
    -s|--server)    [[ $# -ge 2 ]] || die "$1 requires a value"; SERVER="$2";      shift 2 ;;
    -l|--log-dir)   [[ $# -ge 2 ]] || die "$1 requires a value"; LOG_DIR="$2";     shift 2 ;;
    --project=*)    PROJECT_DIR="${1#*=}"; shift ;;
    --email=*)      EMAIL="${1#*=}";       shift ;;
    --server=*)     SERVER="${1#*=}";      shift ;;
    --log-dir=*)    LOG_DIR="${1#*=}";     shift ;;
    -n|--dry-run)   DRY_RUN=1; shift ;;
    -h|--help)      usage 0 ;;
    --)             shift; break ;;
    -*)             die "unknown option: $1" ;;
    *)              die "unexpected argument: $1" ;;
  esac
done

[[ -n "$PROJECT_DIR" ]] || die "--project is required"
[[ -n "$EMAIL" ]]       || die "--email is required"
[[ "$EMAIL" == *@* ]]   || die "--email does not look like an address: $EMAIL"

# ---------------------------------------------------------------- setup ---
PROJECT_DIR="${PROJECT_DIR%/}"                 # strip trailing slash
PROJECT_NAME="$(basename "$PROJECT_DIR")"
DATE="$(date +%Y-%m-%d)"
DESC="${DATE}_${PROJECT_NAME}"

mkdir -p "$LOG_DIR" || { echo "Error: cannot create log dir $LOG_DIR" >&2; exit 1; }
RUN_LOG="${LOG_DIR}/archive_${DESC}.log"

log() { printf '%s  %s\n' "$(date '+%F %T')" "$*" | tee -a "$RUN_LOG"; }

send_mail() {
  local status="$1"
  local subject="[dsmc archive] ${status}: ${DESC} on $(hostname -s)"
  if command -v mailx >/dev/null 2>&1; then
    mailx -s "$subject" "$EMAIL" < "$RUN_LOG"
  elif command -v mail >/dev/null 2>&1; then
    mail -s "$subject" "$EMAIL" < "$RUN_LOG"
  else
    log "WARNING: no mail/mailx command found; email not sent"
    return 1
  fi
}

# ----------------------------------------------------------------- main ---
log "=== Archive run started ==="
log "project : ${PROJECT_DIR}"
log "desc    : ${DESC}"
log "server  : ${SERVER}"
log "email   : ${EMAIL}"
log "dry_run : ${DRY_RUN}"

if [[ ! -d "$PROJECT_DIR" ]]; then
  log "FAIL  ${PROJECT_DIR} is not a directory"
  send_mail "FAILED"
  exit 1
fi

CMD=("${DSMC_PATH}" archive "-se=${SERVER}" "-sub=yes" "-description=${DESC}" "${PROJECT_DIR}/")
log "command : ${CMD[*]}"

if [[ $DRY_RUN -eq 1 ]]; then
  log "=== Dry run, nothing archived ==="
  send_mail "DRY RUN"
  exit 0
fi

START=$(date +%s)
"${CMD[@]}" >> "$RUN_LOG" 2>&1
rc=$?
ELAPSED=$(( $(date +%s) - START ))

# dsmc return codes: 0 ok, 4 some files skipped, 8 warnings, 12+ errors
if   [[ $rc -eq 0 ]]; then STATUS="OK"
elif [[ $rc -le 8 ]]; then STATUS="WARNINGS (rc=$rc)"
else                       STATUS="FAILED (rc=$rc)"
fi

log "=== Finished: ${STATUS}, elapsed ${ELAPSED}s ==="
send_mail "$STATUS"

[[ $rc -le 8 ]] && exit 0 || exit 1
