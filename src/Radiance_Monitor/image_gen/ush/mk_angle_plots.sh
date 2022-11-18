#!/bin/bash

#------------------------------------------------------------------
#
#  mk_angle_plots.sh
#
#  submit the plot jobs to create the angle images.
#
#  Log:
#   08/2010  safford  initial coding (adapted from angle.sh).
#------------------------------------------------------------------

echo; echo "Begin mk_angle_plots.sh"

export CYCLE_INTERVAL=${CYCLE_INTERVAL:-6}

imgndir=${IMGNDIR}/angle
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

cycdy=$((24/$CYCLE_INTERVAL))           # number cycles per day
ndays=$(($NUM_CYCLES/$cycdy))		# number of days in plot period
echo "ndays = $ndays"
rm_list=""

for type in ${SATYPE}; do
   found=0
   test_day=$PDATE

   if [[ $ndays -gt 10 ]]; then
      ctr=10
   else
      ctr=$ndays
   fi
 
   while [[ ${found} -eq 0 && $ctr -gt 0 ]]; do
 
      #---------------------------------------------------
      #  Check to see if the *ctl* files are in $imgndir
      #
      nctl=`ls ${imgndir} | grep $type | grep ctl`
      if [[ ${#nctl} -gt 0 ]]; then
         found=1
         echo "FOUND $type.ctl"

      else
         #-------------------------
         #  Locate $ieee_src
         #
	 ieee_src=`$MON_USH/get_stats_path.sh --run $RUN --pdate ${test_day} \
		    --net ${RADMON_SUFFIX} --tank ${R_TANKDIR} --mon radmon`

	 if [[ -d $ieee_src ]]; then
            using_tar=0
            #--------------------------------------------------------------
            #  Determine if the angle files are in a tar file.  If so
            #  extract the ctl files for this $type.  If both a compressed
            #  and uncompressed version of the radmon_bcoef.tar file exist,
            #  report that as an error condition.
            #
            if [[ -e ${ieee_src}/radmon_angle.tar && -e ${ieee_src}/radmon_angle.tar.${Z} ]]; then
               echo "Located both radmon_angle.tar and radmon_angle.tar.${Z} in ${ieee_src}.  Unable to plot."
               exit 2
   
            elif [[ -e ${ieee_src}/radmon_angle.tar || -e ${ieee_src}/radmon_angle.tar.${Z} ]]; then
               using_tar=1
               ctl_list=`tar -tf ${ieee_src}/radmon_angle.tar* | grep ${type} | grep ctl`
   
               if [[ ${#ctl_list} -gt 0 ]]; then
                  cwd=`pwd`
                  cd ${ieee_src}
                  tar -xf ./radmon_angle.tar* ${ctl_list}
                  cd ${cwd} 
               fi
            fi
 
            #-------------------------------------------------
            #  Copy the *ctl* files to $imgndir, dropping
            #  'angle' from the file name.
            #
            ctl_files=`ls $ieee_src| grep ctl | grep angle.$type`
            prefix='angle.'
            for file in $ctl_files; do
               newfile=`basename $file | sed -e "s/^$prefix//"`
               $NCP ${ieee_src}/${file} ${imgndir}/${newfile}
               found=1
            done

            #----------------------------------------------------------------
            #  If there's a radmon_angle.tar archive in ${ieee_src} then
            #  delete the extracted *ctl* files to leave just the tar files.
            #
            if [[ $using_tar -eq 1 ]]; then
               rm -f ${ieee_src}/angle.${type}.ctl*
               rm -f ${ieee_src}/angle.${type}_anl.ctl*
            fi
         fi

      fi

      if [[ ${found} -eq 0 ]]; then
	 #------------------------------------------
	 #  Step to the previous day and try again.
	 #
         if [[ $ctr -gt 0 ]]; then
            test_day=`$NDATE -24 ${test_day}`
            ctr=$(($ctr-1))
         fi
      fi
   done

   if [[ -s ${imgndir}/${type}.ctl.${Z} || -s ${imgndir}/${type}.ctl ]]; then
      allmissing=0
      found=1
   else
      echo "failed to find ${type}.ctl, adding to rm list"
      rm_list="${rm_list} ${type}"
   fi

done

if [[ $allmissing = 1 ]]; then
   echo ERROR:  Unable to plot.  All angle control files are missing from ${TANKverf} for requested date range.
   exit 3
fi

#---------------------------------------------------------------------
#  Remove all items from SATYPE for which we haven't found a ctl file
#
for type in ${rm_list}; do
   SATYPE=${SATYPE//$type/}
done

#-------------------------------------------------------------------
#   Separate the satypes by number of channels.
# 
for sat in ${SATYPE}; do

   if [[ -s ${imgndir}/${sat}.ctl.${Z} ]]; then
      ${UNCOMPRESS} ${imgndir}/${sat}.ctl.${Z}
   fi

   #-------------------------------------------------------------------
   #   Update the time definition (tdef) line in the time control
   #   files if we're plotting static images.
   #
   if [[ ${PLOT_STATIC_IMGS} -eq 1 ]]; then
      ${IG_SCRIPTS}/update_ctl_tdef.sh ${imgndir}/${sat}.ctl ${START_DATE} ${NUM_CYCLES}
      ${IG_SCRIPTS}/update_ctl_tdef.sh ${imgndir}/${sat}_anl.ctl ${START_DATE} ${NUM_CYCLES}
   fi

   #-------------------------------------------------------------------
   #  Separate the sources with a large number of channels.  These will
   #  be submitted in dedicated jobs, while the sources with a smaller
   #  number of channels will be submitted together.
   #
   nchanl=`cat ${imgndir}/${sat}.ctl | gawk '/title/{print $NF}'` 

   if [[ $nchanl -lt 100 ]]; then
      satlist=" $sat $satlist "
   else
      big_satlist=" $sat $big_satlist "
   fi

   ${COMPRESS} ${imgndir}/${sat}.ctl
done


echo; echo " satlist: ${satlist}"; echo
echo " big_satlist: ${big_satlist}"; echo


#-------------------------------------------------------------------
#   Rename PLOT_WORK_DIR to angle subdir.
#
export PLOT_WORK_DIR="${PLOT_WORK_DIR}/plotangle_${RADMON_SUFFIX}"

if [[ -d $PLOT_WORK_DIR ]]; then
   rm -f $PLOT_WORK_DIR
fi
mkdir -p $PLOT_WORK_DIR
cd $PLOT_WORK_DIR


#-----------------------------------------------------------------
# Loop over satellite types.  Submit job to make plots.
#
list="count penalty omgnbc total omgbc fixang lapse lapse2 const scangl clw cos sin emiss ordang4 ordang3 ordang2 ordang1"

suffix=a

if [[ -e ${cmdfile} ]]; then
   rm -f ${cmdfile}
fi
if [[ -e ${logfile} ]]; then
   rm -f ${logfile}
fi

if [[ -e ${R_LOGDIR}/plot_angle_${suffix}.log ]]; then
   rm ${R_LOGDIR}/plot_angle_${suffix}.log
fi

satarr=($satlist)

ctr=0
jobctr=1
itemctr=1
cmdfile=${PLOT_WORK_DIR}/cmdfile_pangle_${suffix}.${jobctr}

satarr_len=${#satarr[@]}
((satarr_len--))

while [[ $ctr -le ${satarr_len} ]]; do
   type=${satarr[${ctr}]}

   #--------------------------------------------------
   # sbatch (slurm) requires a line number added
   # to the cmdfile
   #
   if [[ ${MY_MACHINE} = "hera" || ${MY_MACHINE} = "jet" || 
         ${MY_MACHINE} = "s4"   || ${MY_MACHINE} = "orion" ]]; then
      echo "${itemctr} ${IG_SCRIPTS}/plot_angle.sh ${type} ${suffix} '${list}'" >> ${cmdfile}
   else
      echo "${IG_SCRIPTS}/plot_angle.sh ${type} ${suffix} '${list}'" >> ${cmdfile}
   fi

   ((itemctr++))

   #-------------------------------------
   #  Submit plot job, 4 satypes per job
   #
   if [[ $itemctr -gt 4 || $ctr -eq ${satarr_len} ]]; then
   
      chmod 755 ${cmdfile}

      jobname=plot_${RADMON_SUFFIX}_ang_${suffix}_${jobctr}
      logfile=${R_LOGDIR}/plot_angle_${suffix}_${jobctr}.log
      errfile=${R_LOGDIR}/plot_angle_${suffix}_${jobctr}.err

      if [[ ${MY_MACHINE} = "hera" || ${MY_MACHINE} = "s4" || ${MY_MACHINE} = "orion" ]]; then
         $SUB --account ${ACCOUNT} -n $ctr  -o ${logfile} -D . -J ${jobname} --time=30:00 \
              --wrap "srun -l --multi-prog ${cmdfile}"

      elif [[ ${MY_MACHINE} = "jet" ]]; then
         $SUB --account ${ACCOUNT} -n $ctr  -o ${logfile} -D . -J ${jobname} --time=30:00 \
              -p ${SERVICE_PARTITION} --wrap "srun -l --multi-prog ${cmdfile}"

      elif [[ $MY_MACHINE = "wcoss2" ]]; then
	 if [[ $NUM_CYCLES -gt 140 ]]; then
            walltm="1:20:00"
	 else
            walltm="40:00"
	 fi
         $SUB -q $JOB_QUEUE -A $ACCOUNT -o ${logfile} -e ${errfile} \
            	-V -l walltime=${walltm} -l select=1:ncpus=4:mem=32GB -N ${jobname} ${cmdfile}
      fi

      ((jobctr++)) 
   
      cmdfile=${PLOT_WORK_DIR}/cmdfile_pangle_${suffix}.${jobctr}
      itemctr=1

   fi

   ((ctr++))
done


#----------------------------------------------------------------------------
#  big_satlist
#   
#    There is so much data for some sat/instrument sources that a separate 
#    job for each is necessary.
#   

for sat in ${big_satlist}; do
   echo processing $sat in $big_satlist

   if [[ ${MY_MACHINE} = "wcoss2" ]]; then 	

      cmdfile=${PLOT_WORK_DIR}/cmdfile_pangle_${sat}
      if [[ -e ${cmdfile} ]]; then
         rm -f $cmdfile
      fi
      echo "$IG_SCRIPTS/plot_angle.sh $sat $sat ${list}" >> $cmdfile
      chmod 755 $cmdfile

      jobname=plot_${RADMON_SUFFIX}_ang_${sat}
      logfile=${R_LOGDIR}/plot_angle_${sat}.log
      if [[ -e ${logfile} ]]; then 
         rm ${logfile}
      fi

      errfile=${R_LOGDIR}/plot_angle_${sat}.err
      if [[ -e ${errfile} ]]; then
         rm ${errfile}
      fi
      $SUB -q $JOB_QUEUE -A $ACCOUNT -o ${logfile} -e ${R_LOGDIR}/plot_angle_${sat}.err \
           -V -l walltime=60:00 -N ${jobname} ${cmdfile}

   #---------------------------------------------------
   #  hera|jet|s4|orion, submit 1 job for each sat/list item
   elif [[ $MY_MACHINE = "hera" || $MY_MACHINE = "jet" || \
           $MY_MACHINE = "s4"   || $MY_MACHINE = "orion" ]]; then		

      ii=0
      logfile=${R_LOGDIR}/plot_angle_${sat}.log
      cmdfile=${PLOT_WORK_DIR}/cmdfile_pangle_${sat}
      rm -f $cmdfile

      logfile=${R_LOGDIR}/plot_angle_${sat}.log
      jobname=plot_${RADMON_SUFFIX}_ang_${sat}

      while [[ $ii -le ${#list[@]}-1 ]]; do
         echo "${ii} ${IG_SCRIPTS}/plot_angle.sh $sat $sat ${list[$ii]}" >> $cmdfile
         (( ii=ii+1 ))
      done

      if [[ $MY_MACHINE = "hera" ]]; then
         $SUB --account ${ACCOUNT} -n $ii  -o ${logfile} -D . -J ${jobname} --time=4:00:00 \
              --mem=0 --wrap "srun -l --multi-prog ${cmdfile}"

      elif [[ $MY_MACHINE = "orion" ]]; then
         $SUB --account ${ACCOUNT} -n $ii  -o ${logfile} -D . -J ${jobname} --time=4:00:00 \
              -p ${SERVICE_PARTITION} --mem=0 --wrap "srun -l --multi-prog ${cmdfile}"

      elif [[ $MY_MACHINE = "s4" ]]; then
         $SUB --account ${ACCOUNT} -n $ii  -o ${logfile} -D . -J ${jobname} --time=4:00:00 \
              --wrap "srun -l --multi-prog ${cmdfile}"

      else
         $SUB --account ${ACCOUNT} -n $ii  -o ${logfile} -D . -J ${jobname} --time=4:00:00 \
              -p ${SERVICE_PARTITION} --wrap "srun -l --multi-prog ${cmdfile}"
      fi

   fi

done


echo "End mk_angle_plots.sh"; echo

exit
