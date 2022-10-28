#! /bin/bash 

#------------------------------------------------------------------
#  plot_summary.sh
#

if [[ ${MY_MACHINE} = "hera" ]]; then
   module load grads
fi

SATYPE=$1
ptype=$2

#------------------------------------------------------------------
# Set work space for this SATYPE source.
#
tmpdir=${WORKDIR}/${SATYPE}.${ptype}.${PDATE}
rm -rf $tmpdir
mkdir -p $tmpdir
cd $tmpdir


#------------------------------------------------------------------
#   Set dates and copy data files
#
#   120 cycles worth of data (30 days) are required for summary 
#   plots.  Start with PDATE and back up 119 times.
#

ctr=0
cdate=$PDATE

while [[ $ctr -le 120 ]]; do
   c_pdy=`echo $cdate|cut -c1-8`

   tankdir_cdate=`${MON_USH}/get_stats_path.sh --run ${RUN} --pdate ${cdate} \
	          --net ${OZNMON_SUFFIX} --tank ${OZN_TANKDIR} --mon oznmon`
   tankdir_cdate=${tankdir_cdate}/time

   if [[ -d ${tankdir_cdate} ]]; then
  
      if [[ -e ${tankdir_cdate}/${SATYPE}.${ptype}.ctl ]]; then
         $NCP ${tankdir_cdate}/${SATYPE}.${ptype}.ctl ./
      fi

      if compgen -G "${tankdir_cdate}/${SATYPE}.${ptype}.${c_pdy}*ieee_d*" > /dev/null; then
         $NCP ${tankdir_cdate}/${SATYPE}.${ptype}.${c_pdy}*ieee_d* ./
      fi
   fi
      
   cdate=`$NDATE -6 $cdate`
   ctr=`expr $ctr + 1`
done

$UNCOMPRESS *.gz

#----------------------------------------------------------------
#  Modify tdef line in .ctl file to start at bdate.  tdef line 
#  should be 1 more than the total number of cycles so the last
#  cycle will be the cycle specified by $PDATE.
#
if [[ -e ${SATYPE}.${ptype}.ctl ]]; then
   bdate=`$NDATE -720 $PDATE`
   ${OZN_IG_SCRIPTS}/update_ctl_tdef.sh ${SATYPE}.${ptype}.ctl ${bdate} ${NUM_CYCLES} 
fi

cat << EOF > ${SATYPE}.gs
'open ${SATYPE}.${ptype}.ctl'
'run ${OZN_IG_GSCRPTS}/plot_summary.gs ${OZNMON_SUFFIX} ${RUN} ${SATYPE} ${ptype} x750 y700'
'quit'
EOF

   $GRADS -bpc "run ${tmpdir}/${SATYPE}.gs"


   #--------------------------------------------------------------------
   #  copy image files to TANKDIR
   #
   ${NCP} *.png ${OZN_IMGS_SUMMARY}/.

else
   echo "Unable to plot ${SATYPE}, no ctl file found"
fi

#--------------------------------------------------------------------
# Clean $tmpdir. 
#
if [[ ${KEEPDATA} -ne 1 ]]; then
  cd ../
  rm -rf $tmpdir
fi

exit

