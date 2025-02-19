#!/bin/bash

if [[ ${TANKimg} != "/" && -d ${TANKimg} ]]; then

   if [[ ${INCLUDE_PNGS} == 1 ]]; then
      exclude="--exclude 'horiz'"
   else
      exclude="--exclude 'horiz' --exclude '*.png'"
   fi

   WEBSVR=${WEBSVR}.ncep.noaa.gov

   #----------------------------------------------------------
   # If the destination directory exists (on the server) then
   # sync the html there with the $TANKimg directory so we
   # have a backup copy.  Note the pngs subdirectory is 
   # skipped -- we only want to update the html and related
   # site files in $TANKimg, not the files in /pngs.  Also 
   # note that the use of the --update option means that if a 
   # file exists in both places the destination file is not 
   # updated if it's newer.
   #
   # Else create the destintation directory on the server.
   #----------------------------------------------------------

   if ssh ${WEBUSER}@${WEBSVR} "[ -d ${WEBDIR} ]"; then
      /usr/bin/rsync -ave ssh --exclude 'pngs/' --update \
         ${WEBUSER}@${WEBSVR}:${WEBDIR}/ ${TANKimg}
   else
      ssh ${WEBUSER}@${WEBSVR} "mkdir -p ${WEBDIR}"
   fi

   /usr/bin/rsync -ave ssh --exclude *.ctl.${Z} ${exclude} \
      --delete-during --update ${TANKimg}/ ${WEBUSER}@${WEBSVR}:${WEBDIR}/

else
   echo "Unable to run rsync, TANKimg has bad/no value of: ${TANKimg}"
fi

exit
