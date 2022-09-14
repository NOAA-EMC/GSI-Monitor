#!/bin/bash

#-----------------------------------------------------------------------
#  OznMon_Plt.sh
#
#  Main plot script for OznMon.
#
#  Usage:
#
#    OznMon_Plt.sh OZNMON_SUFFIX [-p|pdate yyyymmddcc] [-r|run gdas|gfs]
#
#	OZNMON_SUFFIX = data source identifier which matches data 
#		  	in the OZN_TANKDIR_STATS directory.
#       -p|--pdate    = specified cycle to plot.  If not specified the
#			last available date will be plotted.
#	-r|--run      = $RUN value, gdas|gfs, default is gdas.
#       -c1|--comp1   = define first instrument/sat source to plot as comparison
#                        (applies to time series plots only)
#       -c2|--comp2   = define second instrument/sat source to plot as comparison
#                        (applies to time series plots only)
#
#	NOTE:  Both COMP1 and COMP2 have to be defined to 
#	       generate comparison plots as part of the COMP1
#	       source's time plots.
#-----------------------------------------------------------------------

function usage {
  echo " "
  echo "Usage:  OznMon_Plt.sh OZNMON_SUFFIX "
  echo "            OZNMON_SUFFIX is data source identifier which matches data in "
  echo "              the $OZN_TANKDIR_STATS directory."
  echo "            -p | --pdate yyyymmddcc to specify the cycle to be plotted."
  echo "              If unspecified the last available date will be plotted."
  echo "            -r | --run  the gdas|gfs run to be plotted, gdas is default"
  echo "            -c1| --comp1 first instrument/sat source to plotted as a comparision"
  echo "            -c2| --comp2 first instrument/sat source to plotted as a comparision"
  echo " "
}

echo start OznMon_Plt.sh


nargs=$#
echo nargs = $nargs


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
         export RUN="$2"
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

if [[ $nargs -lt 0 || $nargs -gt 9 ]]; then
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

echo "OZNMON_SUFFIX = $OZNMON_SUFFIX"
echo "pdate         = $pdate"
echo "RUN           = $RUN"


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
#   3.  Using the last available cycle for which there is
#        data in ${OZN_TANKDIR_STATS}.
#
# If option 2 has been used the last_plot_time file
# will be updated with ${PDATE} if the plot is able to run.
#--------------------------------------------------------------------

last_plot_time=${OZN_TANKBASE_IMGS}/oznmon/last_plot_time
echo "last_plot_time file = ${last_plot_time}"

latest_data=`${OZN_IG_SCRIPTS}/find_cycle.pl -run gdas -cyc 1 -dir ${OZN_TANKDIR_STATS}`

if [[ ${#pdate} -le 0 ]]; then
   if [[ -e ${last_plot_time} ]]; then
      echo " USING last_plot_time file"
      last_plot=`cat ${last_plot_time}`
      pdate=`$NDATE +6 ${last_plot}`
   else
      echo " USING find_cycle file"
      pdate=${latest_data}
   fi
fi

echo "pdate, latest_data = ${pdate} ${latest_data}"

if [[ ${pdate} -le ${latest_data} ]]; then
   echo " proceeding with plot"

   export PDATE=${pdate}
   export PDY=`echo $PDATE|cut -c1-8`
   export cyc=`echo $PDATE|cut -c9-10`

   #--------------------------------------------------------------------
   #  Create the WORKDIR and link the data files to it
   #--------------------------------------------------------------------
   export WORKDIR=${OZN_WORK_DIR}/IG.${PDY}.${cyc}
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
      export SATYPE=${SATYPE:-`cat ${OZN_TANKDIR_STATS}/info/${RUN}_oznmon_satype.txt`}
   else
      export SATYPE=${SATYPE:-`cat ${HOMEgdas_ozn}/fix/${RUN}_oznmon_satype.txt`}
   fi

   ${OZN_IG_SCRIPTS}/mk_horiz.sh
   ${OZN_IG_SCRIPTS}/mk_summary.sh
   ${OZN_IG_SCRIPTS}/mk_time.sh


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
   #${OZN_IG_SCRIPTS}/rm_img_files.pl --dir ${OZN_TANKDIR_IMGS} --nfl 30

else
  echo "unable to plot"
fi

echo "end OznMon_Plt.sh"
exit
