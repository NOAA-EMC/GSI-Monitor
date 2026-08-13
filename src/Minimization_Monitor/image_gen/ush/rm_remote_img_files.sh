#!/usr/bin/env bash
set -euo pipefail


while [[ $# -ge 1 ]]
do
   key="$1"
   echo $key

   case $key in
    -c|--cdt)
      [[ $# -ge 2 ]] || { echo "Error: $1 requires an argument." >&2; exit 1; }
      CUTOFF_DATE="$2"
      shift 2
      ;;
    -u|--usr)
      [[ $# -ge 2 ]] || { echo "Error: $1 requires an argument." >&2; exit 1; }
      export WEBUSER="$2"
      shift 2
      ;;
    -s|--svr)
      [[ $# -ge 2 ]] || { echo "Error: $1 requires an argument." >&2; exit 1; }
      export WEBSVR="$2"
      shift 2
      ;;
    -d|--dir)
      [[ $# -ge 2 ]] || { echo "Error: $1 requires an argument." >&2; exit 1; }
      export TARGET_DIR="$2"
      shift 2
      ;;
    *)
      echo "Error: Unknown option $1" >&2
      exit 1
      ;;
   esac
done

# Validate that all required parameters were provided
: "${CUTOFF_DATE:?Error: CUTOFF_DATE (-c|--cdt) is required.}"
: "${WEBUSER:?Error: WEBUSER (-u|--usr) is required.}"
: "${WEBSVR:?Error: WEBSVR (-s|--svr) is required.}"
: "${TARGET_DIR:?Error: TARGET_DIR (-d|--dir) is required.}"

echo "CUTOFF_DATE: $CUTOFF_DATE"
echo "WEBUSER:     $WEBUSER"
echo "WEBSVR:      $WEBSVR"
echo "TARGET_DIR:  $TARGET_DIR"

FORMATTED_CUTOFF="${CUTOFF_DATE:0:4}-${CUTOFF_DATE:4:2}-${CUTOFF_DATE:6:2} ${CUTOFF_DATE:8:2}:00:00"
echo "FORMATTED_CUTOFF: ${FORMATTED_CUTOFF}"

# Execute remotely via SSH
[[ "$TARGET_DIR" != "/" ]] || { echo "Error: TARGET_DIR must not be '/'." >&2; exit 1; }
ssh "${WEBUSER}@${WEBSVR}" bash -s -- "$TARGET_DIR" "$FORMATTED_CUTOFF" <<'EOF'
  set -euo pipefail
  TARGET_DIR="$1"
  FORMATTED_CUTOFF="$2"

  cd -- "$TARGET_DIR"

  REF_FILE=$(mktemp /tmp/ref_marker.XXXXXX)
  touch -d "$FORMATTED_CUTOFF" "$REF_FILE"

  echo "Removing files modified before: $FORMATTED_CUTOFF"
  find . -type f ! -newer "$REF_FILE" -delete

  rm -f "$REF_FILE"
EOF
