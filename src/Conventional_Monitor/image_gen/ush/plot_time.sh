#!/bin/bash

#----------------------------------------------------------
#
#  plot_time.sh
#
#----------------------------------------------------------


#----------------------------------------------------------
#  function large_mv()
#    
#  There are a lot of image files generated for the uv
#  types, so many that loading them into a single variable
#  exceeds the argument limit on wcoss_d.  This function
#  gets around that problem. 
#----------------------------------------------------------
function large_mv () {       
   while read imgf; do
      newf=`echo $imgf | sed -e "s/\./.${PDATE}./g"`
      mv $imgf ${C_IMGNDIR}/pngs/time/$newf
   done
}


   echo "--> plot_time.sh, type=${TYPE}"

   workdir=${C_PLOT_WORKDIR}/plottime_${TYPE}
   if [[ -d ${workdir} ]]; then
      rm -rf ${workdir}
   fi
   mkdir -p ${workdir}
   cd ${workdir}

   pdy=`echo $PDATE|cut -c1-8`
   cyc=`echo $PDATE|cut -c9-10`
   tv_tankdir=${C_TANKDIR}/${RUN}.${pdy}/${cyc}/conmon/time_vert


   export xsize=x800
   export ysize=y600


   #---------------------------------------------------
   #  Link in the data files.
   #    going to need ndays worth here
   #---------------------------------------------------
   cdate=$START_DATE
   edate=$PDATE

   while [[ $cdate -le $edate ]] ; do
      day=`echo $cdate | cut -c1-8 `
      dcyc=`echo $cdate |cut -c9-10`

      if [[ -d ${C_TANKDIR}/${RUN}.${day}/${dcyc}/conmon ]]; then

         for cycle in ges anl; do
            data_file=${cycle}_${TYPE}_stas.${cdate}
            data_fp=${C_TANKDIR}/${RUN}.${day}/${dcyc}/conmon/time_vert/${data_file}
            if [[ -e ${data_fp}.${Z} ]]; then
               cp -f ${data_fp}.${Z} ./${data_file}.${Z}
               $UNCOMPRESS ${data_file}.${Z}
            elif [[ -e ./${data_file_fp} ]]; then
               cp -f ${data_fp} ./${data_file}
            fi

         done

      fi

      adate=`${NDATE} +6 ${cdate}`
      cdate=${adate}
   done

   #---------------------------------------------------
   #  Copy over the ctl files, modify dset and tset
   #---------------------------------------------------
   for cycle in ges anl; do

      ctl_file=${tv_tankdir}/${cycle}_${TYPE}_stas.ctl
      if [[ -e ${ctl_file}.${Z} ]]; then
        cp -f ${ctl_file}.${Z} tmp.ctl.${Z}
        ${UNCOMPRESS} tmp.ctl.${Z}
      else
        cp -f ${ctl_file} tmp.ctl
      fi

      new_dset="dset ${cycle}_${TYPE}_stas.%y4%m2%d2%h2"

      tdef=`${C_IG_SCRIPTS}/make_tdef.sh ${START_DATE} ${NUM_CYCLES} 06`
      echo "tdef = $tdef"

      sed -e "s/^dset*/${new_dset}/" tmp.ctl >tmp2.ctl
      sed -e "s/^tdef.*/${tdef}/" tmp2.ctl >${cycle}_${TYPE}_stas.ctl
      rm -f tmp.ctl
      rm -f tmp2.ctl
   done

   #------------------------------------------
   #  ensure the imgn destination dir exists
   #------------------------------------------
   outdir=${C_IMGNDIR}/pngs/time/${cyc}
   if [[ ! -d ${outdir} ]]; then
      mkdir -p ${outdir}
   fi

  
   #---------------------------------------------------
   #  copy plots scripts locally, modify, and run
   #---------------------------------------------------

   for script in plotstas_time_count.gs plotstas_time_bias.gs ;do
      if [[ ${TYPE} = 'gps' && ${script} = 'plotstas_time_bias.gs' ]]; then
         continue
      fi

      plot_script=${C_IG_GSCRIPTS}/${script}

      if [[ -s  ${plot_script} ]]; then
         cp -f ${plot_script} .
      else
         echo "unable to find ${plot_script}, exiting"
         exit 9
      fi

      #--------------------------------
      #  modify plot script for TYPE
      #--------------------------------
      base_name=`echo "${script}" | awk -F. '{print $1}'`
      local_plot_script=${base_name}_${TYPE}.gs
      sed -e "s/DTYPE/$TYPE/" \
         ${script} > ${local_plot_script}

      #-------------------------
      #  run the plot scripts
      #-------------------------
      grads -bpc "run ./${local_plot_script}"

      img_files=`ls *.png`

      #------------------------------------------
      #  use large_mv function to avoid argument 
      #  list overload
      #------------------------------------------
      ls -1 *.png | large_mv

   done


   if [[ ${C_IG_SAVE_WORK} -eq 0 ]]; then
      cd ${workdir}
      cd ..
      rm -rf ${workdir}
   fi


   echo "<-- plot_time.sh"
exit

