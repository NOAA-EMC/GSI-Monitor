#!/bin/bash

#----------------------------------------------------------------------
#  plot_time_ps.sh
#----------------------------------------------------------------------

   echo "---> plot_time_ps.sh"

   workdir=${C_PLOT_WORKDIR}/plottime_ps
   if [[ -d ${workdir} ]]; then
      rm -rf ${workdir}
   fi
   mkdir -p ${workdir}
   cd ${workdir}

   export xsize=x800
   export ysize=y600

   #-------------------------------------------------------
   #  copy over surface pressure time-series GrADS scripts
   #-------------------------------------------------------

   ${NCP} ${C_IG_GSCRIPTS}/plotstas_time_count_ps.gs . 
   ${NCP} ${C_IG_GSCRIPTS}/plotstas_time_bias_ps.gs  . 
   ${NCP} ${C_IG_GSCRIPTS}/plotstas_time_bias2_ps.gs  . 

   #---------------------------------------------------
   #  Link in the data files.
   #    going to need ndays worth here
   #---------------------------------------------------
   cdate=$START_DATE
   edate=$PDATE

   while [[ $cdate -le $edate ]] ; do
      day=`echo $cdate | cut -c1-8 `
      dcyc=`echo $cdate | cut -c9-10 `
      test_dir=`${MON_USH}/get_stats_path.sh --run ${RUN} --pdate ${cdate} \
               --net ${CONMON_SUFFIX} --tank ${TANKDIR} --mon conmon`
      
      if [[ -d ${test_dir} ]]; then

         for cycle in ges anl; do
            stas_file=${test_dir}/time_vert/${cycle}_ps_stas.${cdate}
            if [[ -e ${stas_file}.${Z} ]]; then
               ${UNCOMPRESS} ${stas_file}.${Z}
            fi
            if [[ -s ${stas_file} ]]; then
               ln -s ${stas_file} .
            fi
         done

      fi

      adate=`${NDATE} +6 ${cdate}`
      cdate=${adate}
   done

   #---------------------------------------------------
   #  Copy over the ctl files, modify dset and tset
   #---------------------------------------------------
   test_dir=`${MON_USH}/get_stats_path.sh --run ${RUN} --pdate ${PDATE} \
               --net ${CONMON_SUFFIX} --tank ${TANKDIR} --mon conmon`

   for cycle in ges anl; do

      ctl_file=${test_dir}/time_vert/${cycle}_ps_stas.ctl

      if [[ -e ${ctl_file}.${Z} ]]; then
         cp -f ${ctl_file}.${Z} tmp.ctl.${Z}
         ${UNCOMPRESS} tmp.ctl.${Z}
      else
         cp -f ${ctl_file} tmp.ctl 
      fi

      new_dset=" dset ${cycle}_ps_stas.%y4%m2%d2%h2"
      tdef=`${C_IG_SCRIPTS}/make_tdef.sh ${START_DATE} ${NUM_CYCLES} 06`

      sed -e "s/^dset*/${new_dset}/" tmp.ctl >tmp2.ctl
      sed -e "s/^tdef.*/${tdef}/" tmp2.ctl >${cycle}_ps_stas.ctl
      rm -f tmp.ctl 
      rm -f tmp2.ctl
   done

   #------------------------------------------
   #  ensure the imgn destination dir exists
   #------------------------------------------
   outdir=${C_IMGNDIR}/pngs/time
   if [[ ! -d ${outdir} ]]; then
      mkdir -p ${outdir}
   fi

   #-------------------------
   #  run the plot scripts
   #-------------------------

   grads -bpc "run ./plotstas_time_count_ps.gs"
   grads -bpc "run ./plotstas_time_bias_ps.gs"
   grads -bpc "run ./plotstas_time_bias2_ps.gs"

   img_files=`ls *.png`
   for imgf in ${img_files}; do
      newf=`echo ${imgf} | sed -e "s/\./.${PDATE}./g"`
      mv ${imgf} ${outdir}/${newf}
   done

   if [[ ${C_IG_SAVE_WORK} -eq 0 ]]; then
      cd ${workdir}
      cd ..
      rm -rf ${workdir}
   fi

   echo "<--- plot_time_ps.sh"
exit

