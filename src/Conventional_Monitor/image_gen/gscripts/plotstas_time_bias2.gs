*   the program plot surface pressure time series:
*   data count: no assimilated, no rejected by gross check, no rejected
*   by variational qc,  no monitored

function plot_bias2 (args)

   dtype=DTYPE
   'open ges_'dtype'_stas.ctl'
   'open anl_'dtype'_stas.ctl'
   'set grads off'
   debug=0

   'set t 1 last'
   'q time'
   dmy=sublin(result,1)
   ti=subwrd(dmy,5)
   hh=substr(ti,1,2)
   dd=substr(ti,4,2)

   'q file'
   size=sublin(result,5)
   ixc=subwrd(size,3)
   iyc=subwrd(size,6)
   izc=subwrd(size,9)

   iz=1
   while(iz <=izc)

      if (dtyp='q')
         if(iz =1);levz='2000-0mb';endif
         if(iz =2);levz='>=1000mb';endif
         if(iz =3);levz='999-950mb';endif
         if(iz =4);levz='949-900mb';endif
         if(iz =5);levz='899-850mb';endif
         if(iz =6);levz='849-800mb';endif
         if(iz =7);levz='799-750mb';endif
         if(iz =8);levz='749-700mb';endif
         if(iz =9);levz='699-600mb';endif
         if(iz =10);levz='599-500mb';endif
         if(iz =11);levz='499-400mb';endif
         if(iz =12);levz='399-300mb';endif
         if(iz =13);levz='299-0mb';endif
      else
         if(iz =1);levz='2000-0mb';endif
         if(iz =2);levz='>=1000mb';endif
         if(iz =3);levz='999-900mb';endif
         if(iz =4);levz='899-800mb';endif
         if(iz =5);levz='799-600mb';endif
         if(iz =6);levz='599-400mb';endif
         if(iz =7);levz='399-300mb';endif
         if(iz =8);levz='299-250mb';endif
         if(iz =9);levz='249-200mb';endif
         if(iz =10);levz='199-150mb';endif
         if(iz =11);levz='149-100mb';endif
         if(iz =12);levz='99-50mb';endif
         if(iz =13);levz='49-0mb';endif
      endif

      '!echo $CONMON_RESTRICT_PLOT_AREAS > rest.txt'
      rest=read(rest.txt)
      restrict=subwrd(rest,2)

      iy=1
      while(iy <=iyc)

*        In order to save space skip certain redundant regions.
         if ( restrict = 1 )
            if ( iy = 2 | iy = 3 | iy = 5 | iy = 6 )
               iy=iy+1
               continue
            endif
         endif

         '!rm -f area.txt'
         '!cat ges_'dtype'_stas.ctl |grep "region= 'iy' " > area.txt'
         result=read(area.txt)
         rc=sublin(result,1)
         area="uknown"
         if (rc = 0)
            info=sublin(result,2)
            area=substr(info,14,25)
         endif
         result=close(area.txt)
         ix=1

         while(ix <=ixc)

            '!rm -f info.txt'
            '!cat ges_'dtype'_stas.ctl |grep "'ix' dtype=" > info.txt'
            result=read(info.txt)
            rc=sublin(result,1)
            iuse=0
            if (rc = 0)
               info=sublin(result,2)
               stype=subwrd(info,6)
               subtype=subwrd(info,8)
               iuse=subwrd(info,10)
            endif
            result=close(info.txt)

*           Avoid plotting syptes "uv235" and "all".  Stype all is included in the ctl file (from
*           which the stypes are taken) but the web site has never included stype all, so
*           eliminating plotting them is a space/time savings.  Stype 235 (uv only) produces
*           missing data errors on half the plots -- the upper half.  This will be
*           investigated in a separate fix.
            if ( stype = 235 | stype = all )
               ix=ix+1
               continue
            endif

            plottime(ix,iy,iz,dtype,hh,dd,area,stype,subtype,iuse,levz,debug)

            ix=ix+1
         endwhile

         iy=iy+1
      endwhile
      iz=iz+1
   endwhile

   return
endfile



function plottime(ix,iy,iz,dtype,hh,dd,area,stype,subtype,iuse,levz,debug)

   'clear'

   nfield=4
   field.1.1=bias2.1
   field.1.2=bias2.2

   field.2.1=rms2.1
   field.2.2=rms2.2

   field.3.1=bias3.1
   field.3.2=bias3.2

   field.4.1=rms3.1
   field.4.2=rms3.2

   title.1="o-g for rej. by GC "
   title.2="rms for rej. by GC"
   title.3="o-g for monitored"
   title.4="rms for monitored"

   'set t 1'
   'query time'
   fdmy=sublin(result,1)
   fti=subwrd(fdmy,5)

   nf=1
   while(nf <=nfield)
      y1=10.6-(nf-1)*2.5
      y2=y1-1.8
      ystring=y1+0.1
      'set t 1 last'
      'query time'
      dmy=sublin(result,1)
      ti=subwrd(dmy,5)

      'set y 'iy
      'set x 'ix
      'set z 'iz
      'set gxout stat'
      'd 'field.nf.1

      rec8=sublin(result,8)
      minvar1=subwrd(rec8,4)
      maxvar1=subwrd(rec8,5)
      'd 'field.nf.2
      rec8=sublin(result,8)
      maxvar=subwrd(rec8,5)
      minvar=subwrd(rec8,4)

      if(minvar > minvar1)
         minvar=minvar1
      endif
      if(maxvar1 > maxvar)
         maxvar=maxvar1
      endif

      yrange=maxvar-minvar
      dy=0.1*yrange
      minvar=minvar-dy
      maxvar=maxvar+dy
      'set parea 1.0 8.0 'y2' 'y1
      'set gxout line'
      'set t 1 last'
      'set datawarn off'
      'set tlsupp year'
      'set grads off'
      'set y 'iy
      'set x 'ix
      'set z 'iz
      'set vrange 'minvar' 'maxvar
      'set ccolor 1'
      'set cmark 0'
      'd  'field.nf.1
      'set ccolor 2'
      'set cmark 1'
      'd  'field.nf.2
      'set ccolor 3'
      if(iuse = -1)
         datause='mon.'
      else
         datause='used'
      endif

      'draw string 1.1 'ystring' 'dtype' 'stype'-'subtype'('datause'):'title.nf' at 'area' for 'levz 
      'set line 1 1'
      'draw line 1.1 0.6 1.4 0.6'
      'draw string 1.5 0.55  init. outloop'
      'set line 2 1'
      'draw line 3.1 0.6 3.4 0.6'
      'draw string 3.5 0.55  final outloop'
      'draw string 5.5 0.55   'fti'-'ti
       nf=nf+1
   endwhile

   outfile=dtype''stype'-'subtype'_bias2_region'iy'_lev'iz'.png'

   'printim 'outfile' x950 y750 white'
   if(debug=1)
      say 'enter'
      pull
   endif

return
