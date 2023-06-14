#! /bin/bash

#------------------------------------------------------------------
#
#  plot_time.sh
#
#------------------------------------------------------------------

SATYPE2=$1
PVAR=$2
PTYPE=$3

echo; echo "Starting plot_time.sh"; echo

#-----------------------------------------------
# Make sure IMGNDIR/time directory exists and
# set necessary environment variables.
#
if [[ ! -d ${IMGNDIR}/time ]]; then
   mkdir -p ${IMGNDIR}/time
fi
tmpdir=${PLOT_WORK_DIR}/plot_time_${RADMON_SUFFIX}_${SATYPE2}.$PDATE.${PVAR}
rm -rf $tmpdir
mkdir -p $tmpdir
cd $tmpdir

plot_time_count=plot_time_count.${RAD_AREA}.gs
echo plot_time_count = ${plot_time_count}

plot_time_sep=plot_time_sep.${RAD_AREA}.gs
echo plot_time_sep = ${plot_time_sep}

echo tmpdir        = ${tmpdir}

#------------------------------------------------------------------
#   Set dates
#
bdate=${START_DATE}
edate=$PDATE
bdate0=`echo $bdate|cut -c1-8`
edate0=`echo $edate|cut -c1-8`

ctldir=$IMGNDIR/time


#--------------------------------------------------------------------
# Loop over satellite types.  Copy data files, create plots and
# place on the web server.
#
# Data file location may either be in angle, bcoef, bcor, and time
# subdirectories under $TANKverf, or in the Operational organization
# of radmon.YYYYMMDD directories under $TANKverf
#
for type in ${SATYPE2}; do
   
   $NCP $ctldir/${type}*.ctl* ./
   ${UNCOMPRESS} *.ctl.${Z}

   cdate=$bdate
   while [[ $cdate -le $edate ]]; do

      if [[ ${RAD_AREA} == 'rgn' ]]; then
         pdy=`echo ${cdate}|cut -c1-8`
         ieee_src=${TANKverf}/radmon.${pdy} 
      else
         ieee_src=`$MON_USH/get_stats_path.sh --run $RUN --pdate ${cdate} \
	           --net ${RADMON_SUFFIX} --tank ${R_TANKDIR} --mon radmon`
      fi

      #-----------------------------------------------------------
      #  Locate the data files, first checking for a tar file,
      #  and copy them locally.
      #
      if [[ -d ${ieee_src} ]]; then
         if [[ -e ${ieee_src}/radmon_time.tar && -e ${ieee_src}/radmon_time.tar.${Z} ]]; then
            echo "Located both radmon_time.tar and radmon_time.tar.${Z} in ${ieee_src}.  Unable to plot."
            exit 24

         elif [[ -e ${ieee_src}/radmon_time.tar || -e ${ieee_src}/radmon_time.tar.${Z} ]]; then
            files=`tar -tf ${ieee_src}/radmon_time.tar* | grep ${type} | grep ieee_d`
            if [[ ${files} != "" ]]; then
               tar -xf ${ieee_src}/radmon_time.tar* ${files}
            fi

         else
            files=`ls ${ieee_src}/time.*${type}*ieee_d*`
            for f in ${files}; do
               $NCP ${f} .
            done
         fi
      fi

      adate=`$NDATE +${CYCLE_INTERVAL} $cdate`
      cdate=$adate
   done

   ${UNCOMPRESS} ./*.ieee_d.${Z}

   #-----------------------------------------------
   #  Remove 'time.' from the *ieee_d file names.
   #
   prefix="time."
   dfiles=`ls *.ieee_d 2>/dev/null`
   if [[ $dfiles = "" ]]; then
      echo "NO DATA available for $type, aborting time plot"
      continue
   fi

   for file in $dfiles; do
      newfile=`basename $file | sed -e "s/^$prefix//"`
      mv ./${file} ./${newfile}
   done


   if [[ $PLOT_STATIC_IMGS -eq 1 ]]; then
      for var in ${PTYPE}; do
         echo $var
         if [ "$var" =  'count' ]; then 
cat << EOF > ${type}_${var}.gs
'open ${type}.ctl'
'run ${IG_GSCRIPTS}/${plot_time_count} ${type} ${var} ${PLOT_ALL_REGIONS} x1100 y850'
'quit'
EOF
         elif [ "$var" =  'penalty' ]; then
cat << EOF > ${type}_${var}.gs
'open ${type}.ctl'
'run ${IG_GSCRIPTS}/${plot_time_count} ${type} ${var} ${PLOT_ALL_REGIONS} x1100 y850'
'quit'
EOF
         else
cat << EOF > ${type}_${var}.gs
'open ${type}.ctl'
'run ${IG_GSCRIPTS}/${plot_time_sep} ${type} ${var} ${PLOT_ALL_REGIONS} x1100 y850'
'quit'
EOF
         fi

         echo "running GrADS on ${tmpdir}/${type}_${var}.gs"
         $GRADS -bpc "run ${tmpdir}/${type}_${var}.gs"

      done 
   fi

   #----------------------------------------------------------
   #  mk_digital_time.sh  creates the data files used by the 
   #    html/js web files for interactive chart generation.
   #
   $NCP ${IG_SCRIPTS}/mk_digital_time.sh  .
   echo; ./mk_digital_time.sh  ${type}; echo
   rm -f mk_digital_time.sh 

done

#--------------------------------------------------------------------
# Copy image files to $IMGNDIR.
#
if [[ $PLOT_STATIC_IMGS -eq 1 ]]; then
   cp -f *.png  ${IMGNDIR}/time
fi


#--------------------------------------------------------------------
# Clean $tmpdir.
cd $tmpdir
cd ../
rm -rf $tmpdir

echo "Exiting plot_time.sh"
exit

