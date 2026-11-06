#!/bin/bash

#--------------------------------------------------------------------
#
#  ConMon_IG.sh 
#
#  This is the top level image generation script for the Conventional 
#  Data Monitor (ConMon) package.  
#
#--------------------------------------------------------------------

#--------------------------------------------------------------------
#  usage
#--------------------------------------------------------------------
function usage {
  echo " "
  echo " "
  echo "Usage:  ConMon_IG.sh suffix [-p|--pdate pdate -r|--run gdas|gfs -n|--ncyc -a|--area]"
  echo " "
  echo "            Suffix is the indentifier for this data source."
  echo " "
  echo "            -p | --pdate yyyymmddcc to specify the cycle to be plotted."
  echo "                 If not specified, pdate will be set using the "
  echo "                 C_IMGNDIR/last_plot_time file, and if that doesn't"
  echo "                 exist, then the last available date will be plotted."
  echo " "             
  echo "            -r | --run   the gdas|gfs run to be processed."
  echo "                 Use only if data in TANKdir stores both runs."
  echo "                 Default value is gdas"
  echo " "
  echo "            -n | --ncyc is the number of cycles to be used in time series plots.  If"
  echo "              not specified the default value in parm/RadMon_user_settins will be used"
  echo " "
  echo "            -a | --area may be glb (global) or rgn (regional).  Default is 'glb'."
  echo " "
}


#--------------------------------------------------------------------
#  CMon_IG.sh begins here
#--------------------------------------------------------------------

echo "Begin ConMon_IG.sh"


nargs=$#
if [[ $nargs -lt 1 || $nargs -gt 9 ]]; then
   usage
   exit 1
fi

#-----------------------------------------------
#  Process command line arguments
#
PDATE=""
AREA="glb"

while [[ $# -ge 1 ]]
do
   key="$1"
   echo $key

   case $key in
      -p|--pdate)
         export PDATE="$2"
         shift # past argument
      ;;
      -r|--run)
         RUN="$2"
         shift # past argument
      ;;
      -n|--ncyc)
         NUM_CYCLES="$2"
         shift # past argument
      ;;
      -a|--area)
         AREA="$2"
         shift # past argument
      ;;
      *)
         #any unspecified key is CONMON_SUFFIX
         export CONMON_SUFFIX=$key
      ;;
   esac

   shift
done

#--------------------------------------------------------------------
# Run config files to load environment variables,
# set default plot conditions
#--------------------------------------------------------------------
#this_file=`basename $0`
this_dir=`dirname $0`
top_parm=${this_dir}/../../parm

conmon_config=${conmon_config:-${top_parm}/ConMon_config}
if [[ -s ${conmon_config} ]]; then
   . ${conmon_config}
   echo "able to source ${conmon_config}"
else
   echo "Unable to source ${conmon_config} file"
   exit 3
fi

module list

export RUN="${RUN:-gdas}"
export AREA="${AREA:-glb}"
export NUM_CYCLES="${NUM_CYCLES:-120}"

#--------------------------------------------------------------------
# CYCLE_INTERVAL is 6 hrs for global (default) and 1 hr for regional
#--------------------------------------------------------------------
if [[ ${AREA} = 'rgn' ]]; then
   CYCLE_INTERVAL=1
fi
export CYCLE_INTERVAL="${CYCLE_INTERVAL:-6}"

echo "CONMON_SUFFIX  = $CONMON_SUFFIX"
echo "AREA           = $AREA"
echo "PDATE          = $PDATE"
echo "RUN            = $RUN"
echo "NUM_CYCLES     = $NUM_CYCLES"
echo "CYCLE_INTERVAL = $CYCLE_INTERVAL"

#--------------------------------------------------------------------
#  Create LOGdir as needed
#--------------------------------------------------------------------
if [[ ! -d ${C_LOGDIR} ]]; then
   mkdir -p $C_LOGDIR
fi

#--------------------------------------------------------------------
# Determine cycle to plot.  Exit if cycle is > last available
# data ($PDATE -gt $last_cycle).
#
# PDATE can be set one of 3 ways.  This is the order of priority:
#
#   1.  Specified via command line argument
#   2.  Read from ${C_IMGNDIR}/last_plot_time file and advanced
#        one cycle.
#   3.  Using the last available cycle for which there is
#        data in ${C_TANKDIR}.
#
# If option 2 has been used the ${C_IMGNDIR}/last_plot_time file
# will be updated with ${PDATE} if the plot is able to run.
#--------------------------------------------------------------------

echo "C_IG_SCRIPTS = ${C_IG_SCRIPTS}"
echo "C_TANKDIR = ${C_TANKDIR}"

if [[ ${AREA} = 'glb' ]]; then
   last_cycle=`${MON_USH}/find_last_cycle.sh --net ${CONMON_SUFFIX} \
              --run ${RUN} --tank ${TANKDIR} --mon conmon`
else
   last_cycle=`${MON_USH}/find_last_cycle_rgnl.sh --net ${CONMON_SUFFIX} \
              --tank ${C_TANKDIR} --mon conmon`
fi

echo "last_cycle = ${last_cycle}"

if [[ ${PDATE} = "" ]]; then

   if [[ -e ${C_IMGNDIR}/last_plot_time ]]; then
      echo " USING last_plot_time"
      last_plot=`cat ${C_IMGNDIR}/last_plot_time`
      export PDATE=`$NDATE +${CYCLE_INTERVAL} ${last_plot}`
   else
      export PDATE=$last_cycle
   fi
fi

#--------------------------------------------------------------------
# Set the START_DATE for the plot
#--------------------------------------------------------------------
ncycles=`expr $NUM_CYCLES - 1`
hrs=`expr ${ncycles} \\* -${CYCLE_INTERVAL}`

export START_DATE=`$NDATE ${hrs} $PDATE`
echo "START_DATE, last_cycle, PDATE = $START_DATE $last_cycle  $PDATE"

pdy=`echo ${PDATE}|cut -c1-8`
cyc=`echo ${PDATE}|cut -c9-10`


#------------------------------------------------------------------
#   Start image plotting jobs.
#------------------------------------------------------------------
export JOBNAME=${JOBNAME:-CM_IG_${CONMON_SUFFIX}}
echo "C_TANKDIR = ${C_TANKDIR}"

if [[ ${PDATE} -le ${last_cycle} ]]; then

   echo "ABLE to plot ${PDATE}, last processed date is ${last_cycle}"

   #--------------------------------------------------------------------
   #  Create workdir and cd to it
   #--------------------------------------------------------------------
   if [[ ${AREA} = 'glb' ]]; then
      export C_PLOT_WORKDIR=${C_PLOT_WORKDIR:-${MON_STMP}/${CONMON_SUFFIX}/${RUN}/conmon}
      sdirs="horz,hist,time,vert"
   else
      export C_PLOT_WORKDIR=${C_PLOT_WORKDIR:-${MON_STMP}/${CONMON_SUFFIX}/conmon}
      sdirs="hist,time,vert"
   fi
   rm -rf $C_PLOT_WORKDIR
   mkdir -p $C_PLOT_WORKDIR
   cd $C_PLOT_WORKDIR

   #--------------------------------------------------------------------
   #  Run the two plot setup scripts
   #--------------------------------------------------------------------
   ${C_IG_SCRIPTS}/mk_horz_hist.sh

   ${C_IG_SCRIPTS}/mk_time_vert.sh

   #--------------------------------------------------------------------
   #  Update the last_plot_time file if found
   #--------------------------------------------------------------------
   if [[ -e ${C_IMGNDIR}/last_plot_time ]]; then
      echo ${PDATE} > ${C_IMGNDIR}/last_plot_time
   fi

   #--------------------------------------------------------------------
   #  Mail warning reports 
   #--------------------------------------------------------------------
#   if [[ $DO_DATA_RPT = 1 ]]; then
#     warn_file=${C_TANKDIR}/${RUN}.${pdy}/${cyc}/conmon/horz_hist/ges/err_rpt.ges.${PDATE}
#     if [[ -e ${warn_file} ]]; then
#       echo "mailing err_rpt"          
#       /bin/mail -s "ConMon warning" -c "${MAIL_CC}" ${MAIL_TO} < ${warn_file} 
#     fi
#   fi

   ${MON_USH}/rm_img_files.pl --dir ${C_IMGNDIR}/pngs --ncyc ${NUM_IMG_CYCLES} --sdirs ${sdirs}

else
   echo "UNABLE to plot ${PDATE}, last processed date is ${last_cycle}"
   exit 4
fi


echo "End ConMon_IG.sh"
exit
