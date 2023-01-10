#!/bin/bash

#-------------------------------------------------------------------
#
#  script:  MkBase.sh
#
#  purpose:  Generate the baseline stat files for each satelite 
#            by channel and region.  Baseline stat includes the 
#            30 day average number of obs and sdv, and 30 day avg
#            penalty and sdv.  These files are used only if the 
#            diagnostic reports are switched on. 
#
#  calling:  MkBase.sh suffix 1>log 2>err
#-------------------------------------------------------------------

function usage {
  echo "Usage:  MkBase.sh suffix [--sat SAT/INSTRUMENT --run gdas|gfs] " 
  echo "            Suffix is data source identifier that matches data in "
  echo "              the $TANKverf/stats directory."
  echo ""
  echo "            -s,--sat SAT/INSTRUMENT (optional) limits the action of"
  echo "              MkBase.sh to processing only this specified source."
  echo "              Not using --sat means all satellite sources will be"
  echo "              included in the new base file." 
  echo ""
  echo "            -r,--run gdas|gfs (optional) specifies the run.  Use this"
  echo "              if TANK_USE_RUN=1 in the parm/RadMon_user_settings file"
}

nargs=$#
if [[ $nargs -lt 1 || $nargs -gt 5 ]]; then
   usage
   exit 1
fi

SATYPE=""
while [[ $# -ge 1 ]]
do
   key="$1"
   echo $key

   case $key in
      -s|--sat)
         SATYPE="$2"
         shift # past argument
      ;;
      -r|--run)
         RUN="$2"
         shift # past argument
      ;;
      *)
         #any unspecified key is RADMON_SUFFIX
         RADMON_SUFFIX=$key
      ;;
   esac

   shift
done

echo "RADMON_SUFFIX = $RADMON_SUFFIX"
echo "RUN           = $RUN"
echo "SATYPE        = $SATYPE"

single_sat=0
if [[ ${#SATYPE} -gt 0 ]]; then
   single_sat=1
fi


this_dir=`dirname $0`
top_parm=${this_dir}/../../parm

radmon_config=${radmon_config:-${top_parm}/RadMon_config}
if [[ ! -e ${radmon_config} ]]; then
   echo "Unable to source ${radmon_config} file"
   exit 2
fi

. ${radmon_config}
if [[ $? -ne 0 ]]; then
   echo "Error detected while sourcing ${radmon_config} file"
   exit $?
fi


radmon_user_settings=${radmon_user_settings:-${top_parm}/RadMon_user_settings}
if [[ ! -e ${radmon_user_settings} ]]; then
   echo "Unable to source ${radmon_user_settings} file"
   exit 3
fi

. ${radmon_user_settings}
if [[ $? -ne 0 ]]; then
   echo "Unable to source ${radmon_user_settings} file"
   exit $?
fi

#-------------------------------------------------------------------
#  Set dates
#    bdate is beginning date for the 30/60 day range
#    edate is ending date for 30/60 day range (always use 00 cycle) 
#-------------------------------------------------------------------
edate=`${MON_USH}/find_last_cycle.sh --net ${RADMON_SUFFIX} \
         --run ${RUN} --mon radmon --tank ${TANKDIR}`

sdate=`echo $edate|cut -c1-8`
edate=${sdate}00
bdate=`$NDATE -1080 $edate`

tmpdir=${MON_STMP}/base_${RADMON_SUFFIX}
rm -rf $tmpdir
mkdir -p $tmpdir
cd $tmpdir


#-------------------------------------------------------------------
#  If no single sat source was supplied at the command line then 
#  build $SATYPE list for this data source.
#-------------------------------------------------------------------
SATYPE_LIST=""
if [[ $single_sat -eq 0 ]]; then

   testdir=`$MON_USH/get_stats_path.sh --run $RUN --pdate ${edate} \
            --net ${RADMON_SUFFIX} --tank ${TANKDIR} --mon radmon`

   if [[ -d ${testdir} ]]; then
      test_list=""

      if compgen -G "${testdir}/angle*.ieee_d*" > /dev/null || compgen -G "angle*.ctl*" > /dev/null; then
         test_list=`ls ${testdir}/angle.*${edate}.ieee_d*`
      else
         test_list=`tar -tf ${testdir}/radmon_angle.tar* | grep ieee`
      fi

      for test in ${test_list}; do
         this_file=`basename $test`
         tmp=`echo "$this_file" | cut -d. -f2`

         #----------------------------------------------------------   
         #  remove sat/instrument_anl names so we don't end up
         #  with both "airs_aqua" and "airs_aqua_anl" if analysis
         #  files are being generated for this source.
         #----------------------------------------------------------   
	 if [[ ! $tmp =~ .*_anl.* ]]; then
            SATYPE_LIST="$SATYPE_LIST $tmp"
         fi

      done
   fi
   SATYPE=$SATYPE_LIST
fi

#-------------------------------------------------------------------
#  Loop over $SATYPE and build base files for each
#-------------------------------------------------------------------
for type in ${SATYPE}; do

   #-------------------------------------------------------------------
   #  Create $tmpdir
   #-------------------------------------------------------------------
   workdir=${tmpdir}/${type}.$edate
   mkdir -p $workdir
   cd $workdir

   #-------------------------------------------------------------------
   #  Create the cycle_hrs.txt file
   #-------------------------------------------------------------------
   cdate=$bdate
   nfiles=0
   while [[ $cdate -le $edate ]]; do
      echo $cdate >> cycle_hrs.txt
      adate=`$NDATE +${CYCLE_INTERVAL} $cdate`
      cdate=$adate
      nfiles=`expr $nfiles + 1`
   done

   #-------------------------------------------------------------------
   #  Copy the data files and ctl file to workdir
   #-------------------------------------------------------------------
   have_ctl=0
   cdate=$bdate

   while [[ $cdate -le $edate ]]; do
      testdir=`$MON_USH/get_stats_path.sh --run $RUN --pdate ${cdate} \
            --net ${RADMON_SUFFIX} --tank ${TANKDIR} --mon radmon`

      if [[ -d ${testdir} ]]; then

         if [[ -e ${testdir}/radmon_time.tar || -e ${testdir}/radmon_time.tar.gz ]]; then
            files=`tar -tf ${testdir}/radmon_time.tar* | grep ${type} | grep "ieee_d" | grep -v "_anl"`

            for df in ${files}; do

               if [[ -e ${testdir}/radmon_time.tar.gz ]]; then
	          tar -xf ${testdir}/radmon_time.tar.gz $df

	          if [[ ${have_ctl} -eq 0 ]]; then
                     cfiles=`tar -tf ${testdir}/radmon_time.tar* | grep ${type} | grep "ctl" | grep -v "_anl"`
	             for cf in ${cfiles}; do
                        tar -xf ${testdir}/radmon_time.tar.gz ${cf}
                     done
		     have_ctl=1
                  fi
	       fi
            done 

         else    
            if [[ -e ${testdir}/time.${type}.${cdate}.ieee_d || -e ${testdir}/time.${type}.${cdate}.ieee_d.gz ]]; then
               ${NCP} ${testdir}/time.${type}*.${cdate}.ieee_d* ./
	       if [[ ${have_ctl} -eq 0 ]]; then
                  ${NCP} ${testdir}/time.${type}.ctl* ./
		  have_ctl=1
	       fi   
            fi
	 fi 

      fi

      adate=`$NDATE +${CYCLE_INTERVAL} $cdate`
      cdate=$adate
   done

   #-------------------------------------------------------------------
   #  Expand data files and strip the starting "time." from file name
   #-------------------------------------------------------------------
   ${UNCOMPRESS} *.${Z}

   dfiles=`ls *ieee_d*`
   for df in ${dfiles}; do
      nf=${df#"time."}      
      mv ${df} ${nf}
   done

   #-------------------------------------------------------------------
   #  Get the number of channels for this $type
   #-------------------------------------------------------------------
   line=`cat time.${type}.ctl | grep title`
   nchan=`echo $line|gawk '{print $4}'`

   #-------------------------------------------------------------------
   #  Cut out the iuse flags from the ctl file and dump them
   #  into the channel.txt file for make_base executable to access
   #-------------------------------------------------------------------
   gawk '/iuse/{print $8}' time.${type}.ctl >> channel.txt

   #-------------------------------------------------------------------
   #  Copy the executable and run it 
   #------------------------------------------------------------------
   out_file=${type}.base
   $NCP ${DE_EXEC}/radmon_make_base.x ./make_base

cat << EOF > input
 &INPUT
  satname='${type}',
  n_chan=${nchan},
  nregion=1,
  nfile=${nfiles},
  date='${edate}',
  out_file='${out_file}',
 /
EOF

   ./make_base < input > stdout.${type}.base

   #-------------------------------------------------------------------
   #  Copy base file back to $tmpdir 
   #-------------------------------------------------------------------
   $NCP $out_file ${tmpdir}/.

   cd $tmpdir

done


#-------------------------------------------------------------------
#  Pack all basefiles into a tar file and move it to $TANKverf/info.
#  If a sat value was supplied at the command line then copy the
#  existing $basefile and add/replace the requested sat, leaving
#  all others in the $basefile unchanged.
#-------------------------------------------------------------------
if [[ ! -d ${TANKverf}/info ]]; then
   mkdir -p ${TANKverf}/info
fi

basefile=gdas_radmon_base.tar

newbase=$tmpdir/newbase
mkdir $newbase
cd $newbase

if [[ $single_sat -eq 0 ]]; then
   ${NCP} ${tmpdir}/*.base .
else
   
   #---------------------------------------------
   #  copy over existing $basefile and expand it
   #---------------------------------------------
   if [[ -e ${TANKverf}/info/${basefile} || -e ${TANKverf}/info/${basefile}.${Z} ]]; then
      $NCP ${TANKverf}/info/${basefile}* .
   else
      ${NCP} ${FIXgdas}/${basefile} .
   fi

   if [[ -e ${basefile}.gz ]]; then
      $UNCOMPRESS ${basefile}.gz
   fi
   tar -xf ${basefile}

   #-----------------------
   # copy new ${type}.base
   #-----------------------
   ${NCP} ${tmpdir}/${type}.base .
fi

#----------------------
#  Create new basefile
#----------------------
tar -cf ${basefile} *.base

#--------------------
#  Replace $basefile
#--------------------
if [[ -e ${TANKverf}/info/${basefile} ]]; then
   rm -f ${TANKverf}/info/${basefile}
elif [[ -e ${TANKverf}/info/${basefile}.gz ]]; then
   rm -f ${TANKverf}/info/${basefile}.gz
fi

$NCP ${basefile} ${TANKverf}/info/.

#-------------------------------------------------------------------
#  Clean up $tmpdir
#-------------------------------------------------------------------
cd $tmpdir/..
rm -rf $tmpdir

exit
