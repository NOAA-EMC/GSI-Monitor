#!/bin/bash

#----------------------------------------------------------------------------------------
#  plot_horz.sh
#
#    This produces the horizontal temperature images.
#----------------------------------------------------------------------------------------
   echo "--> plot_horz.sh"

   hh_tankdir=`${MON_USH}/get_stats_path.sh --run ${RUN} --pdate ${PDATE} \
	        --net ${CONMON_SUFFIX} --tank ${TANKDIR} --mon conmon`
   hh_tankdir=${hh_tankdir}/horz_hist

   export xsize=x800
   export ysize=y600

   workdir=${C_PLOT_WORKDIR}/plothorz
   if [[ -d ${workdir} ]]; then
      rm -rf ${workdir}
   fi
   mkdir -p ${workdir}
   cd ${workdir}


   #----------------------------------------------------------------------
   #  link in the analysis and guess data files
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
   ln -s ${C_IG_GSCRIPTS}/cbarnew.gs ./cbarnew.gs


   for type in ps q t; do

      eval stype=\${${type}_TYPE} 
      eval nreal=\${nreal_${type}} 

      for dtype in ${stype}; do
         mtype=`echo ${dtype} | cut -f1 -d_`
         subtype=`echo ${dtype} | cut -f2 -d_`

         for cycle in ges anl; do
            nt=1

            #---------------------------------------
            #  build the control file for the data
            #---------------------------------------
            if [ "$mtype" = 'ps180' -o "$mtype" = 'ps181' -o  \
	         "$mtype" = 'ps183' -o "$mtype" = 'ps187'  ]; then

               cp ${C_IG_FIX}/pstime.ctl ./${dtype}.ctl
               cp ${C_IG_GSCRIPTS}/plot_ps_horz.gs ./plot_${dtype}.gs

            elif [ "$mtype" = 'ps120' ]; then

               cp ${C_IG_FIX}/pssfc.ctl ./${dtype}.ctl
               cp ${C_IG_GSCRIPTS}/plot_ps_horz.gs ./plot_${dtype}.gs

            elif [ "$mtype" = 't120' ]; then

               cp ${C_IG_FIX}/tmandlev.ctl ./${dtype}.ctl
               cp ${C_IG_GSCRIPTS}/plot_tallev_horz.gs ./plot_${dtype}.gs

            elif [ "$mtype" = 't180' -o "$mtype" = 't181' -o "$mtype" = 't182' -o \
		   "$mtype" = 't183' -o "$mtype" = 't187'  ]; then

               cp ${C_IG_FIX}/tsfc.ctl ./${dtype}.ctl
               cp ${C_IG_GSCRIPTS}/plot_tsfc_horz.gs ./plot_${dtype}.gs
   
            elif [ "$mtype" = 't130' -o "$mtype" = 't131' -o "$mtype" = 't132' -o \
		   "$mtype" = 't133' -o "$mtype" = 't134' -o "$mtype" = 't135' ]; then

               cp ${C_IG_FIX}/tallev.ctl ./${dtype}.ctl
               cp ${C_IG_GSCRIPTS}/plot_tallev_horz.gs ./plot_${dtype}.gs
   
            elif [ "$mtype" = 'q120' ]; then
   
               cp ${C_IG_FIX}/qmandlev.ctl ./${dtype}.ctl
               cp ${C_IG_GSCRIPTS}/plot_qallev_horz.gs ./plot_${dtype}.gs

            elif [ "$mtype" = 'q180' -o "$mtype" = 'q181' -o  "$mtype" = 'q182' -o \
		   "$mtype" = 'q183' -o "$mtype" = 'q187' ]; then
               cp ${C_IG_FIX}/qsfc.ctl ./${dtype}.ctl
               cp ${C_IG_GSCRIPTS}/plot_qsfc_horz.gs ./plot_${dtype}.gs

            elif [ "$mtype" = 'q130' -o "$mtype" = 'q131' -o "$mtype" = 'q132' -o \
		   "$mtype" = 'q133' -o "$mtype" = 'q134' -o "$mtype" = 'q135' ]; then
               cp ${C_IG_FIX}/qallev.ctl ./${dtype}.ctl
               cp ${C_IG_GSCRIPTS}/plot_qallev_horz.gs ./plot_${dtype}.gs

            elif [ "$mtype" = 'uv220' ]; then
   
               cp $CTLDIR/uvmandlev.ctl ./${dtype}.ctl
               cp $GSCRIPTS/plot_uvallev_horz.gs ./plot_${dtype}.gs

            elif  [ "$mtype" = 'uv223' -o "$mtype" = 'uv224' -o "$mtype" = 'uv228' ]; then

               cp $CTLDIR/uvsig.ctl ./${dtype}.ctl
               cp $GSCRIPTS/plot_uvallev_horz.gs ./plot_${dtype}.gs
   
            elif  [ "$mtype" = 'uv221' -o "$mtype" = 'uv230' -o "$mtype" = 'uv231' -o \
		    "$mtype" = 'uv232' -o "$mtype" = 'uv233' -o "$mtype" = 'uv234' -o "$mtype" = 'uv235' ]; then

               cp $CTLDIR/uvallev.ctl  ./${dtype}.ctl
               cp $GSCRIPTS/plot_uvallev_horz.gs ./plot_${dtype}.gs

            fi


            sdir=" dset ${dtype}.grads.${cycle}.${PDATE}"
            title="title  ${dtype}  ${cycle}"
            sed -e "s/^title.*/${title}/" ${dtype}.ctl >tmp.ctl
            echo $sdir >${dtype}.grads.${cycle}.ctl
            cat tmp.ctl >>${dtype}.grads.${cycle}.ctl
            rm -f tmp.ctl
            rm -f ${dtype}.ctl


            #--------------------------------------------------------------
            #  link in the ${dtype}_grads.${PDATE} data file from TANKDIR
            #--------------------------------------------------------------
            grads_file=${hh_tankdir}/${cycle}/${dtype}.grads.${cycle}.${PDATE}

            if [ -s ${grads_file}.${Z} ]; then
               ${UNCOMPRESS} ${grads_file}
               ln -s ${grads_file} ${dtype}.grads.${cycle}.${PDATE} 
   
            elif [ -s ${grads_file} ]; then
               ln -s ${grads_file} ${dtype}.grads.${cycle}.${PDATE} 

            else
               continue
            fi

            stnmap -1 -i ${dtype}.grads.${cycle}.ctl 

         done         ## done with cycle


	 #  add check for grads_files here, continue if not found

         if [[ -e ${dtype}.grads.ges.${PDATE} && -e ${dtype}.grads.anl.${PDATE} ]]; then
            echo "OK to plot ${dtype}"

            #---------------------------------------------
            # set plot variables in the GrADS script
            #---------------------------------------------
            sed -e "s/XSIZE/$xsize/" \
                -e "s/YSIZE/$ysize/" \
                -e "s/PLOTFILE/$mtype/" \
                -e "s/PLOT2/$dtype/" \
                -e "s/RDATE/$PDATE/" \
                -e "s/HINT/${hint}/" \
                -e "s/NT/$nt/" \
               plot_${dtype}.gs >plothorz_${dtype}.gs

            $GRADS -blc "run plothorz_${dtype}.gs" 

      	    outdir=${C_IMGNDIR}/pngs/horz
            mkdir -p ${outdir}

            img_files=`ls *.png`
            for imgf in ${img_files}; do
               newf=`echo $imgf | sed -e "s/\./.${PDATE}./g"`
               mv ${imgf} ${outdir}/${newf}
            done

         else
	    echo "No data for ${dtype}, skipping plot"; echo
         fi

      done      ### dtype loop 

   done      ### type loop


   if [[ ${C_IG_SAVE_WORK} -eq 0 ]]; then
      cd ${workdir}
      cd ..
      rm -rf ${workdir}
   fi


   echo "<-- plot_horz.sh"

exit 

