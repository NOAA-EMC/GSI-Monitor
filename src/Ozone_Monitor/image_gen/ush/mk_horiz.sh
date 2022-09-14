#!/bin/bash

#------------------------------------------------------------------
#  mk_horiz.sh
#
#   - set up working directory
#   - build the cmdfile script
#   - submit plot job
#------------------------------------------------------------------

echo "begin mk_horiz.sh"

#------------------------------------------------------------------
# Define working directory for horiz plots
#
tmpdir=${WORKDIR}/horiz
rm -rf $tmpdir
mkdir -p $tmpdir
cd $tmpdir

export WORKDIR=$tmpdir

#------------------------------------------------------------------
#  Expand $OZN_TANKDIR_IMGS for horiz
#
export OZN_IMGS_HORIZ=${OZN_TANKDIR_IMGS}/horiz
if [[ ! -d ${OZN_IMGS_HORIZ} ]]; then
   mkdir -p ${OZN_IMGS_HORIZ}
fi

#------------------------------------------------------------------
# Loop over sat types & create entry in cmdfile for each.
#
suffix=a

data_source="ges anl"

for dsrc in ${data_source}; do

   cmdfile=cmdfile_${dsrc}_phoriz
   rm -f $cmdfile
>$cmdfile

   ctr=0
   for type in ${SATYPE}; do

      if [[ ${dsrc} = "ges" ]]; then
         list="obs ges obsges"
      else
         list="obs anl obsanl"
      fi

      if [[ ${MY_MACHINE} = "hera" || ${MY_MACHINE} = "jet" || ${MY_MACHINE} = "s4" ||
            ${MY_MACHINE} = "orion" ]]; then
         echo "$ctr ${OZN_IG_SCRIPTS}/plot_horiz.sh $type $suffix '$list' $dsrc" >> $cmdfile
      else
         echo "${OZN_IG_SCRIPTS}/plot_horiz.sh $type $suffix '$list' $dsrc" >> $cmdfile
      fi
      ((ctr=ctr+1))
   done

   chmod a+x $cmdfile

   job=${OZNMON_SUFFIX}_ozn_${dsrc}_phoriz
   o_logfile=${OZN_LOGDIR}/plot_horiz.${dsrc}.${PDATE}

   logf=${OZN_LOGDIR}/IG.${PDY}.${cyc}.${dsrc}.horiz.log
   if [[ -e $logf ]]; then
     rm -f $logf
   fi

   errf=${OZN_LOGDIR}/IG.${PDY}.${cyc}.${dsrc}.horiz.err
   if [[ -e $errf ]]; then
      rm -f $errf
   fi


   if [[ ${MY_MACHINE} = "hera" || ${MY_MACHINE} = "s4" || ${MY_MACHINE} = "orion" ]]; then

      $SUB --account ${ACCOUNT} -n $ctr  -o ${logf} -D . -J ${job} \
           --time=10 --wrap "srun -l --multi-prog ${cmdfile}"

   elif [[ ${MY_MACHINE} = "jet" ]]; then

      $SUB --account ${ACCOUNT} -n $ctr  -o ${logf} -D . -J ${job} \
           --time=10 --partition=$PARTITION_OZNMON --wrap "srun -l --multi-prog ${cmdfile}"

   elif [[ $MY_MACHINE = "wcoss2" ]]; then

      $SUB -q $JOB_QUEUE -A $ACCOUNT -o ${logf} -e ${errf} \
           -V -l select=1:mem=5000M -l walltime=20:00 -N ${job} ${cmdfile}

   fi
 
done

echo "end mk_horiz.sh"
exit
