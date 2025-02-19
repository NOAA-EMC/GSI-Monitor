#!/usr/bin/bash

echo; echo "        -----------------------------"; echo

echo "All html and web support files have been created."; echo 
echo "Do you wish to transfer these files to the webserver now?"; echo

echo -n "  Enter YES to transfer now, any other input to decline.  > "
read text
short=`echo $text | cut -c1`

if [[ $short = "Y" || $short = "y" ]]; then

   echo; echo 
   echo "Submitting transfer job"

   if [[ ! -d ${R_LOGDIR} ]]; then
      mkdir -p ${R_LOGDIR}
   fi

   transfer_log=${R_LOGDIR}/Transfer_${RADMON_SUFFIX}.log
   if [[ -e ${transfer_log} ]]; then
      rm ${transfer_log}
   fi

   transfer_err=${R_LOGDIR}/Transfer_${RADMON_SUFFIX}.err
   if [[ -e ${transfer_err} ]]; then
      rm ${transfer_err}
   fi

   transfer_queue=dev_transfer
   jobname=transfer_${RADMON_SUFFIX}

   if [[ $RAD_AREA == 'glb' ]]; then
      export WEBDIR=${WEBDIR}/${RADMON_SUFFIX} 
   else
      export WEBDIR=${WEBDIR}/regional/${RADMON_SUFFIX}
   fi

   cmdfile="./transfer_cmd"
   echo "${IG_SCRIPTS}/transfer.sh" >$cmdfile
   chmod 755 $cmdfile

   $SUB -q $transfer_queue -A $ACCOUNT -o ${transfer_log} -e ${transfer_err} \
        -v "INCLUDE_PNGS=1, WEBSVR=${WEBSVR}, WEBUSER=${WEBUSER}, \
            WEBDIR=${WEBDIR}, TANKimg=${TANKimg}" \
        -l select=1:mem=500M -l walltime=30:00 -N ${jobname} ${cmdfile}

fi

