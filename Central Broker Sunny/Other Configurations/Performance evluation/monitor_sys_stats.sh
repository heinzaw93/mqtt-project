#!/usr/bin/env bash
# Usage:
#   sudo ./monitor_sys_stats.sh <RUN_TAG> <PROC_NAME> <QOS> <MQTT_VERSION> [DURATION_SEC]
#
# If DURATION_SEC is not provided or invalid, default = 120 seconds.

RUN_TAG="$1"
PROC_NAME="$2"
QOS="$3"
MQTTV="$4"
REQ_DURATION="$5"          # optional

OUTDIR="/etc/mosquitto/perf_results"
mkdir -p "${OUTDIR}"

# ----- Dynamic duration handling -----
DEFAULT_DURATION=120

# If 5th arg is a positive integer, use it; otherwise fall back to default 120s
if [[ -n "${REQ_DURATION}" ]] && [[ "${REQ_DURATION}" =~ ^[0-9]+$ ]] && [ "${REQ_DURATION}" -gt 0 ]; then
  DURATION="${REQ_DURATION}"
else
  DURATION="${DEFAULT_DURATION}"
fi

INTERVAL=1        # seconds

# Append-only, per-process files (one CSV + one LOG)
CSV_FILE="${OUTDIR}/${PROC_NAME}_stats.csv"
DEBUG_LOG="${OUTDIR}/debug_${PROC_NAME}.csv.log"

# Write CSV header once (matches the parsed fields below)
if [ ! -f "${CSV_FILE}" ]; then
  echo "timestamp,pid,%usr,%system,%guest,%wait,%CPU,vsize_kB,rss_kB,%MEM,Command,RUN_TAG,SQOS,MQTT_VERSION" > "${CSV_FILE}"
fi

echo "$(date +'%F %T') [DEBUG] Starting monitoring '${PROC_NAME}' run '${RUN_TAG}' (QOS=${QOS}, MQTT=${MQTTV}, DURATION=${DURATION}s)" >> "${DEBUG_LOG}"

# Get PIDs and convert to comma-separated list
PIDS_RAW=$(pgrep -f "${PROC_NAME}")
echo "$(date +'%F %T') [DEBUG] pgrep -f \"${PROC_NAME}\" → raw PIDs: ${PIDS_RAW}" >> "${DEBUG_LOG}"

if [ -z "${PIDS_RAW}" ]; then
  echo "$(date +'%F %T') [ERROR] No PIDs found for process name '${PROC_NAME}'. Exiting." >> "${DEBUG_LOG}"
  exit 1
fi

# Format PIDs list: replace spaces/newlines with commas
PIDS=$(echo "${PIDS_RAW}" | tr '\n' ',' | sed 's/,$//')
echo "$(date +'%F %T') [DEBUG] Formatted PIDs list: ${PIDS}" >> "${DEBUG_LOG}"

# Validate INTERVAL
if ! [[ "${INTERVAL}" =~ ^[0-9]+$ ]] || [ "${INTERVAL}" -lt 1 ]; then
  echo "$(date +'%F %T') [ERROR] Invalid INTERVAL value: ${INTERVAL}" >> "${DEBUG_LOG}"
  exit 1
fi

# Loop for duration
iterations=$((DURATION / INTERVAL))
for ((i=1; i<=iterations; i++)); do
  TS_HR=$(date +'%F %T')
  echo "$(date +'%F %T') [DEBUG] Iteration ${i}/${iterations}, PIDs=${PIDS}, interval=${INTERVAL}" >> "${DEBUG_LOG}"

  # pidstat output (with -u -r -h) differs slightly between versions:
  #   older (Pi):  Time UID PID %usr %system %guest %wait %CPU CPU minflt/s majflt/s VSZ RSS %MEM Command
  #   newer (Sunny):Time UID USER PID %usr %system %guest %wait %CPU CPU minflt/s majflt/s VSZ RSS %MEM Command
  #
  # We detect layout by NF (15 vs 16) and map fields accordingly.

  pidstat -u -r -h -p ${PIDS} ${INTERVAL} 1 2>> "${DEBUG_LOG}" \
    | awk -v ts_hr="${TS_HR}" -v tag="${RUN_TAG}" -v qos="${QOS}" -v mqtt="${MQTTV}" '
        /^Linux /        { next }          # kernel banner
        /^Average:/      { next }          # pidstat summary line
        /^[#]/           { next }          # pidstat column header
        /^[[:space:]]*$/ { next }          # blank lines

        {
          pid=""; usr=""; sys=""; guest=""; waitv=""; cpu=""; vsize=""; rss=""; mem=""; cmd="";

          if (NF == 15) {
            # Layout without USER column (Raspberry Pi)
            # $1=Time $2=UID $3=PID $4=%usr $5=%system $6=%guest $7=%wait
            # $8=%CPU $9=CPU $10=minflt/s $11=majflt/s $12=VSZ $13=RSS
            # $14=%MEM $15=Command
            pid   = $3;
            usr   = $4;
            sys   = $5;
            guest = $6;
            waitv = $7;
            cpu   = $8;
            vsize = $12;
            rss   = $13;
            mem   = $14;
            cmd   = $15;
          } else if (NF >= 16) {
            # Layout with extra USER column (Sunny / some sysstat versions)
            # $1=Time $2=UID $3=USER $4=PID $5=%usr $6=%system $7=%guest $8=%wait
            # $9=%CPU $10=CPU $11=minflt/s $12=majflt/s $13=VSZ $14=RSS
            # $15=%MEM $16=Command
            pid   = $4;
            usr   = $5;
            sys   = $6;
            guest = $7;
            waitv = $8;
            cpu   = $9;
            vsize = $13;
            rss   = $14;
            mem   = $15;
            cmd   = $16;
          } else {
            # Unexpected layout – skip
            next;
          }

          printf "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,S%s,%s\n",
                 ts_hr,pid,usr,sys,guest,waitv,cpu,vsize,rss,mem,cmd,tag,qos,mqtt;
        }
      ' >> "${CSV_FILE}"

  RC=${PIPESTATUS[0]}
  if [ ${RC} -ne 0 ]; then
    echo "$(date +'%F %T') [ERROR] pidstat returned exit code ${RC}" >> "${DEBUG_LOG}"
  fi
done

echo "$(date +'%F %T') [DEBUG] Monitoring complete for '${PROC_NAME}', run '${RUN_TAG}' (QOS=${QOS}, MQTT=${MQTTV}, DURATION=${DURATION}s)" >> "${DEBUG_LOG}"
echo "Monitoring ${PROC_NAME} done for run ${RUN_TAG}. Output → ${CSV_FILE}"
