#!/bin/bash

if [[ ${IMGNDIR} != "/" ]]; then
   /usr/bin/rsync -ave ssh --exclude *.ctl.${Z} \
      --exclude 'horiz' --exclude *.png --delete-during ${IMGNDIR}/ \
      ${WEBUSER}@${WEBSVR}.ncep.noaa.gov:${WEBDIR}/
fi

exit
