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
   c_cyc=`echo $cdate|cut -c9-10`
   
   tankdir_cdate=${OZN_TANKDIR_STATS}/${RUN}.${c_pdy}/${c_cyc}/atmos/oznmon/time
   if [[ ! -d ${tankdir_cdate} ]]; then
      tankdir_cdate=${OZN_TANKDIR_STATS}/${RUN}.${c_pdy}/${c_cyc}/oznmon/time
      if [[ ! -d ${tankdir_cdate} ]]; then
         tankdir_cdate=${OZN_TANKDIR_STATS}/${RUN}.${c_pdy}/horiz
      fi
   fi
   echo "tankdir_cdate = $tankdir_cdate"

   if [[ ! -e ./${SATYPE}.${ptype}.ctl ]]; then
      if [[ -e ${tankdir_cdate}/${SATYPE}.${ptype}.ctl ]]; then
         $NCP ${tankdir_cdate}/${SATYPE}.${ptype}.ctl ./
      fi
   fi
   
   data_file=${tankdir_cdate}/${SATYPE}.${ptype}.${cdate}.ieee_d
   if [[ -s ${data_file} ]]; then
      $NCP ${data_file} ./
   elif [[ -s ${data_file}.gz ]]; then
      $NCP ${data_file}.gz ./
      $UNCOMPRESS ${data_file}.gz
   else
      echo "unable to locate data file: ${data_file}"
   fi

   cdate=`$NDATE -6 $cdate`
   ctr=`expr $ctr + 1`
done


#----------------------------------------------------------------
#  Modify tdef line in .ctl file to start at bdate.  tdef line 
#  should be 1 more than the total number of cycles so the last
#  cycle will be the cycle specified by $PDATE.
#
if [[ -e ${SATYPE}.${ptype}.ctl ]]; then
   bdate=`$NDATE -720 $PDATE`
   ${OZN_IG_SCRIPTS}/update_ctl_tdef.sh ${SATYPE}.${ptype}.ctl ${bdate} 121 

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

