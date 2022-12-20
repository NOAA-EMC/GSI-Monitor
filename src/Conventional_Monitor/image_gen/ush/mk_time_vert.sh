#!/bin/bash

#--------------------------------------------------
#
#  mk_time_vert.sh
#
#--------------------------------------------------

echo "--> mk_time_vert.sh"

   export PDY=`echo ${PDATE}|cut -c1-8`
   export CYC=`echo ${PDATE}|cut -c9-10`

   #--------------------------------------------
   #  submit time ps plots
   #--------------------------------------------
   jobname="${JOBNAME}_time_ps"
   pltfile="${C_IG_SCRIPTS}/plot_time_ps.sh"

   logfile="${C_LOGDIR}/plot_time_ps_${CONMON_SUFFIX}.${PDY}.${CYC}.log"
   if [[ -e ${logfile} ]]; then 
      rm -f $logfile
   fi

   errfile="${C_LOGDIR}/plot_time_ps_${CONMON_SUFFIX}.${PDY}.${CYC}.err"
   if [[ -e ${errfile} ]]; then
      rm -f $errfile
   fi

   if [[ ${MY_MACHINE} == "hera" || ${MY_MACHINE} == "s4" || \
         ${MY_MACHINE} == "jet" || ${MY_MACHINE} == "orion" ]]; then
      ${SUB} -A ${ACCOUNT} --ntasks=1 --time=00:15:00 \
                -p ${SERVICE_PARTITION} -J ${jobname} -o ${logfile} ${pltfile}

   elif [[ ${MY_MACHINE} == "wcoss2" ]]; then
      $SUB -V -q $JOB_QUEUE -A $ACCOUNT -o ${logfile} -e ${logfile} -l walltime=50:00 -N ${jobname} \
                -l select=1:mem=200M ${pltfile}
   fi

   #--------------------------------------------
   #  submit time plots
   #--------------------------------------------
   for type in gps q t uv; do
      jobname="${JOBNAME}_time_${type}"
      export TYPE=${type}
      pltfile="${C_IG_SCRIPTS}/plot_time.sh "

      logfile="${C_LOGDIR}/plot_time_${type}_${CONMON_SUFFIX}.${PDY}.${CYC}.log"
      if [[ -e ${logfile} ]]; then
         rm -f $logfile
      fi

      errfile="${C_LOGDIR}/plot_time_${type}_${CONMON_SUFFIX}.${PDY}.${CYC}.err"
      if [[ -e ${errfile} ]]; then
         rm -f $errfile
      fi

      if [[ ${MY_MACHINE} == "hera" || ${MY_MACHINE} == "s4" || \
            ${MY_MACHINE} == "jet" || ${MY_MACHINE} == "orion" ]]; then
         if [[ ${type} == "uv" || ${type} == "u" || ${type} == "v" ]]; then
            walltime="02:30:00"
         else
            walltime="00:40:00"
         fi
 
         ${SUB} -A ${ACCOUNT} --ntasks=1 --time=${walltime} \
                -p ${SERVICE_PARTITION} -J ${jobname} -o ${logfile} ${pltfile}

      elif [[ ${MY_MACHINE} == "wcoss2" ]]; then
         if [[ ${type} == "uv" || ${type} == "u" || ${type} == "v" ]]; then
            walltime="02:30:00"
         else
            walltime="50:00"
         fi

        $SUB -V -q ${JOB_QUEUE} -A ${ACCOUNT} -o ${logfile} -e ${logfile} -l walltime=${walltime}\
	       	-N ${jobname} -l select=1:mem=1G ${pltfile}
      fi

   done


   #--------------------------------------------
   #  submit vertical plots
   #--------------------------------------------
   for type in q t uv u v; do

      export TYPE=${type}
      jobname="${JOBNAME}_vert_${type}"
      pltfile="${C_IG_SCRIPTS}/plot_vert.sh "

      logfile="${C_LOGDIR}/plot_vert_${type}_${CONMON_SUFFIX}.${PDY}.${CYC}.log"
      if [[ -e ${logfile} ]]; then
         rm -f $logfile
      fi

      errfile="${C_LOGDIR}/plot_vert_${type}_${CONMON_SUFFIX}.${PDY}.${CYC}.err"
      if [[ -e ${errfile} ]]; then
         rm -f $errfile
      fi

      if [[ ${MY_MACHINE} == "hera" || ${MY_MACHINE} == "s4" || \
            ${MY_MACHINE} == "jet" || ${MY_MACHINE} = "orion" ]]; then
         if [[ ${type} == "uv" || ${type} == "u" || ${type} == "v" ]]; then
            walltime="00:50:00"
         else
            walltime="00:30:00"
         fi

         ${SUB} -A ${ACCOUNT} --ntasks=1 --time=${walltime} \
                -p ${SERVICE_PARTITION} -J ${jobname} -o ${logfile} ${pltfile}
     
      elif [[ ${MY_MACHINE} == "wcoss2" ]]; then
        ${SUB} -V -q ${JOB_QUEUE} -A ${ACCOUNT} -o ${logfile} -e ${logfile} -l walltime=50:00 \
         	-N ${jobname} -l select=1:mem=500M ${pltfile}

      fi
   done


echo "<-- mk_time_vert.sh"

exit
