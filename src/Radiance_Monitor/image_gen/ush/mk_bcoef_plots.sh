#!/bin/bash

#------------------------------------------------------------------
#
# mk_bcoef_plots.sh
#
# submit the plot jobs to make the bcoef images.
#
#------------------------------------------------------------------

echo; echo "Start mk_bcoef_plots.sh"

imgndir="${IMGNDIR}/bcoef"

if [[ ! -d ${imgndir} ]]; then
   mkdir -p ${imgndir}
fi

#-------------------------------------------------------------------
#  Locate/update the control files in $TANKverf/radmon.$PDY.  $PDY
#  starts at END_DATE and walks back to START_DATE until ctl files
#  are found or we run out of dates to check.  Report an error to
#  the log file and exit if no ctl files are found.
#
allmissing=1
cycdy=$((24/$CYCLE_INTERVAL))

ndays=$(($NUM_CYCLES/$cycdy))
echo "ndays = $ndays"

test_day=$PDATE
rm_list=""

for type in ${SATYPE}; do
   found=0
   test_day=$PDATE

   if [[ ${ndays} -gt 10 ]]; then
      ctr=10
   elif [[ ${ndays} -le 0 ]]; then
      ctr=1
   else
      ctr=$ndays
   fi

   while [[ ${found} -eq 0 && $ctr -gt 0 ]]; do

      #---------------------------------------------------
      #  Check to see if the *ctl* files are in $imgndir
      #
      if compgen -G "${imgndir}${type}*ctl*" > /dev/null; then
         found=1

      else
         #-------------------------
         #  Locate $ieee_src
         #
         ieee_src=`$MON_USH/get_stats_path.sh --run $RUN --pdate ${test_day} \
		   --net ${RADMON_SUFFIX} --tank ${R_TANKDIR} --mon radmon`

	 if [[ -d ${ieee_src} ]]; then
            using_tar=0
            #--------------------------------------------------------------
            #  Determine if the bcoef files are in a tar file.  If so
            #  extract the ctl files for this $type.  If both a compressed
            #  and uncompressed version of the radmon_bcoef.tar file exist, 
            #  flag that as an error condition.
            #
            if [[ -e ${ieee_src}/radmon_bcoef.tar && -e ${ieee_src}/radmon_bcoef.tar.${Z} ]]; then
               echo "Located both radmon_bcoef.tar and radmon_bcoef.tar.${Z} in ${ieee_src}.  Unable to plot."
               exit 1

            elif [[ -e ${ieee_src}/radmon_bcoef.tar || -e ${ieee_src}/radmon_bcoef.tar.${Z} ]]; then
               using_tar=1
               ctl_list=`tar -tf ${ieee_src}/radmon_bcoef.tar* | grep ${type} | grep ctl`

               if [[ ${ctl_list} != "" ]]; then
                  cwd=`pwd`
                  cd ${ieee_src}
                  tar -xf ./radmon_bcoef.tar* ${ctl_list}
                  cd ${cwd}
               fi
            fi

            #--------------------------------------------------
            #  Copy the *ctl* files to $imgndir, dropping
            #  'bcoef.' from the file name.
            #
            ctl_files=`ls $ieee_src/bcoef.$type*.ctl* 2>/dev/null`
            prefix='bcoef.'
            for file in $ctl_files; do
               newfile=`basename $file | sed -e "s/^$prefix//"`
               $NCP ${file} ${imgndir}/${newfile}
               found=1
            done

            #-------------------------------------------------------
            #  If there's a radmon_bcoef.tar archive in ${ieee_src}
            #  then delete the extracted *ctl* files.
            if [[ $using_tar -eq 1 ]]; then
               rm -f ${ieee_src}/bcoef.${type}.ctl*
               rm -f ${ieee_src}/bcoef.${type}_anl.ctl*
            fi
         fi

      fi

      if [[ $found -eq 0 ]]; then
         test_day=`$NDATE -24 ${test_day}`
         ((ctr--))
      fi
   done

   
   if [[ -s ${imgndir}/${type}.ctl.${Z} || -s ${imgndir}/${type}.ctl ]]; then
      allmissing=0
      found=1
   else
      rm_list="${rm_list} ${type}"
   fi
done

if [[ $allmissing = 1 ]]; then
   echo "ERROR:  Unable to plot.  All bcoef control files are missing from ${TANKverf} for requested date range."
   exit 2
fi

#---------------------------------------------------------------------
#  Remove all items from SATYPE for which we haven't found a ctl file
#
for type in ${rm_list}; do
   SATYPE=${SATYPE//$type/}
done


if [[ ${PLOT_STATIC_IMGS} -eq 1 ]]; then
   for type in ${SATYPE}; do
      if [[ -s ${imgndir}/${type}.ctl.${Z} ]]; then
        ${UNCOMPRESS} ${imgndir}/${type}.ctl.${Z}
      fi

      ${IG_SCRIPTS}/update_ctl_tdef.sh ${imgndir}/${type}.ctl ${START_DATE} ${NUM_CYCLES}
      ${COMPRESS} ${imgndir}/${type}.ctl
   done
fi


#-------------------------------------------------------------------
# submit plot job
#

jobname="plot_${RADMON_SUFFIX}_bcoef"
logfile="$R_LOGDIR/plot_bcoef.log"
if [[ -e ${logfile} ]]; then
   rm ${logfile}
fi

if [[ $MY_MACHINE = "hera" || $MY_MACHINE = "s4" ]]; then
   $SUB --account $ACCOUNT --ntasks=1 --mem=5g --time=1:00:00 -J ${jobname} \
        -o ${logfile} -D . $IG_SCRIPTS/plot_bcoef.sh 

elif [[ $MY_MACHINE = "orion" ]]; then
   $SUB --account $ACCOUNT --ntasks=1 --mem=5g --time=20 -J ${jobname} \
        -p ${SERVICE_PARTITION} -o ${logfile} -D . $IG_SCRIPTS/plot_bcoef.sh 

elif [[ $MY_MACHINE = "jet" ]]; then
   $SUB --account $ACCOUNT --ntasks=1 --mem=5g --time=1:00:00 -J ${jobname} \
        -p ${BATCH_PARTITION} -o ${logfile} -D . $IG_SCRIPTS/plot_bcoef.sh

elif [[ $MY_MACHINE = "wcoss2" ]]; then
   $SUB -q $JOB_QUEUE -A $ACCOUNT -o ${logfile} -e $R_LOGDIR/plot_bcoef.err -V \
        -l select=1:mem=1g -l walltime=1:00:00 -N ${jobname} $IG_SCRIPTS/plot_bcoef.sh
fi

echo "End mk_bcoef_plots.sh"; echo
exit
