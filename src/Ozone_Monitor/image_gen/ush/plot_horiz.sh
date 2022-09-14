#! /bin/bash

#------------------------------------------------------------------
#  plot_horiz.sh
#

echo "begin plot_horiz.sh"


export SATYPE=$1
export PVAR=$2
export PTYPE=$3		# plot type(s)
export dsrc=$4		# data source -- ges | anl

echo "SATYPE, PVAR, PTYPE dsrc = $SATYPE, $PVAR, $PTYPE, $dsrc"
echo "RUN = $RUN"
echo "NDATE = $NDATE"
echo "PDATE = $PDATE"

#------------------------------------------------------------------
# Set work space for this SATYPE source.
#
tmpdir=${WORKDIR}/${SATYPE}.${dsrc}.$PDATE.${PVAR}
if [[ -d $tmpdir ]]; then
   rm -rf $tmpdir
fi
mkdir -p $tmpdir
cd $tmpdir

#------------------------------------------------------------------
#   Set dates and copy data
#
#   4 cycles worth of data are required for horiz plots.
#   Start with PDATE and back up 3 times to get what we need.
#
ctr=0
cdate=$PDATE

while [[ $ctr -le 3 ]]; do
   c_pdy=`echo $cdate|cut -c1-8`
   c_cyc=`echo $cdate|cut -c9-10`

   tankdir_cdate=${OZN_TANKDIR_STATS}/${RUN}.${c_pdy}/${c_cyc}/atmos/oznmon/horiz
   if [[ ! -d ${tankdir_cdate} ]]; then
      tankdir_cdate=${OZN_TANKDIR_STATS}/${RUN}.${c_pdy}/${c_cyc}/oznmon/horiz
      if [[ ! -d ${tankdir_cdate} ]]; then
         tankdir_cdate=${OZN_TANKDIR_STATS}/${RUN}.${c_pdy}/horiz
      fi
   fi

   if [[ -e ${tankdir_cdate}/${SATYPE}.${dsrc}.ctl ]]; then 
      $NCP ${tankdir_cdate}/${SATYPE}.${dsrc}.ctl ./
   fi

   if compgen -G "${tankdir_cdate}/${SATYPE}.${dsrc}.${c_pdy}*ieee_d*" > /dev/null; then
      $NCP ${tankdir_cdate}/${SATYPE}.${dsrc}.${c_pdy}*ieee_d* ./
   fi

   cdate=`$NDATE -6 $cdate`
   ctr=`expr $ctr + 1`
done

if compgen -G "*.gz" > /dev/null; then
   $UNCOMPRESS *.gz
fi

#----------------------------------------------------------------
#  Modify tdef line in .ctl file to start at bdate.
#
if [[ -e ${SATYPE}.${dsrc}.ctl ]]; then
   edate=`$NDATE -18 $PDATE`
   ${OZN_IG_SCRIPTS}/update_ctl_tdef.sh ${SATYPE}.${dsrc}.ctl ${edate} 4

   $NCP ${OZN_IG_GSCRPTS}/cbarnew.gs ./


   $STNMAP -i ${SATYPE}.${dsrc}.ctl

   for var in ${PTYPE}; do

cat << EOF > ${SATYPE}_${var}.gs
'open ${SATYPE}.${dsrc}.ctl'
'run ${OZN_IG_GSCRPTS}/plot_horiz_${dsrc}.gs ${OZNMON_SUFFIX} ${RUN} ${SATYPE} ${var} x800 y700'
'quit'
EOF
      $GRADS -blc "run ${tmpdir}/${SATYPE}_${var}.gs"   


   done 


   #--------------------------------------------------------------------
   #   Move image files to TANK
   #

   ${NCP} *.png ${OZN_IMGS_HORIZ}/.

else
   echo "Unable to plot $SATYPE, no ctl file was found" 
fi

#--------------------------------------------------------------------
# Clean $tmpdir.  Submit done job.
#
if [[ $KEEPDATA -ne 1 ]]; then
   cd ../
   rm -rf $tmpdir
fi

echo "end plot_horiz.sh"
exit

