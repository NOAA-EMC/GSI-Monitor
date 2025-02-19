#!/bin/bash
#--------------------------------------------------------------------
#
#  RadMon_IG_rgn.sh
#
#  Plot image files and queue transfer job.
#
#--------------------------------------------------------------------

#--------------------------------------------------------------------
#  usage
#--------------------------------------------------------------------
function usage {
  echo "Usage:  RadMon_IG_rgn.sh suffix [-p|--pdate -r|--run ]"
  echo ""
  echo "            suffix is the indentifier for this data source."
  echo "              This is usually the same as the NET value."
  echo ""
  echo "            -p|--pdate is the full YYYYMMDDHH cycle to run.  If not specified"
  echo "              the TANKverf directory will be used to determine the next cycle time"
  echo ""
  echo "            -r|--run  nam is the default if not specified."
  echo ""
}


echo "start RadMon_IG_rgn.sh"


nargs=$#
if [[ $nargs -lt 1 || $nargs -gt 5 ]]; then
   usage
   exit 1
fi

#-----------------------------------------------------------
#  Process command line arguments.
#
run=nam
tank=""
pdate=""

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
#      -t|--tank)
#	 tank="2"
#	 shift
#      ;;
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
#echo "tank          = ${tank}"		# not implemented yet

#--------------------------------------------------------------------
# Set environment variables
#--------------------------------------------------------------------
export RAD_AREA=rgn

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

export PLOT_ALL_REGIONS=0

#--------------------------------------------------------------------
#  Make sure $R_LOGDIR exists
#--------------------------------------------------------------------
if [[ -e ${R_LOGDIR} ]]; then
   mkdir -p $R_LOGDIR
fi

#--------------------------------------------------------------------
# Determine cycle to plot.  Exit if requested cycle is > last
# available data.
#
# PDATE can be set one of 3 ways.  This is the order of priority:
#
#   1.  Specified via command line argument
#   2.  Read from ${TANKimg}/last_plot_time file and advanced
#        one cycle.
#   3.  Using the last available cycle for which there is
#        data in ${R_TANKDIR}.
#
# If option 2 has been used the last_plot_time file will be 
# updated with ${PDATE} if the plot is able to run.
#--------------------------------------------------------------------
last_plot_time=${TANKimg}/last_plot_time
echo last_plot_time = $last_plot_time

latest_data=`${MON_USH}/rgn_find_cycle.pl --dir ${TANKverf} --mon radmon`

if [[ ${pdate} = "" ]]; then
   if [[ -e ${last_plot_time} ]]; then
      last_plot=`cat ${last_plot_time}`
      pdate=`$NDATE +${CYCLE_INTERVAL} ${last_plot}`
   else
      pdate=${latest_data}
   fi
fi

echo pdate = $pdate

if [[ ${pdate} -gt ${latest_data} ]]; then
   echo "Unable to plot, pdate is > latest_data, ${pdate}, ${latest_data}"
   exit 5
else
   echo "OK to plot"
fi

export PDATE=${pdate}
pdy=`echo $PDATE|cut -c1-8`

export START_DATE=`$NDATE -${NUM_CYCLES} $PDATE`


#-------------------------------------------------------------
#  Locate the satype file or set SATYPE by assembling a list
#  from available data files in $TANKverf/angle.
#-------------------------------------------------------------
satype_file=${TANKverf}/info/nam_radmon_satype.txt
if [[ ! -e $satype_file ]]; then
   satype_file=${HOMEnam}/fix/nam_radmon_satype.txt
fi

if [[ -s $satype_file ]]; then
   satype=`cat ${satype_file}`
else
   echo "Unable to locate satype_file: ${satype_file}"
fi

#-------------------------------------------------------------
#  Add any satypes not in the $satype_file for which we have
#  data.  This will get us a list of satypes to plot even if
#  the $satype_file can't be found.
#
echo "modifying satype list"
if [[ -d ${TANKverf}/radmon.${pdy} ]]; then
   test_list=`ls ${TANKverf}/radmon.${pdy}/*angle.*${PDATE}.ieee_d*`
fi

for test in ${test_list}; do
   this_file=`basename ${test}`

   if [[ ! $this_file =~ .*_anl.* ]]; then
      sat=`echo "${this_file}" | cut -d. -f2`
      if [[ ! $satype =~ .*${sat}.* ]]; then
         echo "adding ${sat} to satype"
         satype="${satype} ${sat}"
      fi
   fi
done
export SATYPE=${satype}

export PLOT_WORK_DIR=${PLOT_WORK_DIR}.${PDATE}
      
if [[ -d $PLOT_WORK_DIR ]]; then
   rm -rf $PLOT_WORK_DIR
fi    
mkdir -p $PLOT_WORK_DIR

if [[ ! -d ${PLOT_WORK_DIR} ]]; then
   echo "Unable to create PLOT_WORK_DIR:  ${PLOT_WORK_DIR}"
   exit 6
fi

cd $PLOT_WORK_DIR

#------------------------------------------------------------------
#   Submit plot jobs.
#
${IG_SCRIPTS}/mk_angle_plots.sh

${IG_SCRIPTS}/mk_bcoef_plots.sh

if [[ ${PLOT_STATIC_IMGS} -eq 1 ]]; then
   ${IG_SCRIPTS}/mk_bcor_plots.sh
fi

${IG_SCRIPTS}/mk_time_plots.sh


#--------------------------------------------------------------------
#  update last_plot_time if used
#
if [[ -e ${last_plot_time} ]]; then
   echo ${PDATE} > ${last_plot_time}
fi


#----------------------------------------------------------------------
#  Conditionally queue transfer to run
#
#       None:  The $run_time is a one-hour delay to the Transfer job
#              to ensure the plots are all finished prior to transfer.
#----------------------------------------------------------------------
if [[ $RUN_TRANSFER -eq 1 ]]; then

   cyc=`echo $PDATE|cut -c9-10`
   if [[ ${cyc} = "00" || ${cyc} = "06" || ${cyc} = "12" || ${cyc} = "18" ]]; then

      if [[ $MY_MACHINE = "wcoss2" ]]; then
         cmin=`date +%M`           # minute (MM)
         ctime=`date +%G%m%d%H`    # YYYYMMDDHH
         rtime=`$NDATE +1 $ctime`  # ctime + 1 hour

         rhr=`echo $rtime|cut -c9-10`
         run_time="$rhr:$cmin"     # HH:MM format for lsf (bsub command)

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

         export WEBDIR=${WEBDIR}/regional/${RADMON_SUFFIX}

         cmdfile="${PLOT_WORK_DIR}/transfer_cmd"
         echo "${IG_SCRIPTS}/transfer.sh" >$cmdfile
	 chmod 755 $cmdfile

         run_time="$rhr$cmin"      # HHMM format for qsub
         $SUB -q $transfer_queue -A $ACCOUNT -o ${transfer_log} -e ${transfer_err} \
              -V -l select=1:mem=500M -l walltime=30:00 -N ${jobname} -a ${run_time} ${cmdfile}

      fi
   fi
fi

#--------------------------------------------------------------------
#  remove all but the last 30 cycles of image files.
#--------------------------------------------------------------------
${IG_SCRIPTS}/rm_img_files.pl --dir ${TANKimg}/pngs --nfl 30

echo "end RadMon_IG_rgn.sh"
exit
