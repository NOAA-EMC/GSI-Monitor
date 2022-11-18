#!/bin/bash
#--------------------------------------------------------------------
#
#  RadMon_IG_glb.sh
#
#  RadMon image generation script for global data sources.
#  This script queues the plot and transfer scripts.
#
#--------------------------------------------------------------------


#--------------------------------------------------------------------
#  usage
#--------------------------------------------------------------------
function usage {
  echo "Usage:  RadMon_IG_glb.sh suffix [-p|--pdate -r|--run -n|--ncyc]"
  echo ""
  echo "            suffix is the indentifier for this data source."
  echo "              This is usually the same as the NET value."
  echo ""
  echo "            -p|--pdate is the full YYYYMMDDHH cycle to run.  If not specified"
  echo "              the TANKverf directory will be used to determine the next cycle time"
  echo ""
  echo "            -r|--run is gdas|gfs.  gdas is the default if not specified."
  echo ""
  echo "            -n|--ncyc is the number of cycles to be used in time series plots.  If"
  echo "              not specified the default value in parm/RadMon_user_settins will be used"
  echo ""
  echo "            -t | --tank parent directory to the adnmon data file location.  This"
  echo "              will be extended by \$RADMON_SUFFIX, \$RUN, and \$PDATE to locate the"
  echo "              extracted radmon data."
  echo ""
}

echo start RadMon_IG_glb.sh
echo

#--------------------------------------------------------------------
#  RadMon_DE_glb begins here.
#--------------------------------------------------------------------
exit_value=0

nargs=$#
if [[ $nargs -lt 1 || $nargs -gt 7 ]]; then
   usage
   exit 1
fi

#-----------------------------------------------------------
#  Set default values and process command line arguments.
#
run=gdas
pdate=""
num_cycles=""
tank=""

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
      -n|--ncyc)
         num_cycles="$2"
         shift # past argument
      ;;
      -t|--tank)
         tank="$2"
         shift # past argument
      ;;
      *)
         #any unspecified key is RADMON_SUFFIX
         export RADMON_SUFFIX=$key
      ;;
   esac

   shift
done

export RUN=${run}

echo "RADMON_SUFFIX = ${RADMON_SUFFIX}"
echo "RUN           = ${RUN}"
echo "pdate         = ${pdate}"
echo "num_cycles    = ${num_cycles}"

if [[ ${#num_cycles} -gt 0 ]]; then
   export NUM_CYCLES=${num_cycles}
fi

#--------------------------------------------------------------------
# Run config files to load environment variables, 
# set default plot conditions
#--------------------------------------------------------------------
this_dir=`dirname $0`
top_parm=${this_dir}/../../parm

radmon_config=${radmon_config:-${top_parm}/RadMon_config}
if [[ ! -e ${radmon_config} ]]; then
   echo "Unable to source ${radmon_config}"
   exit 2
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

if [[ ${#tank} -le 0 ]]; then
   tank=${TANKDIR}
fi
export R_TANKDIR=${tank}

if [[ ! -d ${IMGNDIR} ]]; then
   mkdir -p ${IMGNDIR}
fi

#--------------------------------------------------------------------
# Determine cycle to plot.  Exit if cycle is > last available
# data.
#
# PDATE can be set one of 3 ways.  This is the order of priority:
#
#   1.  Specified via command line argument
#   2.  Read from ${TANKimg}/last_plot_time file and advanced
#        one cycle.
#   3.  Using the last available cycle for which there is
#        data in ${TANKverf}.
#
# If option 2 has been used the last_plot_time file will be
# updated with ${PDATE} if the plot is able to run.
#--------------------------------------------------------------------
last_plot_time=${TANKimg}/last_plot_time

latest_data=`${MON_USH}/find_last_cycle.sh --net ${RADMON_SUFFIX} \
	                    --run ${RUN} --mon radmon --tank ${R_TANKDIR}`

if [[ ${pdate} = "" ]]; then
   if [[ -e ${last_plot_time} ]]; then
      echo " USING last_plot_time file"
      last_plot=`cat ${last_plot_time}`
      pdate=`$NDATE +6 ${last_plot}`
   else
      echo " USING find_last_cycle file"
      pdate=${latest_data}
   fi
fi


if [[ ${pdate} -gt ${latest_data} ]]; then
  echo "Unable to plot, pdate is > latest_data, ${pdate}, ${latest_data}"
  exit 5 
else
  echo "OK to plot"
fi

export PDATE=${pdate}

#--------------------------------------------------------------------
#  Make sure $R_LOGDIR exists
#--------------------------------------------------------------------
if [[ ! -e ${R_LOGDIR} ]]; then
   mkdir -p $R_LOGDIR
fi

#--------------------------------------------------------------------
#  Calculate start date (first cycle to be included in the plots --
#  PDATE is the latest/last cycle in the plots. 
#--------------------------------------------------------------------
hrs=`expr ${NUM_CYCLES} \\* -6`

export START_DATE=`${NDATE} ${hrs} ${PDATE}`
echo "span is start_date to pdate = ${START_DATE}, ${PDATE}"

export CYC=`echo $PDATE|cut -c9-10`
export PDY=`echo $PDATE|cut -c1-8`


#--------------------------------------------------------------------
#  Locate ieee_src in $TANKverf and verify data files are present
#
ieee_src=`$MON_USH/get_stats_path.sh --run $RUN --pdate ${pdate} --net ${RADMON_SUFFIX} --tank ${R_TANKDIR} --mon radmon`

if [[ ! -d ${ieee_src} ]]; then
   echo "Unable to set ieee_src, aborting plot"
   exit 6
fi

#-------------------------------------------------------------
# check $ieee_src for data files.  If none are found
# check contents of the radmon_angle.tar file.  If both
# a compressed and an uncompressed version of radmon_angle.tar
# exist, flag that condition as an error.

test_list=`find ${ieee_src} -name "angle.*${PDATE}.ieee_d*" -exec basename {} \;`

if [[ ${#test_list} -le 0 ]]; then
   if [[ -e ${ieee_src}/radmon_angle.tar && -e ${ieee_src}/radmon_angle.tar.${Z} ]]; then
      echo "Located both radmon_angle.tar and radmon_angle.tar.${Z} in ${ieee_src}.  Unable to plot."
      exit 7

   elif [[ -e ${ieee_src}/radmon_angle.tar || -e ${ieee_src}/radmon_angle.tar.${Z} ]]; then
      test_list=`tar -tf ${ieee_src}/radmon_angle.tar* | grep ieee_d`
   fi
fi

if [[ ${#test_list} -le 0 ]]; then
   echo " Missing ieee_src files, nfile_src = ${nfile_src}, aborting plot"
   exit 8
fi


export PLOT_WORK_DIR=${PLOT_WORK_DIR}.${PDATE}

if [[ -d $PLOT_WORK_DIR ]]; then
   rm -rf $PLOT_WORK_DIR
fi
mkdir -p $PLOT_WORK_DIR
cd $PLOT_WORK_DIR

#-------------------------------------------------------------
#  Locate the satype file or set SATYPE by assembling a list 
#  from available data files in $TANKverf/angle. 
#-------------------------------------------------------------
tankdir_info=${TANKverf}/info
satype_file=${satype_file:-${tankdir_info}/gdas_radmon_satype.txt}
if [[ ! -e $satype_file ]]; then
   satype_file=${HOMEgdas}/fix/gdas_radmon_satype.txt
fi

if [[ -s ${satype_file} ]]; then
   satype=`cat ${satype_file}`
else
   echo "Unable to locate satype_file: ${satype_file}"
fi

#-------------------------------------------------------------
#  Add any satypes not in the $satype_file for which we have
#  data.  This will get us a list of satypes to plot even if
#  the $satype_file can't be found.
#

list_array=($test_list)

for test in "${list_array[@]}"; do

   if [[ $test != *"_anl"* ]]; then
      tmp=`echo "$test" | cut -d. -f2`

      if [[ $satype != *${tmp}* ]]; then
         echo "adding $tmp to satype"
         satype="$satype $tmp"
      fi

   fi

done

export SATYPE=${satype}
echo; echo "SATYPE:  $SATYPE"; echo

#------------------------------------------------------------------
#   Start plot scripts.
#------------------------------------------------------------------
${IG_SCRIPTS}/mk_time_plots.sh

${IG_SCRIPTS}/mk_bcoef_plots.sh

${IG_SCRIPTS}/mk_angle_plots.sh

if [[ ${PLOT_STATIC_IMGS} -eq 1 ]]; then
   ${IG_SCRIPTS}/mk_bcor_plots.sh
fi

#--------------------------------------------------------------------
#  Check for log file and extract data for error report there
#--------------------------------------------------------------------
if [[ $DO_DATA_RPT -eq 1 ]]; then

   warn_file=${TANKverf}/${RUN}.${PDY}/${CYC}/${MONITOR}/warning.${PDATE}
   if [[ -e ${warn_file} ]]; then
      echo "mailing warning report"
      /bin/mail -s "RadMon warning" -c "${MAIL_CC}" ${MAIL_TO} < ${warn_file}
   fi

fi

#--------------------------------------------------------------------
#  Update the last_plot_time file if found
#--------------------------------------------------------------------
if [[ -e ${last_plot_time} ]]; then
   echo "update last_plot_time file"
   echo ${PDATE} > ${last_plot_time}
fi


#--------------------------------------------------------------------
#  Remove all but the last 30 cycles worth of data image files.
#--------------------------------------------------------------------
${IG_SCRIPTS}/rm_img_files.pl --dir ${TANKimg}/pngs --nfl 30


#----------------------------------------------------------------------
#  Conditionally queue transfer to run
# 
#	None:  The $run_time is a one-hour delay to the Transfer job
#  	       to ensure the plots are all finished prior to transfer.
#----------------------------------------------------------------------
if [[ $RUN_TRANSFER -eq 1 ]]; then

   if [[ $MY_MACHINE = "wcoss2" ]]; then
      cmin=`date +%M`		# minute (MM)
      ctime=`date +%G%m%d%H`	# YYYYMMDDHH
      rtime=`$NDATE +1 $ctime`	# ctime + 1 hour

      rhr=`echo $rtime|cut -c9-10`
      run_time="$rhr:$cmin"	# HH:MM format for lsf (bsub command) 		

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
      job="${IG_SCRIPTS}/Transfer.sh --nosrc ${RADMON_SUFFIX}"

      export WEBDIR=${WEBDIR}/${RADMON_SUFFIX}/${RUN}/pngs

      cmdfile="${PLOT_WORK_DIR}/transfer_cmd"
      echo "${IG_SCRIPTS}/Transfer.sh --nosrc ${RADMON_SUFFIX}" >$cmdfile
      chmod 755 $cmdfile

      run_time="$rhr$cmin"	# HHMM format for qsub
      $SUB -q $transfer_queue -A $ACCOUNT -o ${transfer_log} -e ${transfer_err} \
           -V -l select=1:mem=500M -l walltime=45:00 -N ${jobname} -a ${run_time} ${cmdfile}

   fi
fi


echo "exiting RadMon_IG_glb.sh"
exit
