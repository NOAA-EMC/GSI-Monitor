#! /bin/bash

#------------------------------------------------------------------
#
#  plot_summary.sh
#
#------------------------------------------------------------------

SATYPE2=$SATYPE

echo; echo "Start plot_summary.sh"

#------------------------------------------------------------------
# Set environment variables.
tmpdir=${PLOT_WORK_DIR}/plot_summary_${RADMON_SUFFIX}
rm -rf $tmpdir
mkdir -p $tmpdir
cd $tmpdir


#------------------------------------------------------------------
#   Set dates
#
bdate=${START_DATE}
edate=$PDATE
bdate0=`echo $bdate|cut -c1-8`
edate0=`echo $edate|cut -c1-8`

ctldir=$IMGNDIR/time
usef="use.txt"
timesf="times.txt"
chanf="chan.txt"

#--------------------------------------------------------------------
# Assemble the required data files (*.ieee_d), make txt files, and 
# conditionally create static images (see below), and move all 
# resulting files to the $TANKverf/imgn directory for transfer to 
# server.
#
for type in ${SATYPE2}; do

   $NCP $ctldir/${type}*.ctl* ./
   ${UNCOMPRESS} *.ctl.${Z}

   cdate=$bdate

   #-------------------------------------
   #  Locate and copy data files.
   #
   while [[ $cdate -le $edate ]]; do

      #-----------------------------------------------------------
      #  Locate the data files, first checking for a tar file,
      #  and copy them locally.
      #
      ieee_src=`$MON_USH/get_stats_path.sh --run $RUN --pdate ${cdate} \
	        --net ${RADMON_SUFFIX} --tank ${R_TANKDIR} --mon radmon`

      if [[ -d ${ieee_src} ]]; then
         if [[ -e ${ieee_src}/radmon_time.tar && -e ${ieee_src}/radmon_time.tar.${Z} ]]; then
            echo "Located both radmon_time.tar and radmon_time.tar.${Z} in ${ieee_src}.  Unable to plot."
            exit 23
				      
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

      adate=`$NDATE +${CYCLE_INTERVAL} ${cdate}`
      cdate=$adate
   done

   ${UNCOMPRESS} *.ieee_d.${Z}

   #-----------------------------------------------
   #  Remove 'time.' from the *ieee_d file names.
   #
   prefix="time."
   dfiles=`ls *.ieee_d 2>/dev/null`
   if [[ $dfiles = "" ]]; then
      echo "NO DATA available for $type, aborting summary plot"
      continue
   fi

   for file in $dfiles; do
      newfile=`basename $file | sed -e "s/^$prefix//"`
      mv ./${file} ./${newfile}
   done
   
   #--------------------------------------------------------------------
   #  Plotting is moving towards dynamic, interactive images drawn
   #  on-the-fly in the client browser.  These images require small text
   #  files instead of static images produced by GrADS.  The flag
   #  PLOT_STATIC_IMGS controls the conditional plotting of the older
   #  static images.  
   #
   #  At present this only affects the summary plots, but will eventually
   #  include most radiance images.
   #
   if [[ $PLOT_STATIC_IMGS -eq 1 ]]; then

      outfile=${tmpdir}/${type}.gs
      rm -f ${outfile}

cat << EOF > ${outfile}
'open ${type}.ctl'
'run ${IG_GSCRIPTS}/plot_summary.gs ${type} ${PLOT_SUB_AVGS} ${USE_ANL} x1100 y850'
'quit'
EOF

      $GRADS -bpc "run ${outfile}"
   fi


   #--------------------------------------------------------------------
   #  Build data files for server.
   #  This supports the javascript summary plot.
   #
   #  Algorithm:
   #    1. Copy summary.x locally
   #    2. For each entry in SATYTPE
   #       a) build the times.txt file from the data files
   #       b) build the use.txt file from the ctl file
   #       c) build the input file (namelist for summary.x)
   #       d) run the summary.x executable
   #       e) copy the [satype].sum.txt file to $TANKverf/imgn/{suffix}/pngs/summary/.
   #       f) clean up

   if [[ -e $timesf ]]; then
      rm -f $timesf
   fi

   if [[ ! -s summary.x ]]; then
      $NCP ${IG_EXEC}/radmon_ig_summary.x summary.x 
   fi

   ls ${type}.*.ieee_d | cut -d'.' -f2 > tmp
   tac tmp > $timesf
   rm tmp

   if [[ -e ${usef} ]]; then
      rm -f ${usef}
   fi
   cat ./${type}.ctl | grep iuse | gawk '{print $8}' > ${usef}

   nchanl=`cat ./${type}.ctl | grep title |gawk '{print $4}'`

   #------------------------------
   #  build chan.txt using ctl file
   #
   if [[ -e ${chanf} ]]; then
      rm ${chanf}
   fi
   grep iuse ${type}.ctl | gawk '{print $5}' > $chanf

   ncycle=`cat $timesf | wc -l`
   st_time=`head -1 $times`
   cyc_per_day=$((24/$CYCLE_INTERVAL))           # number cycles per day

   input=${type}.input.txt

   nregion=5
   if [[ ${RAD_AREA} == "rgn" ]]; then
     nregion=1
   fi
 
   cat <<EOF > ${input}
     &INPUT
      satname=${type},
      nchanl=${nchanl},
      ncycle=${ncycle},
      nregion=${nregion},
      st_time=${st_time},
      cyc_per_day=${cyc_per_day},
     /
EOF

   rm -f input
   cp ${input} input
   ./summary.x < input > out.${type}

   rm -f ${input}
   rm -f ${type}*ieee_d
done


#--------------------------------------------------------------------
# Copy image files to $IMGNDIR to set up for mirror to web server.
# Delete images and data files.

if [[ ! -d ${IMGNDIR}/summary ]]; then
   mkdir -p ${IMGNDIR}/summary
fi

if [[ $PLOT_STATIC_IMGS -eq 1 ]]; then
   $NCP *summary.png ${IMGNDIR}/summary/.
fi

for type in ${SATYPE2}; do
   mv ${type}.sum.txt ${IMGNDIR}/summary/${type}.${PDATE}.sum.txt
done


#--------------------------------------------------------------------
# Clean $tmpdir. 
#
cd $tmpdir
cd ../
rm -rf $tmpdir

echo "End plot_summary.sh"; echo

exit

