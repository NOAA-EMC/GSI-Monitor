#!/bin/bash

#-----------------------------------------------------------------------
#  OznMon_Plt.sh
#
#  Main plot script for OznMon.
#
#-----------------------------------------------------------------------

function usage {
  echo " "
  echo "Usage:  OznMon_Plt.sh OZNMON_SUFFIX [-p|--pdate -r|--run -n|--ncyc -c1|--comp1 -c2|--comp2] "
  echo "            OZNMON_SUFFIX is data source identifier which matches data in "
  echo "              the $OZN_TANKDIR directory."
  echo "            -p | --pdate yyyymmddcc to specify the cycle to be plotted."
  echo "              If unspecified the last available date will be plotted."
  echo "            -r | --run  the gdas|gfs run to be plotted, gdas is default"
  echo "            -n | --ncyc is the number of cycles to be used in time series plots.  If"
  echo "              not specified the default value in parm/RadMon_user_settins will be used"
  echo "            -t | --tank parent directory to the oznmon data file location.  This" 
  echo "              will be extended by $OZNMON_SUFFIX, $RUN, and $PDATE to locate the"
  echo "              extracted oznmon data."
  echo "            -c1| --comp1 first instrument/sat source to plotted as a comparision"
  echo "            -c2| --comp2 first instrument/sat source to plotted as a comparision"
  echo " "
}

echo start OznMon_Plt.sh

nargs=$#
echo nargs = $nargs

num_cycles=""
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
         export RUN="$2"
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
      -c1|--comp1)
	 export COMP1="$2"
         shift # past argument
      ;;
      -c2|--comp2)
	 export COMP2="$2"
         shift # past argument
      ;;
      *)
         #any unspecified key is OZNMON_SUFFIX
         export OZNMON_SUFFIX=$key
      ;;
   esac

   shift
done

if [[ $nargs -lt 0 || $nargs -gt 13 ]]; then
   usage
   exit 1
fi

if [[ $OZNMON_SUFFIX = "" ]]; then
   echo ""
   echo "ERROR:  OZNMON_SUFFIX not specified in input"
   echo ""
   usage
   exit 2
fi


if [[ ${#RUN} -le 0 ]]; then
   echo "setting RUN to gdas"
   export RUN=gdas 
fi

if [[ ${#num_cycles} -gt 0 ]]; then
   export NUM_CYCLES=${num_cycles}
fi

echo "OZNMON_SUFFIX = $OZNMON_SUFFIX"
echo "pdate         = $pdate"
echo "RUN           = $RUN"
echo "tank          = $tank"

export DO_COMP=0
if [[ ${#COMP1} > 0 && ${#COMP2} > 0 ]]; then
   export DO_COMP=1
fi


this_file=`basename $0`
this_dir=`dirname $0`

#--------------------------------------------------
# source verison, config, and user_settings files
#--------------------------------------------------
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

#--------------------------------------------------------------------
#  Set up OZN_TANKDIR
#--------------------------------------------------------------------
if [[ ${tank} = "" ]]; then	 
   ozn_tankdir=${TANKDIR}
else
   if [[ -d ${tank} ]]; then
      ozn_tankdir=${tank}   
   else
      echo "Error:  tank argument is not a directory:  ${tank}"
      echo "must exit"
      exit
   fi
fi
export OZN_TANKDIR=${ozn_tankdir}

#--------------------------------------------------------------------
#  Set up OZN_TANKDIR_IMGS
#--------------------------------------------------------------------
if [[ ! -d ${OZN_TANKDIR_IMGS} ]]; then
   mkdir -p ${OZN_TANKDIR_IMGS}
fi

#---------------------------------------------------------------
# Create any missing directories.
#---------------------------------------------------------------
if [[ ! -d $OZN_LOGDIR ]]; then
   mkdir -p $OZN_LOGDIR
fi


#--------------------------------------------------------------------
# Determine cycle to plot.  Exit if cycle is > last available
# data.
#
# PDATE can be set one of 3 ways.  This is the order of priority:
#
#   1.  Specified via command line argument
#   2.  Read from ${OZN_TANKBASE_IMGS}/last_plot_time file and
#        advanced one cycle.
#   3.  The last cycle time for which there is data.
#
# If option 2 has been used the last_plot_time file
# will be updated with ${PDATE} if the plot is able to run.
#--------------------------------------------------------------------

last_cycle=`${MON_USH}/find_last_cycle.sh --net ${OZNMON_SUFFIX} --run ${RUN} --tank ${OZN_TANKDIR} --mon oznmon`
last_plot_time=${OZN_TANKBASE_IMGS}/oznmon/last_plot_time

if [[ ${#pdate} -le 0 ]]; then
   if [[ -e ${last_plot_time} ]]; then
      echo " USING last_plot_time file"
      last_plot=`cat ${last_plot_time}`
      pdate=`$NDATE +6 ${last_plot}`
   else
      echo " USING last_cycle"
      pdate=${last_cycle}
   fi
fi

#------------------------------------
#  Confirm there is data for $pdate
#
dp=""
dp=`$MON_USH/get_stats_path.sh --run $RUN --pdate ${pdate} --net ${OZNMON_SUFFIX} --tank ${OZN_TANKDIR} --mon oznmon`

if [[ $pdate -le $last_cycle && -d ${dp} ]]; then

   export PDATE=${pdate}
   export PDY=`echo $PDATE|cut -c1-8`
   export CYC=`echo $PDATE|cut -c9-10`

   #--------------------------------------------------------------------
   #  Create the WORKDIR and link the data files to it
   #--------------------------------------------------------------------
   export WORKDIR=${OZN_WORK_DIR}/IG.${PDY}.${CYC}
   if [[ -d ${WORKDIR} ]]; then
     rm -rf ${WORKDIR}
   fi
   mkdir -p ${WORKDIR}
   cd ${WORKDIR}

   #--------------------------------------------------------------------
   #  Plot scripts are plot_time.sh and plot_horiz.sh.  The plot_time.sh
   #  script calls plot_summary.sh.  The plot_time & plot_horiz are
   #  submitted jobs.
   #
   #  All plot_* scripts call transfer.sh.  We'll handle that like the
   #  other monitors.
   #--------------------------------------------------------------------

   if [[ -e ${OZN_TANKDIR_STATS}/info/gdas_oznmon_satype.txt ]]; then
      export SATYPE=${SATYPE:-`cat ${OZN_TANKDIR_STATS}/info/gdas_oznmon_satype.txt`}
   else
      export SATYPE=${SATYPE:-`cat ${HOMEgdas_ozn}/fix/${RUN}_oznmon_satype.txt`}
   fi

   ${OZN_IG_SCRIPTS}/mk_horiz.sh
   ${OZN_IG_SCRIPTS}/mk_time.sh
   ${OZN_IG_SCRIPTS}/mk_summary.sh


   if [[ $DO_DATA_RPT -eq 1 ]]; then
      ${OZN_IG_SCRIPTS}/mk_err_rpt.sh
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
   #
   #  This is not currently necessary -- the OznMon doesn't make any 
   #  time-stampped plots.  But it's here (borrowed from the RadMon) 
   #  to meet that contingency. 
   #--------------------------------------------------------------------
   ${OZN_IG_SCRIPTS}/rm_img_files.pl --dir ${OZN_TANKDIR_IMGS} --nfl 30

else
  echo "unable to plot"
fi

echo "end OznMon_Plt.sh"
exit
