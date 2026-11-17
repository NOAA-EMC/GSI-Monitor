#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
shared="$root/src/Radiance_Monitor/nwprod/radmon_shared/sorc"
extract="$root/src/Radiance_Monitor/data_extract/sorc/radmon_validate_tm.fd"

for validation in "$shared/verf_radtime.fd" "$extract"; do
  mkdir "$work/run"
  cd "$work/run"
  "${FC:-gfortran}" ${FFLAGS:-} -ffree-line-length-0 -fcheck=all \
    "$validation/valid.f90" "$validation/bad_chan.f90" \
    "$validation/low_count.f90" "$validation/bad_penalty.f90" \
    "$shared/verf_radtime.fd/create_ctl_time.f90" \
    "$shared/verf_radang.fd/create_ctl_angle.f90" \
    "$shared/verf_radbcor.fd/create_ctl_bcor.f90" \
    "$shared/verf_radbcoef.fd/create_ctl_bcoef.f90" \
    "$root/tests/radiance_names.f90" -o radiance_names
  ./radiance_names
  cd "$work"
  rm -r -- "$work/run"
done
