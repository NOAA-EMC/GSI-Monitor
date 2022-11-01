#!/bin/bash

#  MinMon data copy script

#--------------------------------------------------------------------
#  usage
#--------------------------------------------------------------------
function usage {
  echo "Usage:  MinMon_CP.sh suffix [-p|--pdate pdate -r|--run gdas|gfs]"
  echo "            Suffix is the indentifier for this data source."
  echo "            -p | --pdate yyyymmddcc to specify the cycle to be processed"
  echo "              if unspecified the last available date will be processed"
  echo "            -r | --run   the gdas|gfs run to be processed"
  echo "              use only if data in TANKdir stores both runs"
  echo "            -d | --data  base location of minmon data without any"
  echo "              date-dependent subdirectories"
  echo " "
}

#--------------------------------------------------------------------
#  MinMon_DE.sh begins here
#--------------------------------------------------------------------

nargs=$#
if [[ $nargs -lt 1 || $nargs -gt 7 ]]; then
   usage
   exit 1
fi

#-----------------------------------------------
#  Process command line arguments
#
pdate=""
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
      -d|--data)                       # base location of minmon data 
         data="$2"
         shift # past argument
      ;;
      *)
         #any unspecified key is MINMON_SUFFIX
         export MINMON_SUFFIX=$key
      ;;
   esac

   shift
done

if [[ $data = "" ]]; then
   data=/lfs/h1/ops/prod/com		# default to wcoss2 operational data
fi

if [[ $run = "" ]]; then
   run=gdas
fi

#-----------------------------------
#  source config and settings files
#
this_dir=`dirname $0`
top_parm=${this_dir}/../../parm

minmon_config=${minmon_config:-${top_parm}/MinMon_config}
if [[ ! -e ${minmon_config} ]]; then
   echo "Unable to locate ${minmon_config} file"
   exit 3
fi

. ${minmon_config}
if [[ $? -ne 0 ]]; then
   echo "Error detected while sourcing ${minmon_config} file"
   exit $?
fi


minmon_user_settings=${minmon_user_settings:-${top_parm}/MinMon_user_settings}
if [[ ! -e ${minmon_user_settings} ]]; then
   echo "Unable to locate ${minmon_user_settings} file"
   exit 4
fi

. ${minmon_user_settings}
if [[ $? -ne 0 ]]; then
   echo "Error detected while sourcing ${minmon_user_settings} file"
   exit $?
fi


#------------------------------------------------------------------------------------
#  If pdate was not supplied, find the last cycle in TANKDIR and increment one cycle
#
if [[ $pdate = "" ]]; then
   ldate=`${MON_USH}/find_last_cycle.sh --net ${MINMON_SUFFIX} --run ${run} --mon minmon --tank ${TANKDIR}`
   pdate=`${NDATE} +06 $ldate`
fi

echo "pdate = $pdate"

pdy=`echo $pdate|cut -c1-8`
cyc=`echo $pdate|cut -c9-10`

#----------------------------------------------
#  Create the new directory to store the data
#
min_tank=${M_TANKverf}/${MINMON_SUFFIX}/${run}.${pdy}/${cyc}/minmon
if [[ ! -d ${min_tank} ]]; then
   mkdir -p ${min_tank}
fi

#---------------------------------------------------------------
#  Verify the data files are available for this cycle
#
data_dir=""
data_dir=`$MON_USH/get_stats_path.sh --run $RUN --pdate ${pdate} --net ${MINMON_SUFFIX} --tank ${data} --mon minmon`
echo data_dir = $data_dir

if [[ ! -d ${data_dir} ]]; then
   echo "Unable to copy, ${data_dir} not found"
   exit 5
fi

cp ${data_dir}/*${pdate}* ${min_tank}/.
cp ${data_dir}/gnorm_data.txt ${min_tank}/.


