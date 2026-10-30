#!/bin/bash

#--------------------------------------------------------------------
#  usage
#--------------------------------------------------------------------
function usage {
  echo "Usage:  ConMon_IG.sh suffix [-r|--run gdas|gfs -a|--area glb|rgn]"
  echo "            Suffix is the indentifier for this data source."
  echo "            -r | --run   the gdas|gfs run to be processed"
  echo "              use only if data in TANKdir stores both runs, otherwise"
  echo "              gdas is assumed."
  echo "            -a | --area  glb or rgn.  Default is glb"
  echo " "
}

nargs=$#
if [[ $nargs -lt 1 || $nargs -gt 5 ]]; then
   usage
   exit 1
fi

#-----------------------------------------------
#  Process command line arguments
#
while [[ $# -ge 1 ]]
do
   key="$1"
   echo $key

   case $key in
      -r|--run)
         run="$2"
         shift # past argument
      ;;
      -a|--area)
         area="$2"
         shift # past argument
      ;;
      *)
         #any unspecified key is CONMON_SUFFIX
         export CONMON_SUFFIX=$key
      ;;
   esac

   shift
done

export AREA="${area:-glb}"
if [[ ${AREA} = "glb" ]]; then
   export RUN="${run:-gdas}"
fi

this_file=`basename $0`
this_dir=`dirname $0`

top_parm=${this_dir}/../../parm
export CMON_CONFIG=${CMON_CONFIG:-${top_parm}/ConMon_config}
export CMON_USER_SETTINGS=${CMON_USER_SETTINGS:-${top_parm}/ConMon_user_settings}

if [[ -s ${CMON_CONFIG} ]]; then
   . ${CMON_CONFIG}
else
   echo "ERROR:  Unable to source ${CMON_CONFIG}"
   exit 1
fi


logfile=${C_LOGDIR}/transfer_${CONMON_SUFFIX}.log
if [[ -e ${logfile} ]]; then
   rm ${logfile}
fi

errfile=${C_LOGDIR}/transfer_${CONMON_SUFFIX}.err
if [[ -e ${errfile} ]]; then
   rm ${errfile}
fi

WEBDIR=${WEBDIR}/${CONMON_SUFFIX}
if [[ ${AREA} = "glb" ]]; then
   WEBDIR=${WEBDIR}/${RUN}
fi

echo "WEBDIR: $WEBDIR"
echo "/home/people/emc/www/htdocs/gmb/gdas/es_conv/rrfs/pngs"

export JOB_QUEUE=dev_transfer
export jobname=transfer_${CONMON_SUFFIX}_conmon

#--------------------------------------------------------
#  Note that transfers from hera are not straightforward,
#  and must go through a system that is allowed to access
#  emcrzdm.  This script will just report that situation
#  and leave it to the user to manually transfer files to
#  the server.
#
if [[ ${MY_MACHINE} = "wcoss2" ]]; then

   ${SUB} -q ${JOB_QUEUE} -A ${ACCOUNT} -o ${logfile} -e ${errfile} \
        -V -l select=1:mem=500M -l walltime=45:00 -N ${jobname} \
        ${C_IG_SCRIPTS}/transfer_imgs.sh

else
   echo "Unable to transfer files from ${MY_MACHINE} to ${WEBSVR}."
   echo "Manual intervention is required."

fi


echo end Transfer.sh
exit
