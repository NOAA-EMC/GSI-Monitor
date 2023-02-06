#!/bin/bash

#-------------------------------------------------------------------
#
#  script:  mk_time_plots.sh
#
#  submit plot jobs to make the time images.
#  
#-------------------------------------------------------------------

echo; echo Start mk_time_plots.sh

imgndir=${IMGNDIR}/time
tankdir=${TANKverf}/time

if [[ ! -d ${imgndir} ]]; then
   mkdir -p ${imgndir}
fi

#-------------------------------------------------------------------
#  Locate/update the control files.  If no ctl file is available
#  report a warning to the log file.  Search order is $imgndir,
#  then $TANKverf/radmon.$pdy.
#
allmissing=1

cycdy=$((24/$CYCLE_INTERVAL))		# number cycles per day
ndays=$(($NUM_CYCLES/$cycdy))		# number days in plot period
echo ndays = $ndays

test_day=$PDATE
rm_list=""

#--------------------------------------------------------
#  Verify there are control files available in $imgndir 
#  for everything in $SATYPE.
#
for type in ${SATYPE}; do
   found=0
   test_day=$PDATE

   if [[ $ndays -gt 10 ]]; then
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

         using_tar=0
	 if [[ -d ${ieee_src} ]]; then
            #--------------------------------------------------
            #  Determine if the time files are in a tar file.  If so
            #  extract the ctl files for this $type.  If both a compressed
            #  and uncompressed version of the radmon_time.tar file exist,
            #  flag that as an error condition.
            #
            if [[ -e ${ieee_src}/radmon_time.tar && -e ${ieee_src}/radmon_time.tar.${Z} ]]; then
               echo "Located both radmon_time.tar and radmon_time.tar.${Z} in ${ieee_src}.  Unable to plot."
               exit 1

            elif [[ -e ${ieee_src}/radmon_time.tar || -e ${ieee_src}/radmon_time.tar.${Z} ]]; then
               using_tar=1
               ctl_list=`tar -tf ${ieee_src}/radmon_time.tar* | grep $type | grep ctl`
               if [[ ${ctl_list} != "" ]]; then
                  cwd=`pwd`
                  cd ${ieee_src}
                  ctl_list=`tar -tf ./radmon_time.tar* | grep $type | grep ctl`
                  tar -xf ${ieee_src}/radmon_time.tar* ${ctl_list}            
                  cd ${cwd}
               fi
            fi

            #--------------------------------------------------
            #  Copy the *ctl* files to $imgndir, dropping
            #  'time.' from the file name.
            #
            ctl_files=`ls $ieee_src/time.$type*.ctl* 2>/dev/null`

            prefix='time.'
            for file in $ctl_files; do
               newfile=`basename $file | sed -e "s/^$prefix//"`
               $NCP ${file} ${imgndir}/${newfile}
               found=1
            done

            #------------------------------------------------------
            #  If there's a radmon_time.tar archive in ${ieee_src} 
            #  then delete the extracted *ctl* files.
            if [[ $using_tar -eq 1 ]]; then
               rm -f ${ieee_src}/time.${type}.ctl*
               rm -f ${ieee_src}/time.${type}_anl.ctl*
            fi 
             
         fi
      fi

      if [[ ${found} -eq 0 ]]; then
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
   echo ERROR:  Unable to plot.  All time control files are missing.
   exit
fi

#---------------------------------------------------------------------
#  Remove all items from SATYPE for which we haven't found a ctl file
#
for type in ${rm_list}; do
   SATYPE=${SATYPE//$type/}
done

echo SATYPE = $SATYPE

#---------------------------------------------------------------
#  Sort out the bigSATLIST types using the number of channels.
#
for type in ${SATYPE}; do

   if [[ -s ${imgndir}/${type}.ctl.${Z} ]]; then
      ${UNCOMPRESS} ${imgndir}/${type}.ctl.${Z}
   fi

   #-------------------------------------------------------------------
   #   Update the time definition (tdef) line in the time control
   #   files if we're plotting static images. 
   #
   if [[ ${PLOT_STATIC_IMGS} -eq 1 ]]; then
      ${IG_SCRIPTS}/update_ctl_tdef.sh ${imgndir}/${type}.ctl ${START_DATE} ${NUM_CYCLES}
      ${IG_SCRIPTS}/update_ctl_tdef.sh ${imgndir}/${type}_anl.ctl ${START_DATE} ${NUM_CYCLES}
   fi

   nchanl=`cat ${imgndir}/${type}.ctl | gawk '/title/{print $NF}'`
   if [[ $nchanl -ge 100 ]]; then
      bigSATLIST=" $type $bigSATLIST "
   else
      SATLIST=" $type $SATLIST "
   fi
done

${COMPRESS} ${imgndir}/*.ctl


#-------------------------------------------------------------------
#  Summary plots
#
#    Submit the summary plot job.
#
#-------------------------------------------------------------------

jobname=plot_${RADMON_SUFFIX}_sum
logfile=${R_LOGDIR}/plot_summary.log
if [[ -e ${logfile} ]]; then
   rm ${logfile}
fi

if [[ ${MY_MACHINE} = "hera" || ${MY_MACHINE} = "s4" ]]; then
   ${SUB} --account ${ACCOUNT}  --ntasks=1 --mem=5g --time=1:00:00 -J ${jobname} \
          -o ${logfile} ${IG_SCRIPTS}/plot_summary.sh

elif [[ ${MY_MACHINE} = "orion" ]]; then
   ${SUB} --account ${ACCOUNT}  --ntasks=1 --mem=5g --time=20:00 -J ${jobname} \
          -o ${logfile} ${IG_SCRIPTS}/plot_summary.sh

elif [[ ${MY_MACHINE} = "jet" ]]; then
   ${SUB} --account ${ACCOUNT}  --ntasks=1 --mem=5g --time=1:00:00 -J ${jobname} \
          --partition ${BATCH_PARTITION} -o ${logfile} ${IG_SCRIPTS}/plot_summary.sh

elif [[ $MY_MACHINE = "wcoss2" ]]; then
   $SUB -q $JOB_QUEUE -A $ACCOUNT -o ${logfile} -e ${R_LOGDIR}/plot_summary.err -V \
          -l select=1:mem=1g -l walltime=30:00 -N ${jobname} ${IG_SCRIPTS}/plot_summary.sh
fi


#-------------------------------------------------------------------
#-------------------------------------------------------------------
#  Time plots
#
#    Submit the time plot jobs.
#-------------------------------------------------------------------
#-------------------------------------------------------------------


#-------------------------------------------------------------------
#   Rename PLOT_WORK_DIR to time subdir.
#
export PLOT_WORK_DIR="${PLOT_WORK_DIR}/plottime_${RADMON_SUFFIX}"
if [ -d $PLOT_WORK_DIR ] ; then
   rm -f $PLOT_WORK_DIR
fi
mkdir -p $PLOT_WORK_DIR
cd $PLOT_WORK_DIR

list="count penalty omgnbc total omgbc"

#-------------------------------------------------------------------
#  Build command file and submit plot job for intruments not on 
#    the bigSAT list.
#
suffix=a
jobname=plot_${RADMON_SUFFIX}_tm_${suffix}

cmdfile=${PLOT_WORK_DIR}/cmdfile_ptime_${suffix}
if [[ -e ${cmdfile} ]]; then
   rm -f $cmdfile
fi

logfile=${R_LOGDIR}/plot_time_${suffix}.log
if [[ -e ${logfile} ]]; then
   rm ${logfile}
fi

>$cmdfile

ctr=0

for sat in ${SATLIST}; do
   if [[ ${MY_MACHINE} = "hera" || ${MY_MACHINE} = "jet" || 
         ${MY_MACHINE} = "s4"   || ${MY_MACHINE} = "orion" ]]; then
      echo "${ctr} $IG_SCRIPTS/plot_time.sh $sat $suffix '$list'" >> $cmdfile
   else
      echo "$IG_SCRIPTS/plot_time.sh $sat $suffix '$list'" >> $cmdfile
   fi
   ((ctr=ctr+1))
done
chmod 755 $cmdfile


if [[ $MY_MACHINE = "hera" || $MY_MACHINE = "s4" ]]; then
   $SUB --account ${ACCOUNT} -n ${ctr}  -o ${logfile} -D . -J ${jobname} --time=1:00:00 \
        --wrap "srun -l --multi-prog ${cmdfile}"

elif [[ $MY_MACHINE = "orion" ]]; then
   $SUB --account ${ACCOUNT} -n ${ctr}  -o ${logfile} -D . -J ${jobname} --time=1:00:00 \
        -p $SERVICE_PARTITION --wrap "srun -l --multi-prog ${cmdfile}"

elif [[ $MY_MACHINE = "jet" ]]; then
   $SUB --account ${ACCOUNT} -n ${ctr}  -o ${logfile} -D . -J ${jobname} --time=1:00:00 \
        -p ${BATCH_PARTITION} --wrap "srun -l --multi-prog ${cmdfile}"

elif [[ $MY_MACHINE = "wcoss2" ]]; then
   $SUB -q $JOB_QUEUE -A $ACCOUNT -o ${logfile} -e ${R_LOGDIR}/plot_time_${suffix}.err -V \
        -l select=1:mem=1g -l walltime=1:00:00 -N ${jobname} ${cmdfile}
fi
      


#---------------------------------------------------------------------------
#  bigSATLIST
#
#    For some sat/instrument sources (airs_aqua, iasi, etc) there is so much 
#    data that a separate job for each provides a faster solution.
#   
#---------------------------------------------------------------------------
for sat in ${bigSATLIST}; do 
   jobname=plot_${RADMON_SUFFIX}_tm_${sat}

   cmdfile=${PLOT_WORK_DIR}/cmdfile_ptime_${sat}
   if [[ -e ${cmdfile} ]]; then
      rm -f ${cmdfile}
   fi

   logfile=${R_LOGDIR}/plot_time_${sat}.log
   if [[ -e ${logfile} ]]; then
      rm -f ${logfile}
   fi

   ctr=0 
   for var in $list; do
      if [[ ${MY_MACHINE} = "hera" || ${MY_MACHINE} = "jet" || 
            ${MY_MACHINE} = "s4"   || ${MY_MACHINE} = "orion" ]]; then
         echo "${ctr} $IG_SCRIPTS/plot_time.sh $sat $var $var" >> $cmdfile
      else
         echo "$IG_SCRIPTS/plot_time.sh $sat $var $var" >> $cmdfile
      fi
      ((ctr=ctr+1))
   done
   chmod 755 $cmdfile

   wall_tm="1:00"
   if [[ $PLOT_ALL_REGIONS -eq 1 || $ndays -gt 30 ]]; then
      wall_tm="2:30"
   fi

   if [[ $MY_MACHINE = "hera" || $MY_MACHINE = "s4" ]]; then
      $SUB --account ${ACCOUNT} -n ${ctr}  -o ${logfile} -D . -J ${jobname} --time=4:00:00 \
           --wrap "srun -l --multi-prog ${cmdfile}"

   elif [[ $MY_MACHINE = "orion" ]]; then
      $SUB --account ${ACCOUNT} -n ${ctr}  -o ${logfile} -D . -J ${jobname} --time=1:30:00 \
           -p $SERVICE_PARTITION --wrap "srun -l --multi-prog ${cmdfile}"

   elif [[ $MY_MACHINE = "jet" ]]; then
      $SUB --account ${ACCOUNT} -n ${ctr}  -o ${logfile} -D . -J ${jobname} --time=4:00:00 \
           -p ${BATCH_PARTITION} --wrap "srun -l --multi-prog ${cmdfile}"

   elif [[ $MY_MACHINE = "wcoss2" ]]; then
      logfile=${R_LOGDIR}/plot_time_${sat}.log
      if [[ -e ${logfile} ]]; then
         rm ${logfile}
      fi

      $SUB -q $JOB_QUEUE -A $ACCOUNT -o ${logfile} -e ${R_LOGDIR}/plot_time_${sat}.err -V \
           -l select=1:mem=1g -l walltime=1:30:00 -N ${jobname} ${cmdfile}
   fi

done


echo End mk_time_plots.sh; echo
exit
