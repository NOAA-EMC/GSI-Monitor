#!/bin/bash

function usage {
  echo "Usage:  RunTransfer.sh [-r] suffix"
  echo "            Suffix is data source identifier that matches data in "
  echo "              the $MY_TANKDIR/stats directory."
  echo "        -r|--run   Specifies the RUN value, typically 'gdas'(default) or 'gfs'"
}

nargs=$#

if [[ $nargs -lt 1 || $nargs -gt 3 ]]; then
   usage
   exit 1
fi

RUN=gdas
RAD_AREA=glb

while [[ $# -ge 1 ]]
do
   key="$1"

   case $key in
      -r|--run)
         RUN=$2
         shift # past argument
      ;;
      -a|--area)
         RAD_AREA=$2
	 shift
      ;;
      *)
         #any unspecified key is RADMON_SUFFIX
         export RADMON_SUFFIX=$key
      ;;
   esac

   shift
done

this_dir=`dirname $0`
top_parm=${this_dir}/../../parm

radmon_config=${radmon_config:-${top_parm}/RadMon_config}
if [[ ! -e ${radmon_config} ]]; then
   echo "Unable to locate ${radmon_config} file"
   exit 3
fi

. ${radmon_config}
if [[ $? -ne 0 ]]; then
   echo "Error detected while sourcing ${radmon_config} file"
   exit $?
fi

radmon_user_settings=${radmon_user_settings:-${top_parm}/RadMon_user_settings}
if [[ ! -e ${radmon_user_settings} ]]; then
   echo "Unable to locate ${radmon_user_settings} file"
   exit 4
fi

. ${radmon_user_settings}
if [[ $? -ne 0 ]]; then
   echo "Error detected while sourcing ${radmon_user_settings} file"
   exit $?
fi


transfer_log=${R_LOGDIR}/Transfer_${RADMON_SUFFIX}.log
if [[ -e ${transfer_log} ]]; then
   rm ${transfer_log}
fi

transfer_err=${R_LOGDIR}/Transfer_${RADMON_SUFFIX}.err
if [[ -e ${transfer_err} ]]; then
   rm ${transfer_err}
fi

transfer_queue=dev_transfer
jobname=transfer_${RADMON_SUFFIX}
export WEBDIR=${WEBDIR}/${RADMON_SUFFIX}
echo WEBDIR  = $WEBDIR
echo IMGNDIR = $IMGNDIR

transfer_work_dir=${MON_STMP}/${RADMON_SUFFIX}/${RUN}/radmon/transfer
if [[ ! -d ${transfer_work_dir} ]]; then
   mkdir -p ${transfer_work_dir}
fi

cmdfile="${transfer_work_dir}/transfer_cmd"
echo "${IG_SCRIPTS}/transfer.sh" >$cmdfile
chmod 755 $cmdfile

if [[ ${MY_MACHINE} = "hera" ]]; then
   ${SUB} --account ${ACCOUNT}  --ntasks=1 --mem=500M --time=45:00 -J ${jobname} \
          --partition service -o ${transfer_log} ${IG_SCRIPTS}/transfer.sh

elif [[ ${MY_MACHINE} = "wcoss2" ]]; then
   $SUB -q $transfer_queue -A $ACCOUNT -o ${transfer_log} -e ${transfer_err} \
        -V -l select=1:mem=500M -l walltime=45:00 -N ${jobname} ${cmdfile}
fi

exit
