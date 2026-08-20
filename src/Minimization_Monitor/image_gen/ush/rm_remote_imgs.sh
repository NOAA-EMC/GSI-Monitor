#!/usr/bin/bash

#-------
# usage
#-------
usage() {
    local exit_code="${1:-0}"
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --rh|--remote-host              Required.  Name of remote host.
  --rd|--remote-dir               Required.  Target directory on remote host.
  -u|--remote-usr                 Required.  User name on remote host.
  -c|--cutoff-date <YYYYMMDDHH>   Required.  Remove files from cycles earlier than this date.
  -d|--dry-run                    Optional.  Preview actions without deleting remote files
  -h|--help                                  Display this help message and exit

Examples:
  $(basename "$0") --cdt 2026081400 --dry-run
  $(basename "$0") -n
EOF
    exit "$exit_code"
}



# ------------------------------
#  Parse Command Line Arguments 
# ------------------------------
CUTOFF_DATE=""
DRY_RUN=false
REMOTE_HOST=""
REMOTE_DIR=""
REMOTE_USR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --rh|--remote-host)
            REMOTE_HOST=$2
            shift 2
            ;;
        --rd|--remote-dir)
            REMOTE_DIR=$2
            shift 2
            ;;
        -u|--remote-usr)
            REMOTE_USR=$2
            shift 2
            ;;
        -c|--cutoff-date)
            CUTOFF_DATE="$2"
            # --- Validate 10-Digit Format ---
            if [[ ! "$CUTOFF_DATE" =~ ^[0-9]{10}$ ]]; then
                echo "Error: Invalid CUTOFF_DATE '$CUTOFF_DATE'. Must be 10 digits in YYYYMMDDHH format)." >&2
                usage 1
            fi
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift 1
            ;;
        -h|--help)
            usage 0
            ;;
        *)
            echo "Unknown option: $1"
            usage 1
            ;;
    esac
done

if [ "${DRY_RUN}" = true ]; then
    echo "=== DRY RUN MODE: No files will be deleted ==="
fi

if [ -z "${CUTOFF_DATE}" ]; then
   echo "No CUTOFF_DATE was input.  Unable to proceed."
   usage 1
fi

if [ -z "${REMOTE_USR}" ]; then
   echo "REMOTE_USR was not input.  Unable to proceed."
   usage 1
fi

if [ -z "${REMOTE_DIR}" ]; then
   echo "REMOTE_DIR was not input.  Unable to proceed."
   usage 1
fi

if [ -z "${REMOTE_HOST}" ]; then
   echo "REMOTE_HOST was not input.  Unable to proceed."
   usage 1
fi

echo "REMOTE_HOST: ${REMOTE_HOST}"
echo "REMOTE_DIR:  ${REMOTE_DIR}"
echo "REMOTE_USR:  ${REMOTE_USR}"
echo "CUTOFF_DATE: ${CUTOFF_DATE}"
echo "DRY_RUN:     ${DRY_RUN}"

#-----------------------------
# Get listing of remote files
#-----------------------------
r_files="remote_files.txt"
ssh "${REMOTE_USR}@${REMOTE_HOST}" "ls -1 ${REMOTE_DIR}" > ${r_files}

#-------------------------------------------------------------
# Extract cycle times from file names, dump into a Bash array
#-------------------------------------------------------------
mapfile -t raw_cycle_times < <(awk -F'.' '{print $2}' "${r_files}" | grep -E '^[0-9]{10}$' | sort -u)

#---------------------------------
# Filter out times >= CUTOFF_DATE 
#---------------------------------
cycle_times=()
for cycle in "${raw_cycle_times[@]}"; do
    if [ "$cycle" -lt "$CUTOFF_DATE" ]; then
        cycle_times+=( "$cycle" )
    fi
done

#-------------------------------------------------
# Process remaining cycle times on remote machine
#-------------------------------------------------
if [ "${#cycle_times[@]}" -gt 0 ]; then
    echo "Processing ${#cycle_times[@]} cycle time(s)..."

    # Construct match patterns
    patterns=""
    for cycle in "${cycle_times[@]}"; do
        patterns="$patterns \"$REMOTE_DIR\"/*.$cycle.*"
    done

    if [ "$DRY_RUN" = true ]; then
        echo "Files that WOULD be deleted on ${REMOTE_HOST}:"
        ssh "${REMOTE_USR}@${REMOTE_HOST}" "ls -d ${patterns} 2>/dev/null" || echo "No matching files found on remote server."
    else
        echo "Deleting matching files on ${REMOTE_HOST}..."
        ssh "${REMOTE_USR}@$REMOTE_HOST" "rm -f ${patterns}"
        echo "Deletion complete."
    fi
else
    echo "No cycle times remaining to delete."
fi

#------------------------------
# Remove remote filenames file
#------------------------------
rm ${r_files}
