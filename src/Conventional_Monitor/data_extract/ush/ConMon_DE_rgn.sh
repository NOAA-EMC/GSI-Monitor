#!/bin/bash

#--------------------------------------------------------------------
#
#  ConMon_DE_rgn.sh 
#
#  This is the top level data extraction script for the Conventional 
#  Data Monitor (ConMon) package for regional sources.  
#
#  C_DATDIR and C_GDATDIR (source directories for the cnvstat files) 
#  point to the operational data (NAM).  They can be overriden 
#  to process data from another source. 
#--------------------------------------------------------------------

#--------------------------------------------------------------------
#  usage
#--------------------------------------------------------------------
function usage {
  echo "Usage:  ConMon_DE_rgn.sh suffix [-p|--pdate pdate -c|-cnv /path/to/cnvstat/dir"
  echo "            Suffix is the indentifier for this data source."
  echo "            -p | --pdate yyyymmddcc to specify the cycle to be processed"
  echo "              if unspecified the last available date will be processed"
  echo "            -c | --cnv  location of the cnvstat and other essential files"
  echo " "
}

#------------------------------------------------------------------------------
# set_hr_tm() assigns the rgnTM and rgnHH vars which are file name components
#             in the rapid refresh scheme the nam uses.
#------------------------------------------------------------------------------
function set_hr_tm(){

   case $hr in
      00) rgnHH=t00z
          rgnTM=tm00;;
      01) rgnHH=t06z
	  rgnTM=tm05;;
      02) rgnHH=t06z
	  rgnTM=tm04;;
      03) rgnHH=t06z
          rgnTM=tm03;;
      04) rgnHH=t06z
          rgnTM=tm02;;
      05) rgnHH=t06z
          rgnTM=tm01;;
      06) rgnHH=t06z
          rgnTM=tm00;;
      07) rgnHH=t12z
          rgnTM=tm05;;
      08) rgnHH=t12z
          rgnTM=tm04;;
      09) rgnHH=t12z
          rgnTM=tm03;;
      10) rgnHH=t12z
          rgnTM=tm02;;
      11) rgnHH=t12z
          rgnTM=tm01;;
      12) rgnHH=t12z
          rgnTM=tm00;;
      13) rgnHH=t18z
          rgnTM=tm05;;
      14) rgnHH=t18z
          rgnTM=tm04;;
      15) rgnHH=t18z
          rgnTM=tm03;;
      16) rgnHH=t18z
          rgnTM=tm02;;
      17) rgnHH=t18z
          rgnTM=tm01;;
      18) rgnHH=t18z
          rgnTM=tm00;;
      19) rgnHH=t00z    # This is where the day changes.
          rgnTM=tm05
          use_next_day=1;;
      20) rgnHH=t00z
          rgnTM=tm04
          use_next_day=1;;
      21) rgnHH=t00z
          rgnTM=tm03
          use_next_day=1;;
      22) rgnHH=t00z
          rgnTM=tm02
          use_next_day=1;;
      23) rgnHH=t00z
          rgnTM=tm01
          use_next_day=1;;
   esac
}


#--------------------------------------------------------------------
#  ConMon_DE.sh begins here
#--------------------------------------------------------------------

echo "Begin ConMon_DE_rgn.sh"
exit_value=0

nargs=$#
if [[ ${nargs} -lt 1 || ${nargs} -gt 7 ]]; then
   usage
   exit 1
fi


#-----------------------------------------------
#  Process command line arguments
#

pdate=""
cnvstat_location=""

while [[ $# -ge 1 ]]
do
   key="$1"
   echo ${key}

   case ${key} in
      -p|--pdate)
         pdate="$2"
         shift # past argument
      ;;
      -c|--cnv)
         cnvstat_location="$2"
         shift # past argument
      ;;
      *)
         #any unspecified key is CONMON_SUFFIX
         export CONMON_SUFFIX=${key}
      ;;
   esac

   shift
done


this_file=`basename $0`
this_dir=`dirname $0`


nam_ver=v4.2

echo CONMON_SUFFIX = ${CONMON_SUFFIX}
echo cnvstat_location = ${cnvstat_location}
echo pdate = ${pdate}

export AREA='rgn'

top_parm=${this_dir}/../../parm

conmon_config=${conmon_config:-${top_parm}/ConMon_config}
if [[ -s ${conmon_config} ]]; then
   . ${conmon_config}
   echo "able to source ${conmon_config}"
else
   echo "Unable to source ${conmon_config} file"
   exit 3
fi



#--------------------------------------------------------------------
# Create any missing directories

if [[ ! -d ${C_TANKDIR} ]]; then
   mkdir -p ${C_TANKDIR}
fi
if [[ ! -d ${C_LOGDIR} ]]; then
   mkdir -p ${C_LOGDIR}
fi
if [[ ! -d ${C_IMGNDIR} ]]; then
   mkdir -p ${C_IMGNDIR}
fi


#--------------------------------------------------------------------
# Get date of cycle to process and/or previous cycle processed.
#
echo "C_TANKDIR: ${C_TANKDIR}"
if [[ ${#pdate} -le 0 ]]; then
   ldate=`${MON_USH}/rgn_find_cycle.pl --cyc 1 --dir ${C_TANKDIR} --mon conmon`
   pdate=`${NDATE} +01 ${ldate}`
fi

echo ldate, pdate = ${ldate}, ${pdate}

export PDY=`echo ${pdate}|cut -c1-8`
export CYC=`echo ${pdate}|cut -c9-10`
      
hr=${CYC}

rgnHH=''
rgnTM=''
use_next_day=0
   
set_hr_tm


if [[ ${#cnvstat_location} -le 0 ]]; then
   export cnvstat_location=${COMROOT}/nam/${nam_ver}
fi
export CNVSTAT_LOCATION=${cnvstat_location} 
echo cnvstat_location = ${cnvstat_location}

export C_DATDIR=${C_DATDIR:-${CNVSTAT_LOCATION}/${CONMON_SUFFIX}.${PDY}}
export C_COMIN=${C_DATDIR}
export CONMON_WORK_DIR=${CONMON_WORK_DIR:-${C_STMP_USER}/${CONMON_SUFFIX}}/conmon


#----------------------------------------------------------------------
#  cnvstat file
#
#  If processing one of the last 5 cycles for the day, look for
#  them in the next day's directory.  The $use_next_day variable, set
#  in set_hr_tm() flags this condition.
#----------------------------------------------------------------------
cnvstat=""
day=${PDY}
if [[ $use_next_day == 1 ]]; then
   pdate06=`${NDATE} +6 ${PDY}${CYC}`
   day=`echo ${pdate06} | cut -c1-8`
fi
export cnvstat=${cnvstat_location}/${CONMON_SUFFIX}.${day}/${CONMON_SUFFIX}.${rgnHH}.cnvstat.${rgnTM}
echo cnvstat: ${cnvstat}

if [[ -e ${cnvstat} ]]; then
   echo "cnvstat exists"
else
   echo "cnvstat is a no-go"
fi

#------------------------------------------------------------
# These definitions are intentionally commented out.  Error
# checking for regional data sources is not yet enabled, but 
# when it is, these definitions will become relevent.
##---------------------------------------------
## override the default convinfo definition
## if there's a copy in C_TANKDIR/info
##
#if [[ -e ${C_TANKDIR}/info/global_convinfo.txt ]]; then
#   echo " overriding convinfo definition"
#   export convinfo=${C_TANKDIR}/info/global_convinfo.txt
#fi
#
##---------------------------------------------
## override the default conmon_base definition
## if there's a copy in C_TANKDIR/info
##
#if [[ -e ${C_TANKDIR}/info/gdas_conmon_base.txt ]]; then
#   echo " overriding conmon_base definition"
#   export conmon_base=${C_TANKDIR}/info/gdas_conmon_base.txt
#fi

jobname=CM_RDE_${CONMON_SUFFIX}

if [[ -e ${cnvstat} ]]; then

   #------------------------------------------------------------------
   #   Submit data extraction job.
   #------------------------------------------------------------------
   logfile=${C_LOGDIR}/DE.${PDY}.${CYC}.log
   if [[ -e ${logfile} ]]; then
      rm -f ${logfile}
   fi

   if [[ ${MY_MACHINE} = "hera" || ${MY_MACHINE} = "s4" || ${MY_MACHINE} = "orion" ]]; then
      ${SUB} -A ${ACCOUNT} --ntasks=1 --time=00:30:00 \
  		-p ${SERVICE_PARTITION} -J ${jobname} -o ${C_LOGDIR}/DE.${PDY}.${CYC}.log \
		${HOMEnam_conmon}/jobs/JGDAS_ATMOS_CONMON

   elif [[ ${MY_MACHINE} = "jet" ]]; then
      ${SUB} -A ${ACCOUNT} -ntasks=1 --time=00:30:00 --mem=5000 \
		-p ${SERVICE_PARTITION} -J ${jobname} -o ${C_LOGDIR}/DE.${PDY}.${CYC}.log \
		${HOMEnam_conmon}/jobs/JGDAS_ATMOS_CONMON
      
   elif [[ ${MY_MACHINE} = "wcoss2" ]]; then
      ${SUB} -V -q ${JOB_QUEUE} -A ${ACCOUNT} -o ${logfile} -e ${logfile} -l walltime=30:00 \
  	      -N ${jobname} -l select=1:mem=5000M ${HOMEnam_conmon}/jobs/JNAM_CONMON
   fi

else
   echo "data not available -- missing $cnvstat file"
   exit_value=7
fi

echo "End ConMon_DE_rgn.sh"
exit ${exit_value}
