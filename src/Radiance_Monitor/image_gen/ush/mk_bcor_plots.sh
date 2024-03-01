#!/bin/bash

#------------------------------------------------------------------
#
#  mk_bcor_plots.sh
#
#  Submit plot jobs to make the bcor images.
#
#  Log:
#   08/2010  safford  initial coding (adapted from bcor.sh).
#------------------------------------------------------------------

echo "begin mk_bcor_plots.sh"; echo

imgndir=${IMGNDIR}/bcor
if [[ ! -d ${imgndir} ]]; then
   mkdir -p ${imgndir}
fi


#-------------------------------------------------------------------
#  Locate/update the control files in $TANKverf/radmon.$pdy.  $pdy
#  starts at END_DATE and walks back to START_DATE until ctl files
#  are found or we run out of dates to check.  Report an error to
#  the log file and exit if no ctl files are found.
#
cycdy=$((24/$CYCLE_INTERVAL))           # number cycles per day
ndays=$(($NUM_CYCLES/$cycdy))           # number days in plot period

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

      #------------------------------------------------------------------
      #  Check to see if the *ctl* files for this $type are in $imgndir
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
            #---------------------------------------------------------------
            #  Determine if the bcor files are in a tar file.  If so
            #  extract the ctl files for this $type.  If both a compressed
            #  and uncompressed version of the radmon_bcor.tar file exist,
            #  flag that as an error condition.
            #
            #  Note that the ctl files are moved back to ${ieee_src}
            #  so the code block that follows will work with both 
            #  tarred and non-tarred storage schemes.
            #
            if [[ -e ${ieee_src}/radmon_bcor.tar && -e ${ieee_src}/radmon_bcor.tar.${Z} ]]; then
               echo "Located both radmon_bcor.tar and radmon_bcor.tar.${Z} in ${ieee_src}.  Unable to plot."
               exit 1
													
            elif [[ -e ${ieee_src}/radmon_bcor.tar || -e ${ieee_src}/radmon_bcor.tar.${Z} ]]; then
               using_tar=1
               ctl_list=`tar -tf ${ieee_src}/radmon_bcor.tar* | grep ${type} | grep ctl`
               if [[ ${ctl_list} != "" ]]; then
                  cwd=`pwd`
                  cd ${ieee_src}
                  tar -xf ./radmon_bcor.tar* ${ctl_list}            
                  cd ${cwd}
               fi
            fi

            #--------------------------------------------------
            #  Copy the *ctl* files to $imgndir, dropping
            #  'bcor.' from the file name. 
            #
            ctl_files=`ls $ieee_src/bcor.$type*.ctl*`
            prefix='bcor.'
            for file in $ctl_files; do
               newfile=`basename $file | sed -e "s/^$prefix//"` 
               $NCP ${file} ${imgndir}/${newfile}
               found=1
            done

            #------------------------------------------------------
            #  If there's a radmon_bcor.tar archive in ${ieee_src}
            #  then delete the extracted *ctl* files.
            if [[ $using_tar -eq 1 ]]; then
               rm -f ${ieee_src}/bcor.${type}*.ctl*
            fi
   
         fi
      fi

      if [[ ${found} -eq 0 ]]; then		# if not found try previous day
         if [[ $ctr -gt 0 ]]; then
            test_day=`$NDATE -24 ${test_day}`
            ctr=$(($ctr-1))
         fi
      fi

   done

   if [[ ${found} -eq 0 ]]; then
      rm_list="${rm_list} ${type}"
   fi

done

nctl=`ls ${imgndir}/*ctl* -1 | wc -l`
if [[ $nctl -le 0 ]]; then
   echo ERROR:  Unable to plot.  All bcor control files are missing.
   exit 14
fi

#---------------------------------------------------------------------
#  Remove all items from SATYPE for which we haven't found a ctl file
#
for type in ${rm_list}; do
   SATYPE=${SATYPE//$type/}
done


#-------------------------------------------------------------------
#   Update the time definition (tdef) line in the bcor control
#   files.

for type in ${SATYPE}; do
   if [[ -s ${imgndir}/${type}.ctl.${Z} ]]; then
     ${UNCOMPRESS} ${imgndir}/${type}.ctl.${Z}
   fi

   ${IG_SCRIPTS}/update_ctl_tdef.sh ${imgndir}/${type}.ctl ${START_DATE} ${NUM_CYCLES}
done

for sat in ${SATYPE}; do
   nchanl=`cat ${imgndir}/${sat}.ctl | gawk '/title/{print $NF}'`
   if [[ $nchanl -ge 100 ]]; then
      bigSATLIST=" $sat $bigSATLIST "      
   else         
      SATLIST=" $sat $SATLIST "
   fi
done

${COMPRESS} ${imgndir}/*.ctl


#------------------------------------------------------------------
#   Submit plot jobs
#
plot_list="count total fixang lapse lapse2 const scangl clw cos sin emiss ordang4 ordang3 ordang2 ordang1"

export PLOT_WORK_DIR=${PLOT_WORK_DIR}/plotbcor_${RADMON_SUFFIX}
if [[ -d ${PLOT_WORK_DIR} ]]; then 
   rm -f ${PLOT_WORK_DIR}
fi
mkdir -p ${PLOT_WORK_DIR}
cd ${PLOT_WORK_DIR}


#-------------------------------------------------------------------------
#  Loop over satellite/instruments and submit job.
#
suffix=a
cmdfile=cmdfile_pbcor_${suffix}
jobname=plot_${RADMON_SUFFIX}_bcor_${suffix}
logfile=${R_LOGDIR}/plot_bcor_${suffix}.log

rm -f ${cmdfile}
rm -f ${logfile}
>$cmdfile

ctr=0
for sat in ${SATLIST}; do
   if [[ $MY_MACHINE = "hera" || $MY_MACHINE = "jet" || 
         $MY_MACHINE = "s4"   || $MY_MACHINE = "orion" ||
         $MY_MACHINE = "hercules" ]]; then
      echo "${ctr} $IG_SCRIPTS/plot_bcor.sh $sat $suffix '$plot_list'" >> $cmdfile
   else   
      echo "$IG_SCRIPTS/plot_bcor.sh $sat $suffix '$plot_list'" >> $cmdfile
   fi
   ((ctr=ctr+1))
done

chmod 755 $cmdfile


if [[ $PLOT_ALL_REGIONS -eq 1 || $ndays -gt 30 ]]; then
   wall_tm="1:30"
else
   wall_tm="0:45"
fi

if [[ $MY_MACHINE = "hera" || $MY_MACHINE = "s4" ]]; then
   $SUB --account ${ACCOUNT} -n $ctr  -o ${logfile} -D . -J ${jobname} \
        --time=2:00:00 --wrap "srun -l --multi-prog ${cmdfile}"

elif [[ $MY_MACHINE = "orion" || $MY_MACHINE = "hercules" ]]; then
   $SUB --account ${ACCOUNT} -n $ctr  -o ${logfile} -D . -J ${jobname} --time=2:00:00 \
        -p ${SERVICE_PARTITION} --wrap "srun -l --multi-prog ${cmdfile}"

elif [[ $MY_MACHINE = "jet" ]]; then
   $SUB --account ${ACCOUNT} -n $ctr  -o ${logfile} -D . -J ${jobname} \
        -p ${BATCH_PARTITION} --time=2:00:00 --wrap "srun -l --multi-prog ${cmdfile}"

elif [[ $MY_MACHINE = "wcoss2" ]]; then
   $SUB -q $JOB_QUEUE -A $ACCOUNT -o ${logfile} -e ${R_LOGDIR}/plot_bcor_${suffix}.err \
        -V -l select=1:mem=1g -l walltime=1:00:00 -N ${jobname} ${cmdfile}

fi


#--------------------------------------------------------------------------
#  bigSATLIST
#  
#    Some satellite/instrument sources have so many channels that a separate
#    job to handle each plot type is the fastest solution.
#
#--------------------------------------------------------------------------
for sat in ${bigSATLIST}; do
   echo "processing $sat"
   suffix=$sat

   cmdfile=cmdfile_pbcor_${suffix}
   jobname=plot_${RADMON_SUFFIX}_bcor_${suffix}
   logfile=${R_LOGDIR}/plot_bcor_${suffix}.log

   rm -f $cmdfile
   rm ${logfile}
>$cmdfile

   ctr=0
   for var in $plot_list; do
      if [[ $MY_MACHINE = "hera" || $MY_MACHINE = "jet" || 
            $MY_MACHINE = "s4"   || $MY_MACHINE = "orion" ||
            $MY_MACHINE = "hercules" ]]; then
         echo "$ctr $IG_SCRIPTS/plot_bcor.sh $sat $var $var" >> $cmdfile
      else
         echo "$IG_SCRIPTS/plot_bcor.sh $sat $var $var" >> $cmdfile
      fi
      ((ctr=ctr+1))
   done

   chmod 755 $cmdfile

   if [[ $PLOT_ALL_REGIONS -eq 1 || $ndays -gt 30 ]]; then
      wall_tm="2:30"
   else
      wall_tm="1:00"
   fi

   if [[ $MY_MACHINE = "hera" || $MY_MACHINE = "s4" ]]; then
      $SUB --account ${ACCOUNT} -n $ctr  -o ${logfile} -D . -J ${jobname} \
           --time=1:00:00 --wrap "srun -l --multi-prog ${cmdfile}"

   elif [[ $MY_MACHINE = "orion" || $MY_MACHINE = "hercules" ]]; then
      $SUB --account ${ACCOUNT} -n $ctr  -o ${logfile} -D . -J ${jobname} --time=1:00:00 \
           -p ${SERVICE_PARTITION} --wrap "srun -l --multi-prog ${cmdfile}"

   elif [[ $MY_MACHINE = "jet" ]]; then
      $SUB --account ${ACCOUNT} -n $ctr  -o ${logfile} -D . -J ${jobname} \
           -p ${BATCH_PARTITION} --time=1:00:00 --wrap "srun -l --multi-prog ${cmdfile}"

   elif [[ $MY_MACHINE = "wcoss2" ]]; then
      $SUB -q $JOB_QUEUE -A $ACCOUNT -o ${logfile} -e ${R_LOGDIR}/plot_bcor_${suffix}.err \
	   -V -l select=1:mem=1g -l walltime=1:00:00 -N ${jobname} ${cmdfile}
   fi

   echo "submitted $sat"
done


echo "end mk_bcor_plots.sh"
exit 
