#! /bin/ksh

#------------------------------------------------------------------
#
#  plot_bcor.sh
#
#------------------------------------------------------------------

set -ax
export list=$listvars

SATYPE2=$1
PVAR=$2
PTYPE=$3

echo "begin plot_bcor.sh"

#------------------------------------------------------------------
# Set environment variables.
#
word_count=`echo $PTYPE | wc -w`

if [[ $word_count -le 1 ]]; then
   tmpdir=${PLOT_WORK_DIR}/plot_bcor_${RADMON_SUFFIX}_${SATYPE2}.$PDATE.${PVAR}.${PTYPE}
else
   tmpdir=${PLOT_WORK_DIR}/plot_bcor_${RADMON_SUFFIX}_${SATYPE2}.$PDATE.${PVAR}
fi

rm -rf $tmpdir
mkdir -p $tmpdir
cd $tmpdir

plot_bcor_count=plot_bcor_count.${RAD_AREA}.gs
plot_bcor_sep=plot_bcor_sep.${RAD_AREA}.gs


#------------------------------------------------------------------
#   Set dates

bdate=${START_DATE}
edate=$PDATE
bdate0=`echo $bdate|cut -c1-8`
edate0=`echo $edate|cut -c1-8`

ctldir=$IMGNDIR/bcor

#--------------------------------------------------------------------
# Loop over satellite types.  Copy data files, create plots and
# place on the web server.
#
for type in ${SATYPE2}; do

   $NCP $ctldir/${type}*.ctl* ./
   ${UNCOMPRESS} *.ctl.${Z}

   cdate=$bdate

   #-------------------------------------
   #  Locate and copy data files.
   #
   while [[ $cdate -le $edate ]]; do

      #----------------------------------------------------
      #  Attempt to locate the parent directory for the
      #  extracted ieee data files.
      #
      if [[ ${RAD_AREA} == 'rgn' ]]; then
         pdy=`echo ${cdate}|cut -c1-8`
	 ieee_src=${TANKverf}/radmon.${pdy} 
      else
         ieee_src=`$MON_USH/get_stats_path.sh --run $RUN --pdate ${cdate} \
   	           --net ${RADMON_SUFFIX} --tank ${R_TANKDIR} --mon radmon`
      fi

      #-----------------------------------------------------------
      #  Now locate this cycle's data files, first checking for 
      #  a tar file, and copy them locally.
      #
      if [[ -e ${ieee_src}/radmon_bcor.tar && -e ${ieee_src}/radmon_bcor.tar.${Z} ]]; then
         echo "Located both radmon_bcor.tar and radmon_bcor.tar.${Z} in ${ieee_src}.  Unable to plot."
         exit 22

      elif [[ -e ${ieee_src}/radmon_bcor.tar || -e ${ieee_src}/radmon_bcor.tar.${Z} ]]; then
         files=`tar -tf ${ieee_src}/radmon_bcor.tar* | grep ${type} | grep ieee_d`
         tar -xf ${ieee_src}/radmon_bcor.tar* ${files}

      else				
         files=`ls ${ieee_src}/bcor.*${type}*ieee_d*`
         for f in ${files}; do
            $NCP ${f} .
         done
      fi

      adate=`$NDATE +${CYCLE_INTERVAL} ${cdate}`
      cdate=$adate
   done

   ${UNCOMPRESS} *.ieee_d.${Z}

   #-----------------------------------------------
   #  Remove 'bcor.' from the *ieee_d file names.
   #
   prefix="bcor."
   dfiles=`ls *.ieee_d`
   if [[ $dfiles = "" ]]; then
      echo "NO DATA available for $type, aborting bcoef plot"
      continue
   fi

   for file in $dfiles; do
      newfile=`basename $file | sed -e "s/^$prefix//"`
      mv ./${file} ./${newfile}
   done

   for var in ${PTYPE}; do
      echo $var
      if [ "$var" =  'count' ]; then
cat << EOF > ${type}_${var}.gs
'open ${type}.ctl'
'run ${IG_GSCRIPTS}/${plot_bcor_count} ${type} ${var} ${PLOT_ALL_REGIONS} x1100 y850'
'quit'
EOF
      else
cat << EOF > ${type}_${var}.gs
'open ${type}.ctl'
'run ${IG_GSCRIPTS}/${plot_bcor_sep} ${type} ${var} ${PLOT_ALL_REGIONS} x1100 y850'
'quit'
EOF
      fi

      echo ${tmpdir}/${type}_${var}.gs
      $GRADS -bpc "run ${tmpdir}/${type}_${var}.gs"
   done 

done

#--------------------------------------------------------------------
# Copy image files to $IMGNDIR to set up for mirror to web server.
#
mv *.png  ${IMGNDIR}/bcor/.


#--------------------------------------------------------------------
# Clean $tmpdir  
#
cd $tmpdir
cd ../
rm -rf $tmpdir

echo "end plot_bcor.sh"
exit
