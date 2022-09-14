#!/bin/bash

#--------------------------------------------------------------------
#  OznMon_CP.sh
#
#    This script searches for new oznmon output from the global GDAS
#    and copies those filess to the user's $OZN_TANKDIR_STATS 
#    directory.
#
#    The bad_penalty, low count, and missing diag reports are 
#    reevaluated using local copies of the base file and satype
#    files in the $OZN_TANKDIR_STATS/info directory. 
#    
#    The unified error report is journaled to warning.${PDY}${CYC}.
#
#--------------------------------------------------------------------

function usage {
  echo "Usage:  OznMon_CP_glb.sh suffix [-r|--run gdas|gfs -p|--pdate yyyymmddhh"
  echo ""
  echo "            Suffix (NET) is the indentifier for this data source."
  echo ""
  echo "            -r|--run is the run value, typically gdas or gfs.  Default value is gdas." 
  echo ""
  echo "            -p|--pdate is 10 digit yyyymmddhh string of cycle to be copied."
  echo "                       If not specified the pdate will be calculated by finding the latest"
  echo "                       cycle time in $OZN_TANKDIR_STATS and incrementing it by 6 hours."
  echo ""
  echo "            --oznf parent directory to file location.  This will be extended by "
  echo "                       $RUN.$PDY/$CYC/atmos/oznmon and the files there copied to OZN_TANKDIR_STATS."
  echo ""
  echo "            --ostat directory of oznstat file."
}


echo start OznMon_CP.sh
exit_value=0

nargs=$#
if [[ $nargs -le 0 || $nargs -gt 9 ]]; then
   usage
   exit 1
fi

#-----------------------------------------------------------
#  Set default values and process command line arguments.
#
run=gdas
pdate=""
oznmon_file_loc=""
oznmon_stat_loc=""

while [[ $# -ge 1 ]]
do
   key="$1"
   echo $key

   case $key in
      -p|--pdate)
         pdate="$2"
         shift # past argument
      ;;
      -r|--run)
         run="$2"
         shift # past argument
      ;;
      --oznf)
         oznmon_file_loc="$2"
         shift # past argument
      ;;
      --ostat)
         oznmon_stat_loc="$2"
         shift # past argument
      ;;
      *)
         #any unspecified key is OZNMON_SUFFIX
         export OZNMON_SUFFIX=$key
      ;;
   esac

   shift
done

echo "OZNMON_SUFFIX    = $OZNMON_SUFFIX"
echo "run              = $run"
echo "pdate            = $pdate"
echo "oznmon_file_loc  = ${oznmon_file_loc}"
echo "oznmon_stat_loc  = ${oznmon_stat_loc}"

export RUN=${RUN:-${run}}


#--------------------------------------------------------------------
# Set environment variables
#--------------------------------------------------------------------
this_dir=`dirname $0`

top_parm=${this_dir}/../../parm

oznmon_user_settings=${oznmon_user_settings:-${top_parm}/OznMon_user_settings}
if [[ ! -e ${oznmon_user_settings} ]]; then
   echo "Unable to source ${oznmon_user_settings} file"
   exit 4
fi

. ${oznmon_user_settings}
if [[ $? -ne 0 ]]; then
   echo "Error detected while sourcing ${oznmon_user_settings} file"
   exit $?
fi

oznmon_config=${oznmon_config:-${top_parm}/OznMon_config}
if [[ ! -e ${oznmon_config} ]]; then
   echo "Unable to source ${oznmon_config} file"
   exit 3
fi

. ${oznmon_config}
if [[ $? -ne 0 ]]; then
   echo "Error detected while sourcing ${oznmon_config} file"
   exit $?
fi


if [[ ${oznmon_stat_loc} = "" ]]; then
   oznmon_stat_loc=${OZNSTAT_LOCATION}
fi


#---------------------------------------------------------------
# Create any missing directories.
#---------------------------------------------------------------
if [[ ! -d ${OZN_TANKDIR_STATS} ]]; then
   mkdir -p ${OZN_TANKDIR_STATS}
fi
if [[ ! -d ${OZN_LOGDIR} ]]; then
   mkdir -p ${OZN_LOGDIR}
fi

#---------------------------------------------------------------
# If the pdate (processing date) was not specified at the 
# command line then set it by finding the latest cycle in
# $OZN_TANKDIR_STATS and increment 6 hours.
#---------------------------------------------------------------
if [[ $pdate = "" ]]; then
   ldate=`${OZN_DE_SCRIPTS}/find_cycle.pl --run $RUN --cyc 1 --dir ${OZN_TANKDIR_STATS}`
   echo "OZN_DE_SCRIPTS = $OZN_DE_SCRIPTS"
   echo "RUN = $RUN"
   echo "OZN_TANKDIR_STATS = $OZN_TANKDIR_STATS"
   echo "ldate = $ldate"
   pdate=`${NDATE} +06 ${ldate}`
fi
export PDATE=${pdate}

export PDY=`echo $PDATE|cut -c1-8`
export CYC=`echo $PDATE|cut -c9-10`

#---------------------------------------------------------------
#  Verify the data files are available
#---------------------------------------------------------------
export OZNSTAT_LOCATION=${oznmon_stat_loc}/${RUN}.${PDY}/${CYC}/atmos


#---------------------------------------------------------------
#  The location of the extracted oznmon files can be found
#  using the OZNSTAT_LOCATION if data_location is not 
#  included in the arguments.
#
if [[ ${oznmon_file_loc} = "" ]]; then 
   data_location=${OZNSTAT_LOCATION}/oznmon
else
   data_location=${oznmon_file_loc}
   if [[ -d ${data_location}/${RUN}.${PDY}/${CYC}/atmos/oznmon ]]; then
      data_location=${data_location}/${RUN}.${PDY}/${CYC}/atmos/oznmon
   fi
fi

export DATA_LOCATION=${data_location}
export OZNSTAT=${OZNSTAT_LOCATION}/${RUN}.t${CYC}z.oznstat

#----------------------
#  Submit the copy job
#
if compgen -G "${DATA_LOCATION}/time/*${PDATE}*.ieee_d*" > /dev/null; then
   job=${OZN_DE_SCRIPTS}/oznmon_copy.sh
   jobname=OznMon_CP_${OZNMON_SUFFIX}

   logfile=${OZN_LOGDIR}/CP.${PDY}.${CYC}.log
   errfile=${OZN_LOGDIR}/CP.${PDY}.${CYC}.err
   if [[ -e ${logfile} ]]; then
     rm -f ${logfile}
   fi
   if [[ -e ${errfile} ]]; then
     rm -f ${errfile}
   fi

   if [[ $MY_MACHINE = "wcoss2" ]]; then
      $SUB -q $JOB_QUEUE -A $ACCOUNT -o ${logfile} -e ${errfile} \
           -V -l select=1:mem=5000M -l walltime=20:00 -N ${jobname} ${job}

   elif [[ $MY_MACHINE = "hera" ]]; then
      $SUB --account=${ACCOUNT} --time=10 -J ${jobname} -D . \
        -o ${logfile} --ntasks=1 --mem=5g ${job}

   elif [[ $MY_MACHINE = "orion" ]]; then
      echo submit job on orion
      $SUB --account=${ACCOUNT} --time=10 -J ${jobname} -D . \
        -o ${logfile} --ntasks=1 --mem=5g ${job}
   fi

else
   echo "Unable to locate extracted ozone data in DATA_LOCATION: ${DATA_LOCATION}"
   exit_value=4
fi


echo end OznMon_CP.sh
exit ${exit_value}

