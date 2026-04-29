!-----------------------------------------------------
!  program mainread_pw
!
!-----------------------------------------------------

   implicit none

   external ::  convinfo_read
   external ::  read_pw
   external ::  read_pw_mor

   character*200 fname
   character*50 fileo
   character*15 mtype

   real rpress,rlev

   integer nreal,insubtype
   integer isubtype,ncount_gros,ncount_vgc,ncount

   integer(4):: ituse,ntumgrp,ntgroup,ntmiter
   real(4) :: ttwind,gtross,etrmax,etrmin,vtar_b,vtar_pg

   real(4) :: rmiss

   data rmiss/-999.0/ 


   namelist /input/nreal,mtype,fname,fileo,rlev,insubtype
 

   read (5,input)
!   write(6,input)

   ncount=0
   rpress=rmiss
   ncount_vgc=0
   ncount_gros=0

!   print *,mtype,nreal

   call convinfo_read(mtype,15,insubtype,ituse,ntumgrp,ntgroup,ntmiter,isubtype,&
                      ttwind,gtross,etrmax,etrmin,vtar_b,vtar_pg)

!   print *,'ituse=',ituse,gtross

   if (ituse >0) call read_pw(nreal,mtype,fname,fileo,gtross,rlev) 
   if (ituse <0) call read_pw_mor(nreal,mtype,fname,fileo,gtross,rlev) 
  
   stop
end
