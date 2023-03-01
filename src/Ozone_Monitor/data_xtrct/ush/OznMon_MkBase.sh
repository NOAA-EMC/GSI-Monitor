#!/bin/bash

#-------------------------------------------------------------------
#
#  script:   OznMon_MkBase.sh
#
#  purpose:  Generate the baseline stat files for each instrument
#            by level and region.  Baseline stat includes the 
#            30 day average number of obs and sdv, and 30 day avg
#            penalty and sdv.  These files are used only if the 
#            diagnostic reports are switched on. 
#
#  calling:  OznMon_MkBase.sh suffix 1>log 2>err
#-------------------------------------------------------------------

function usage {
  echo "Usage:  OznMon_MkBase.sh [-s|--sat sat_name] suffix "
  echo "            Suffix is data source identifier that matches data in "
  echo "              the TANKverf/stats directory."
  echo "            -s|--sat (optional) restricts the list of sat/instrument "
  echo "              sources.  If no sat is specified then all "
  echo "              sat/instrument sources will be included." 
  echo "            -r|--run indicates RUN value, usually gfs|gdas"
}

nargs=$#
if [[ $nargs -lt 1 || $nargs -gt 5 ]]; then
   usage
   exit 1
fi

SINGLE_SAT=0
RUN=gdas

#-----------------------------------------------
#  Process command line arguments
#
while [[ $# -ge 1 ]]
do
   key="$1"
   echo $key

   case $key in
      -r|--run)
         RUN="$2"
         shift # past argument
      ;;
      -s|--sat)
         SATYPE="$2"
         SINGLE_SAT=1
         shift # past argument
      ;;
      *)
         #any unspecified key is OZNMON_SUFFIX
         export OZNMON_SUFFIX=$key
      ;;
   esac

   shift
done

this_file=`basename $0`
this_dir=`dirname $0`


#------------------------------------------------------------------
# Set environment variables.
#-------------------------------------------------------------------
top_parm=${this_dir}/../../parm

oznmon_user_settings=${oznmon_user_settings:-${top_parm}/OznMon_user_settings}
if [[ ! -e ${oznmon_user_settings} ]]; then
   echo "Unable to source ${oznmon_user_settings} file"
   exit 3
fi

. ${oznmon_user_settings}
if [[ $? -ne 0 ]]; then
   echo "Error detected while sourcing ${oznmon_user_settings} file"
   exit $?
fi

oznmon_config=${oznmon_config:-${top_parm}/OznMon_config}
if [[ ! -e ${oznmon_config} ]]; then
   echo "Unable to source ${oznmon_config} file"
   exit 4
fi

. ${oznmon_config}
if [[ $? -ne 0 ]]; then
   echo "Error detected while sourcing ${oznmon_config} file"
   exit $?
fi


#-------------------------------------------------------------------
#  Set dates
#    BDATE is beginning date for the 45 day range
#    EDATE is ending date for 45 day range (always use 00 cycle) 
#-------------------------------------------------------------------
EDATE=`${MON_USH}/find_last_cycle.sh --net ${OZNMON_SUFFIX} \
        --run ${RUN} --mon oznmon --tank ${TANKDIR}`

sdate=$(echo $EDATE|cut -c1-8)
EDATE="${sdate}00"
BDATE=`$NDATE -1080 $EDATE`	# 45 days

wrkdir=${OZN_WORK_DIR}/base_${OZNMON_SUFFIX}
if [[ -e ${wrkdir} ]]; then rm -rf ${wrkdir}; fi
mkdir -p ${wrkdir}
cd ${wrkdir}

#-------------------------------------------------------------------
#  If no single sat source was supplied at the command line then 
#  find $SATYPE list for this data source, checking the 
#  $TANKDIR/info directory first.
#-------------------------------------------------------------------
if [[ $SINGLE_SAT -eq 0 ]]; then

   if [[ -e ${OZN_TANKDIR_STATS}/info/gdas_oznmon_satype.txt ]]; then
      SATYPE=$(cat ${OZN_TANKDIR_STATS}/info/gdas_oznmon_satype.txt)
   elif [[ -e ${HOMEgdas_ozn}/fix/gdas_oznmon_satype.txt ]]; then
      SATYPE=$(cat ${HOMEgdas_ozn}/fix/gdas_oznmon_satype.txt)
   fi
fi


#-------------------------------------------------------------------
#  Loop over $SATYPE and build base files for each
#-------------------------------------------------------------------
for type in ${SATYPE}; do

   #-------------------------------------------------------------------
   #  Create $typdir
   #-------------------------------------------------------------------
   typdir=${wrkdir}/${type}.${EDATE}
   if [[ -e ${typdir} ]]; then rm -rf ${typdir}; fi
   mkdir -p ${typdir}
   cd ${typdir}

   #-------------------------------------------------------------------
   #  Copy the data files and ctl file to workdir
   #-------------------------------------------------------------------
   have_ctl=0
   cdate=$BDATE
    
   while [[ $cdate -le $EDATE ]]; do

      test_dir=$(${MON_USH}/get_stats_path.sh --run ${RUN} --pdate ${cdate} \
	      --net ${OZNMON_SUFFIX} --tank ${TANKDIR} --mon oznmon)
      test_dir=${test_dir}/time

      if [[ -d ${test_dir} ]]; then
         test_file=${test_dir}/${type}.ges.${cdate}.ieee_d

         if [[ -s $test_file ]]; then
            $NCP ${test_file} ./${type}.${cdate}.ieee_d
            echo $cdate >> cycle_hrs.txt
         elif [[ -s ${test_file}.${Z} ]]; then
            $NCP ${test_file}.${Z} ./${type}.${cdate}.ieee_d.${Z}
            echo $cdate >> cycle_hrs.txt
         fi
      fi


      if [[ $have_ctl -eq 0 ]]; then
         test_file=${test_dir}/${type}.ges.ctl
         if [[ -s ${test_file} ]]; then
            $NCP ${test_file} ./${type}.ctl
            have_ctl=1
         elif [[ -s ${test_file}.${Z} ]]; then
            $NCP ${test_file}.${Z} ./${type}.ctl.${Z}
            have_ctl=1
         fi
      fi

      cdate=$($NDATE +${CYCLE_INTERVAL} $cdate)
   done

   if compgen -G "*.${Z}" > /dev/null; then
      ${UNCOMPRESS} *.${Z}
   fi

   #----------------------------------------
   # skip this $type if there's no ctl file 
   #----------------------------------------
   if [[ ! -e ${type}.ctl ]]; then 
      echo "no data for ${type}, skipping"
      continue 
   fi


   #-------------------------------------------------------------------
   #  Get the number of levels for this $type
   #-------------------------------------------------------------------
   line=`cat ${type}.ctl | grep title`
   nlev=`echo $line|gawk '{print $4}'`

   #-------------------------------------------------------------------
   #  Cut out the iuse flags from the ctl file and dump them
   #  into the level.txt file for make_base executable to access
   #-------------------------------------------------------------------
   gawk '/iuse/{print $8}' ${type}.ctl >> level.txt

   #-------------------------------------------------------------------
   #  Copy the executable and run it 
   #------------------------------------------------------------------
   out_file=${type}.base
   $NCP ${GSI_MON_BIN}/oznmon_make_base.x ./

   nfiles=`ls -1 ${type}*ieee_d | wc -l` 

cat << EOF > input
 &INPUT
  satname='${type}',
  nlev=${nlev},
  nfile=${nfiles},
  out_file='${out_file}',
 /
EOF

   ./oznmon_make_base.x < input > stdout.${type}.base

   #-------------------------------------------------------------------
   #  Copy base file back to $wrkdir 
   #-------------------------------------------------------------------
   $NCP $out_file ${wrkdir}/.
   cd $wrkdir

done


#-------------------------------------------------------------------
#  Pack all basefiles into a tar file and move it to $TANKverf/info.
#  If a SINGLE_SAT was supplied at the command line then copy the
#  existing $basefile and add/replace the requested sat, leaving
#  all others in the $basefile unchanged.
#-------------------------------------------------------------------
if [[ ! -d ${OZN_TANKDIR_STATS}/info ]]; then
   mkdir -p ${OZN_TANKDIR_STATS}/info
fi

cd $wrkdir
basefile=gdas_oznmon_base.tar

if [[ $SINGLE_SAT -eq 0 ]]; then
   tar -cf ${basefile} *.base
else

   #---------------------------------------------------------
   #  copy over existing $basefile, replace the changed file
   #
   if [[ -s ${OZN_TANKDIR_STATS}/info/${basefile} ]]; then
      $NCP ${OZN_TANKDIR_STATS}/info/${basefile} ./${basefile} 
   elif [[ -s ${HOMEgdas_ozn}/fix/${basefile} ]]; then
      $NCP ${HOMEgdas_ozn}/fix/${basefile} ./${basefile} 
   fi

   new_base=$(ls *.base)
   tar --delete -f $basefile  ${new_base}
   tar -rf ${basefile} ${new_base}
fi


#--------------------------------------------------------
#  Remove the old version of the $basefile and copy new 
#  $basefile to $OZN_TANKDIR_STATS/info
#
if [[ -e ${OZN_TANKDIR_STATS}/info/${basefile} || -e ${OZN_TANKDIR_STATS}/info/${basefile}.${Z} ]]; then
   rm -f ${OZN_TANKDIR_STATS}/info/${basefile}*
fi

$NCP ${basefile} ${OZN_TANKDIR_STATS}/info/.


#-------------------------------------------------------------------
#  Clean up $tmpdir
#-------------------------------------------------------------------
cd ..
rm -rf $wrkdir

exit
