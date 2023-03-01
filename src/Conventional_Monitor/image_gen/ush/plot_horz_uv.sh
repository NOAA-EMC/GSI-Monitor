#!/bin/bash

   #---------------------------------------------------------------------
   #
   #  plot_horz_uv.sh
   #
   #---------------------------------------------------------------------
   echo "--> plot_horz_uv.sh"

   hh_tankdir=`${MON_USH}/get_stats_path.sh --run ${RUN} --pdate ${PDATE} \
                --net ${CONMON_SUFFIX} --tank ${TANKDIR} --mon conmon`
   hh_tankdir=${hh_tankdir}/horz_hist

   workdir=${C_PLOT_WORKDIR}/plothorz_uv
   if [[ -d ${workdir} ]]; then
      rm -rf ${workdir}
   fi
   mkdir -p ${workdir}
   cd ${workdir}

   export xsize=x800
   export ysize=y600

   #----------------------------------------------------------------------
   #  Link in the analysis and guess data files
   #----------------------------------------------------------------------
   anl_file=${hh_tankdir}/anl/anal.${PDATE}
   ges_file=${hh_tankdir}/ges/guess.${PDATE}

   if [[ -e ${anl_file}.gz ]]; then
      ${UNCOMPRESS} ${anl_file}.gz
   fi
   if [[ -e ${ges_file}.gz ]]; then
      ${UNCOMPRESS} ${ges_file}.gz
   fi

   ln -s ${anl_file} anal.${PDATE}
   ln -s ${ges_file} guess.${PDATE}


   #----------------------------------------------------------------------
   #  create the idx and ctl files for ges|anl grib2 files
   #----------------------------------------------------------------------
   ${C_IG_SCRIPTS}/g2ctl.pl -0 anal.$PDATE > anal.ctl
   gribmap -0 -i anal.ctl
   ${C_IG_SCRIPTS}/g2ctl.pl guess.$PDATE > guess.ctl
   gribmap -i guess.ctl


   #----------------------------------------------------------------------
   #  Link to required grads tools
   #----------------------------------------------------------------------
   ln -s ${C_IG_GSCRIPTS}/rgbset2.gs ./rgbset2.gs
   ln -s ${C_IG_GSCRIPTS}/page.gs ./page.gs
   ln -s ${C_IG_GSCRIPTS}/defint.gs ./defint.gs
   ln -s ${C_IG_GSCRIPTS}/setvpage.gs ./setvpage.gs
   ln -s ${C_IG_GSCRIPTS}/colorbar.gs ./colorbar.gs


   for type in uv; do

      eval stype=\${${type}_TYPE} 
      eval nreal=\${nreal_${type}} 

      ## decoding the dignostic file

      for dtype in ${stype}; do

         mtype=`echo ${dtype} | cut -f1 -d_`
         subtype=`echo ${dtype} | cut -f2 -d_`

         for cycle in ges anl; do

            nt=1

            ### determine what kind data to plotted: 1: all data, 0: assimilated, -1: rejected
            ### or not assimilated

            if [ "$mtype" = 'uv220' ]; then

               ${NCP} ${C_IG_FIX}/uvmandlev.ctl ./${dtype}.ctl
               ${NCP} ${C_IG_GSCRIPTS}/plot_uvallev_horz.gs ./plot_${dtype}.gs

            elif  [ "$mtype" = 'uv223' -o "$mtype" = 'uv224' -o "$mtype" = 'uv228' ]; then

               ${NCP} ${C_IG_FIX}/uvsig.ctl ./${dtype}.ctl
               ${NCP} ${C_IG_GSCRIPTS}/plot_uvallev_horz.gs ./plot_${dtype}.gs

            elif  [ "$mtype" = 'uv221' -o "$mtype" = 'uv230' -o "$mtype" = 'uv231' -o\
		    "$mtype" = 'uv232' -o "$mtype" = 'uv233' -o "$mtype" = 'uv234' -o "$mtype" = 'uv235' ]; then

               ${NCP} ${C_IG_FIX}/uvallev.ctl  ./${dtype}.ctl
               ${NCP} ${C_IG_GSCRIPTS}/plot_uvallev_horz.gs ./plot_${dtype}.gs

            elif [ "$mtype" = 'uv242' -o "$mtype" = 'uv243' -o "$mtype" = 'uv245' -o \
		   "$mtype" = 'uv246' -o "$mtype" = 'uv247' -o "$mtype" = 'uv248' -o \
		   "$mtype" = 'uv249' -o "$mtype" = 'uv250' -o "$mtype" = 'uv251' -o \
		   "$mtype" = 'uv252' -o "$mtype" = 'uv253' -o "$mtype" = 'uv254' -o \
		   "$mtype" = 'uv255' -o "$mtype" = 'uv256' -o "$mtype" = 'uv257' -o "$mtype" = 'uv258' ]; then

               ${NCP} ${C_IG_FIX}/uvallev.ctl ./${dtype}.ctl
               ${NCP} ${C_IG_GSCRIPTS}/plot_uvsatwind_horz.gs ./plot_${dtype}.gs

            elif [ "$mtype" = 'uv280' -o "$mtype" = 'uv281' -o "$mtype" = 'uv282' -o \
		   "$mtype" = 'uv284' -o "$mtype" = 'uv287' ]; then

               ${NCP} ${C_IG_FIX}/uvsfc11.ctl ./${dtype}.ctl
               ${NCP} ${C_IG_GSCRIPTS}/plot_uvsfc_horz.gs ./plot_${dtype}.gs

            elif [ "$mtype" = 'uv229' ]; then

               ${NCP} ${C_IG_FIX}/uvsfc7.ctl ./${dtype}.ctl
               ${NCP} ${C_IG_GSCRIPTS}/plot_uvsfc_horz.gs ./plot_${dtype}.gs
            fi


            sdir=" dset ${dtype}.grads.${cycle}.${PDATE}"
            title="title  ${dtype}  ${cycle}"
            sed -e "s/^title.*/${title}/" ${dtype}.ctl >tmp.ctl
            echo $sdir >${dtype}.grads.${cycle}.ctl
            cat tmp.ctl >>${dtype}.grads.${cycle}.ctl
            rm -f tmp.ctl
            rm -f ${dtype}.ctl


            #--------------------------------------------------------------
            #  link in the ${dtype}.grads.${PDATE} data file from TANKDIR
            #--------------------------------------------------------------
            grads_file=${hh_tankdir}/${cycle}/${dtype}.grads.${cycle}.${PDATE}

            if [ -s ${grads_file}.gz ]; then
               ${UNCOMPRESS} ${grads_file}.gz
               ln -s ${grads_file} ${dtype}.grads.${cycle}.${PDATE}

            elif [ -s ${grads_file} ]; then
               ln -s ${grads_file} ${dtype}.grads.${cycle}.${PDATE}
   
            else
               continue
            fi

            stnmap -1 -i ${dtype}.grads.${cycle}.ctl

         done         ## done with cycle
  
         if [[ -e ${dtype}.grads.ges.${PDATE} && -e ${dtype}.grads.anl.${PDATE} ]]; then
	    echo "OK to plot ${dtype}" 

            #----------------------------------------
            # set plot variables in GrADS script
            #----------------------------------------
            sed -e "s/XSIZE/$xsize/" \
                -e "s/YSIZE/$ysize/" \
                -e "s/PLOTFILE/$mtype/" \
                -e "s/PLOT2/$dtype/" \
                -e "s/RDATE/$PDATE/" \
                -e "s/HINT/${hint}/" \
                -e "s/NT/$nt/" \
                -e "s/DINDEX/$dindex/" \
            plot_${dtype}.gs >plothorz_${dtype}.gs

            ${GRADS} -blc "run plothorz_${dtype}.gs"


            outdir=${C_IMGNDIR}/pngs/horz
      	    if [[ ! -d ${outdir} ]]; then
               mkdir -p ${outdir}
            fi

            img_files=`ls *.png`
            for imgf in $img_files; do
               newf=`echo ${imgf} | sed -e "s/\./.${PDATE}./g"`
   	    mv ${imgf} ${C_IMGNDIR}/pngs/horz/${newf}
            done

         else
            echo "No data for ${dtype}, skipping plot"; echo
	 fi

      done      ### dtype loop 
   done      ### type loop

   ${COMPRESS} ${hh_tankdir}/ges/*grads*
   ${COMPRESS} ${hh_tankdir}/anl/*grads*

   if [[ ${C_IG_SAVE_WORK} -eq 0 ]]; then
      cd ${workdir}
      cd ..
      rm -rf ${workdir}
   fi


   echo "<-- plot_horz_uv.sh"

exit 

