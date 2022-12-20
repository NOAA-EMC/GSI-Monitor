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
  echo "            --ozndf parent directory to the oznmon data file location.  This will be extended by "
  echo "                       $OZNMON_SUFFIX, $RUN, and $PDATE to locate the extracted oznmon data."
  echo ""
  echo "            --ostat parent directory to the oznstat file.  This is only needed if DO_DATA_RPT"
  echo "                       (in parm/OznMon_user_settings) is set to 1. This location will be "  
  echo "                       extended using $OZNMON_SUFFIX, $RUN, and $PDATE to locate the oznstat file."
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
ozn_df_dir=""
ozn_stat_dir=""

while [[ $# -ge 1 ]]
do
   key="$1"

   case $key in
      -p|--pdate)
         pdate="$2"
         shift # past argument
      ;;
      -r|--run)
         run="$2"
         shift # past argument
      ;;
      --ozndf)
         ozn_df_dir="$2"
         shift # past argument
      ;;
      --ostat)
         ozn_stat_dir="$2"
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
echo "ozn_df_dir       = ${ozn_df_dir}"
echo "ozn_stat_dir     = ${ozn_stat_dir}"

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

if [[ ${ozn_df_dir} = "" ]]; then
   ozn_df_dir=${OZN_DATA_DIR}
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
   ldate=`${MON_USH}/find_last_cycle.sh --net ${OZNMON_SUFFIX} --run ${RUN} --tank ${OZN_TANKDIR_STATS} --mon oznmon`
   pdate=`${NDATE} +06 ${ldate}`
   echo "PDATE set to $pdate"
fi
export PDATE=${pdate}

export PDY=`echo $PDATE|cut -c1-8`
export CYC=`echo $PDATE|cut -c9-10`


#---------------------------------------------------------------
#  Verify the data files are available
#---------------------------------------------------------------
data_dir=""
data_dir=`$MON_USH/get_stats_path.sh --run $RUN --pdate ${pdate} --net ${OZNMON_SUFFIX} --tank ${ozn_df_dir} --mon oznmon`

export OZN_DATA_DIR=${data_dir}
echo "OZN_DATA_DIR = $OZN_DATA_DIR"


#--------------------------------------------------------
#  If DO_DATA_RPT then attempt to find the oznstat file.
#--------------------------------------------------------
OZNSTAT=""  
if [[ ${DO_DATA_RPT} -eq 1 ]]; then
   oznstat=${OZN_DATA_DIR}/../${RUN}.t${CYC}z.oznstat
   if [[ -f ${oznstat} ]]; then
      OZNSTAT=${oznstat} 
   else
      echo "unable to locate ${oznstat}, setting DO_DATA_RPT to 0"
      DO_DATA_RPT=0
   fi
fi
export OZNSTAT=${OZNSTAT}


#----------------------
#  Submit the copy job
#
if compgen -G "${OZN_DATA_DIR}/time/*${PDATE}*.ieee_d*" > /dev/null; then

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
   echo "Unable to locate extracted ozone data in OZN_DATA_DIR: ${OZN_DATA_DIR}"
   exit_value=4
fi


echo end OznMon_CP.sh
exit ${exit_value}

