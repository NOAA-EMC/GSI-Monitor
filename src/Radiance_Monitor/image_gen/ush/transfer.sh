#!/bin/bash

function usage {
  echo "Usage:  Transfer.sh suffix"
  echo "            Suffix is data source identifier that matches data in "
  echo "              the $MY_TANKDIR/stats directory."
}


nargs=$#
if [[ $nargs -ne 1 ]]; then
   usage
   exit 1
fi

#---------------------------------------
#  set default values, parse arguments
#---------------------------------------
RADMON_SUFFIX=$1
echo "RADMON_SUFFIX = $RADMON_SUFFIX"

#--------------------------------------------------------------------

log_file=${LOGdir}/transfer_${RADMON_SUFFIX}.log
err_file=${LOGdir}/transfer_${RADMON_SUFFIX}.err

echo "IMGNDIR = ${IMGNDIR}"
echo "WEBDIR  = ${WEBDIR}"

if [[ ${IMGNDIR} != "/" ]]; then
   if [[ $MY_MACHINE = "wcoss2" ]]; then
      /usr/bin/rsync -ave ssh --exclude *.ctl.${Z} \
         --exclude 'horiz' --exclude *.png --delete-during ${IMGNDIR}/ \
         ${WEBUSER}@${WEBSVR}.ncep.noaa.gov:${WEBDIR}/
   fi
fi

exit
