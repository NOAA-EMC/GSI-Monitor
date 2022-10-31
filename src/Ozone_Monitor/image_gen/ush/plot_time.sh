#! /bin/bash

#------------------------------------------------------------------
#  plot_time.sh
#

export SATYPE=$1
export PVAR=$2
export PTYPE=$3
dsrc=$4

echo "SATYPE, PVAR, PTYPE, dsrc = $SATYPE, $PVAR, $PTYPE $dsrc"
echo "RUN = $RUN"

echo COMP1, COMP2, DO_COMP = $COMP1, $COMP2, $DO_COMP

ADD_COMP=0
if [[ $SATYPE = $COMP1 ]]; then
   ADD_COMP=1
fi

#------------------------------------------------------------------
# Set work space for this SATYPE source.
#
tmpdir=${WORKDIR}/${SATYPE}.${dsrc}.$PDATE.${PVAR}
rm -rf $tmpdir
mkdir -p $tmpdir
cd $tmpdir

#------------------------------------------------------------------
#   Set dates and copy data files
#
#   120 cycles worth of data (30 days) are required for time plots.
#   Start with PDATE and back up 119 times to get what we need.
#

ctr=0
cdate=$PDATE

while [[ $ctr -le 119 ]]; do
   c_pdy=`echo $cdate|cut -c1-8`
   c_cyc=`echo $cdate|cut -c9-10`

   tankdir_cdate=`${MON_USH}/get_stats_path.sh --run ${RUN} --pdate ${cdate} \
	          --net ${OZNMON_SUFFIX} --tank ${OZN_TANKDIR} --mon oznmon`
   tankdir_cdate=${tankdir_cdate}/time

   if [[ -d ${tankdir_cdate} ]]; then

      if [[ -e ${tankdir_cdate}/${SATYPE}.${dsrc}.ctl ]]; then
         $NCP ${tankdir_cdate}/${SATYPE}.${dsrc}.ctl ./
      fi

      if compgen -G "${tankdir_cdate}/${SATYPE}.${dsrc}.${c_pdy}*ieee_d*" > /dev/null; then
         $NCP ${tankdir_cdate}/${SATYPE}.${dsrc}.${c_pdy}*ieee_d* ./
      fi

      if [[ $ADD_COMP -eq 1 ]]; then
         if [[ ! -e ./${COMP2}.${dsrc}.ctl ]]; then
            $NCP ${tankdir_cdate}/${COMP2}.${dsrc}.ctl ./
         fi
      
         data_file=${tankdir_cdate}/${COMP2}.${dsrc}.${cdate}.ieee_d
         if [[ -s ${data_file} ]]; then
            $NCP ${data_file} ./
         else
            data_file=${data_file}.${Z}
            if [[ -s ${data_file} ]]; then
               $NCP ${data_file} ./
               $UNCOMPRESS ${data_file}
            fi
         fi

      fi
   fi

   cdate=`$NDATE -6 $cdate`
   ctr=`expr $ctr + 1`
done



#----------------------------------------------------------------
#  Modify tdef line in .ctl file to start at bdate.
#
if [[ -e ${SATYPE}.${dsrc}.ctl ]]; then
   ((cyc=${NUM_CYCLES}-1, hrs=cyc*${CYCLE_INTERVAL}))
   edate=`${NDATE} -${hrs} ${PDATE}`
   ${OZN_IG_SCRIPTS}/update_ctl_tdef.sh ${SATYPE}.${dsrc}.ctl ${edate} ${NUM_CYCLES}

   if [[ $ADD_COMP -eq 1 ]]; then
      ${OZN_IG_SCRIPTS}/update_ctl_tdef.sh ${COMP2}.${dsrc}.ctl ${edate} ${NUM_CYCLES}
   fi


   for var in ${PTYPE}; do
      echo $var

      if [[ $ADD_COMP -eq 0 ]]; then

cat << EOF > ${SATYPE}_${var}.gs
'reinit'
'clear'
'open  ${SATYPE}.${dsrc}.ctl'
'run ${OZN_IG_GSCRPTS}/plot_time_${dsrc}.gs ${OZNMON_SUFFIX} ${RUN} ${SATYPE} ${var} x750 y700'
'quit'
EOF

      else

cat << EOF > ${SATYPE}_${var}.gs
'reinit'
'clear'
'open  ${SATYPE}.${dsrc}.ctl'
'open  ${COMP2}.${dsrc}.ctl'
'run ${OZN_IG_GSCRPTS}/plot_time_${dsrc}_2x.gs ${OZNMON_SUFFIX} ${RUN} ${SATYPE} ${COMP2} ${var} x750 y700'
'quit'
EOF

      fi

      $GRADS -bpc "run ${tmpdir}/${SATYPE}_${var}.gs"

   done 


   #--------------------------------------------------------------------
   #  copy image files to TANKDIR
   #
   ${NCP} *.png ${OZN_IMGS_TIME}/.

else
   echo "Unable to plot $SATYPE, no ctl file found"
fi


#--------------------------------------------------------------------
# Clean $tmpdir.
if [[ ${KEEPDATA} -ne 1 ]]; then
   cd ../
   rm -rf $tmpdir
fi

exit

