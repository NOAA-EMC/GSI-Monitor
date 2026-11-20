#!/bin/bash

echo begin transfer_imgs.sh

if [[ ${C_IMGNDIR} != "/" ]]; then

   if [[ $MY_MACHINE = "wcoss2" ]]; then
      /usr/bin/rsync -ave ssh --exclude *.ctl.${Z} --delete-during ${C_IMGNDIR}/ \
         ${WEBUSER}@${WEBSVR}.ncep.noaa.gov:${WEBDIR}/
   fi
fi

echo end transfer_imgs.sh
exit
