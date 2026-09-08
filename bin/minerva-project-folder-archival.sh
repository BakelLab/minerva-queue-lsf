#!/usr/bin/env bash
#
# minerva-project-folder-archival.sh — archive a project folder to TSM/Spectrum
#                      Protect via dsmc, compress the log and email a summary.
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
#   -l, --log-dir <dir>      Directory for run logs (default: /sc/arion/work/$USER/minerva-archival-logs)
#   -t, --tail <n>           Lines from the end of the dsmc output to include in the email (default: 40)
#   -n, --dry-run            Print the dsmc command without running it (email still sent)
#   --no-start-mail          Skip the "job started" notification email
#   -h, --help               Show this help
#
# Example:
#   minerva-project-folder-archival.sh --project /sc/arion/projects/MYPROJECT --email you@example.org
#   -> dsmc archive -se=$USER -sub=yes -description="2026-09-08_MYPROJECT" /sc/arion/projects/MYPROJECT/
#
# The full dsmc output is written to <log-dir>/archive_<desc>.log and gzipped
# when the job finishes. The email contains a short summary, the last lines
# of the dsmc output, and the path to the compressed log (not the log itself).
# A short "started" email is also sent when the dsmc job begins.

set -uo pipefail

# ------------------------------------------------------------- defaults ---
DSMC_PATH="/opt/tivoli/tsm/client/ba/bin/dsmc"
RUN_USER="${USER:-$(id -un)}"                  # $USER may be unset under cron
SERVER="$RUN_USER"
LOG_DIR="/sc/arion/work/${RUN_USER}/minerva-archival-logs"
TAIL_LINES=40
PROJECT_DIR=""
EMAIL=""
DRY_RUN=0
START_MAIL=1

usage() { sed -n '/^# Usage:/,/^set -uo/p' "$0" | sed '$d'; exit "${1:-0}"; }
die()   { echo "Error: $*" >&2; echo >&2; usage 1; }

# --------------------------------------------------------- parse options ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--project)   [[ $# -ge 2 ]] || die "$1 requires a value"; PROJECT_DIR="$2"; shift 2 ;;
    -e|--email)     [[ $# -ge 2 ]] || die "$1 requires a value"; EMAIL="$2";       shift 2 ;;
    -s|--server)    [[ $# -ge 2 ]] || die "$1 requires a value"; SERVER="$2";      shift 2 ;;
    -l|--log-dir)   [[ $# -ge 2 ]] || die "$1 requires a value"; LOG_DIR="$2";     shift 2 ;;
    -t|--tail)      [[ $# -ge 2 ]] || die "$1 requires a value"; TAIL_LINES="$2";  shift 2 ;;
    --project=*)    PROJECT_DIR="${1#*=}"; shift ;;
    --email=*)      EMAIL="${1#*=}";       shift ;;
    --server=*)     SERVER="${1#*=}";      shift ;;
    --log-dir=*)    LOG_DIR="${1#*=}";     shift ;;
    --tail=*)       TAIL_LINES="${1#*=}";  shift ;;
    -n|--dry-run)   DRY_RUN=1; shift ;;
    --no-start-mail) START_MAIL=0; shift ;;
    -h|--help)      usage 0 ;;
    --)             shift; break ;;
    -*)             die "unknown option: $1" ;;
    *)              die "unexpected argument: $1" ;;
  esac
done

[[ -n "$PROJECT_DIR" ]]          || die "--project is required"
[[ -n "$EMAIL" ]]                || die "--email is required"
[[ "$EMAIL" == *@* ]]            || die "--email does not look like an address: $EMAIL"
[[ "$TAIL_LINES" =~ ^[0-9]+$ ]]  || die "--tail must be a non-negative integer"

# ---------------------------------------------------------------- setup ---
PROJECT_DIR="${PROJECT_DIR%/}"                 # strip trailing slash
PROJECT_NAME="$(basename "$PROJECT_DIR")"
DATE="$(date +%Y-%m-%d)"
DESC="${DATE}_${PROJECT_NAME}"
HOST="$(hostname -s)"

mkdir -p "$LOG_DIR" || { echo "Error: cannot create log dir $LOG_DIR" >&2; exit 1; }
RUN_LOG="${LOG_DIR}/archive_${DESC}.log"
: > "$RUN_LOG"                                  # start a fresh log for this run

log() { printf '%s  %s\n' "$(date '+%F %T')" "$*" | tee -a "$RUN_LOG"; }

# Compress the run log; prints the final log path (gz on success, plain otherwise)
compress_log() {
  if gzip -f "$RUN_LOG" 2>/dev/null; then
    echo "${RUN_LOG}.gz"
  else
    echo "$RUN_LOG"
  fi
}

# deliver <subject>   (body on stdin)
deliver() {
  local subject="$1"
  if command -v mailx >/dev/null 2>&1; then
    mailx -s "$subject" "$EMAIL"
  elif command -v mail >/dev/null 2>&1; then
    mail -s "$subject" "$EMAIL"
  else
    echo "WARNING: no mail/mailx command found; email not sent" >&2
    cat >/dev/null
    return 1
  fi
}

# send_start_mail: short notification that the dsmc job has begun
send_start_mail() {
  [[ $START_MAIL -eq 1 ]] || return 0
  deliver "[dsmc archive] STARTED: ${DESC} on ${HOST}" <<MSG
dsmc archive started
====================
Project  : ${PROJECT_DIR}
Desc     : ${DESC}
Server   : ${SERVER}
Host     : ${HOST}
Started  : ${START_TS}
PID      : $$

Command  : ${CMD[*]}
Log file : ${RUN_LOG} (will be gzipped on completion)

A second email will follow when the job finishes.
MSG
}

# send_mail <status> <final_log_path> [dsmc_tail_text]
send_mail() {
  local status="$1" final_log="$2" dsmc_tail="${3:-}"
  local subject="[dsmc archive] ${status}: ${DESC} on ${HOST}"
  local size
  size="$(du -h "$final_log" 2>/dev/null | cut -f1)"

  local body
  body="$(cat <<MSG
dsmc archive report
===================
Status   : ${status}
Project  : ${PROJECT_DIR}
Desc     : ${DESC}
Server   : ${SERVER}
Host     : ${HOST}
Started  : ${START_TS:-n/a}
Finished : $(date '+%F %T')
Elapsed  : ${ELAPSED:-0}s

Log file : ${final_log} (${size:-?})
$( [[ "$final_log" == *.gz ]] && echo "View with: zless ${final_log}" )
MSG
)"

  if [[ -n "$dsmc_tail" ]]; then
    body+=$'\n\n'"--- last ${TAIL_LINES} lines of dsmc output ---"$'\n'"${dsmc_tail}"
  fi

  printf '%s\n' "$body" | deliver "$subject"
}

# ----------------------------------------------------------------- main ---
START_TS="$(date '+%F %T')"
log "=== Archive run started ==="
log "project : ${PROJECT_DIR}"
log "desc    : ${DESC}"
log "server  : ${SERVER}"
log "email   : ${EMAIL}"
log "dry_run : ${DRY_RUN}"

if [[ ! -d "$PROJECT_DIR" ]]; then
  log "FAIL  ${PROJECT_DIR} is not a directory"
  send_mail "FAILED" "$(compress_log)"
  exit 1
fi

if [[ ! -x "$DSMC_PATH" ]]; then
  log "FAIL  dsmc not found or not executable at ${DSMC_PATH}"
  send_mail "FAILED" "$(compress_log)"
  exit 1
fi

CMD=("${DSMC_PATH}" archive "-se=${SERVER}" "-sub=yes" "-description=${DESC}" "${PROJECT_DIR}/")
log "command : ${CMD[*]}"

if [[ $DRY_RUN -eq 1 ]]; then
  log "=== Dry run, nothing archived ==="
  send_mail "DRY RUN" "$(compress_log)"
  exit 0
fi

send_start_mail

START=$(date +%s)
log "--- dsmc output begins ---"
"${CMD[@]}" >> "$RUN_LOG" 2>&1
rc=$?
ELAPSED=$(( $(date +%s) - START ))
log "--- dsmc output ends ---"

# dsmc return codes: 0 ok, 4 some files skipped, 8 warnings, 12+ errors
if   [[ $rc -eq 0 ]]; then STATUS="OK"
elif [[ $rc -le 8 ]]; then STATUS="WARNINGS (rc=$rc)"
else                       STATUS="FAILED (rc=$rc)"
fi
log "=== Finished: ${STATUS}, elapsed ${ELAPSED}s ==="

# Grab the dsmc summary block before the log is compressed
DSMC_TAIL="$(sed -n '/--- dsmc output begins ---/,/--- dsmc output ends ---/p' "$RUN_LOG" \
             | sed '1d;$d' | tail -n "$TAIL_LINES")"

FINAL_LOG="$(compress_log)"
echo "Log: ${FINAL_LOG}"
send_mail "$STATUS" "$FINAL_LOG" "$DSMC_TAIL"

[[ $rc -le 8 ]] && exit 0 || exit 1
