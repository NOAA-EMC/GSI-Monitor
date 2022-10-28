#!/bin/bash

echo "start transfer.sh"

echo "OZN_IMGN_TANKDIR = ${OZN_IMGN_TANKDIR}"
echo "OZNMON_SUFFIX = ${OZNMON_SUFFIX}  "
echo "WEBSVR        = ${WEBSVR}"
echo "WEBUSER       = ${WEBUSER}"
echo "WEB_DIR       = ${WEB_DIR}"
echo "RSYNC         = ${RSYNC}"

if [[ ${OZN_IMGN_TANKDIR} != "/" ]]; then			# sanity check 

   if [[ $MY_MACHINE = "wcoss2" ]]; then

      WEB_DIR=${WEB_DIR}/${OZNMON_SUFFIX}/${RUN}
      ssh ${WEBUSER}@${WEBSVR}.ncep.noaa.gov "mkdir -p ${WEB_DIR}"

      #----------------------------------------------------------------
      #  use rsync to perform the file transfer
      #
      $RSYNC -ave ssh --delete-during ${OZN_TANKDIR_IMGS}/ \
         ${WEBUSER}@${WEBSVR}.ncep.noaa.gov:${WEB_DIR}/
   fi

fi

echo "end transfer.sh"
exit
