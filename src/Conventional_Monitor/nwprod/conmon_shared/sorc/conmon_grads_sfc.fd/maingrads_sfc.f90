!-----------------------------------------------------------------------------
!  maingrads_sfc
!
!    This program reads the conventional data and converts it into GrADS
!    data files.  The data is a profile type having multiple levels.
!
!-----------------------------------------------------------------------------
program maingrads_sfc

   use generic_list
   use data
   use conmon_read_diag

   implicit none

   interface

      subroutine grads_sfc(fileo,ifileo,nobs,nreal,iscater,igrads,&
                           subtype, list, run)
         use generic_list

         integer ifileo
         character(ifileo)              :: fileo
         integer                        :: nobs,nreal,iscater,igrads
         character(3)                   :: subtype
         type(list_node_t), pointer     :: list
         character(3)                   :: run
      end subroutine grads_sfc

   end interface

   character(10) :: stype 
   character(3) :: intype
   character(3) :: subtype
   integer nreal,iscater,igrads,isubtype 
   integer nobs,lstype
   integer itype

   type(list_node_t), pointer   :: list => null()

   !--- namelist with defaults
   logical               :: netcdf              = .false.
   character(100)        :: input_file          = "conv_diag"
   character(3)          :: run                 = "ges"
   namelist /input/input_file,intype,stype,itype,nreal,iscater,igrads,subtype,isubtype,netcdf,run

   read(5,input)
   write(6,*)' User input below'
   write(6,input)

   lstype=len_trim(stype) 

   write(6,*)'netcdf       =', netcdf
   call set_netcdf_read( netcdf )

   call conmon_read_diag_file( input_file, intype, itype, nreal, nobs, isubtype, list )

 
   if( nobs > 0 ) then
      call grads_sfc(stype,lstype,nobs,nreal,iscater,igrads,subtype,list,run) 
   else
      print *, 'NOBS <= 0, NO OUTPUT GENERATED'
   end if

   call list_free( list )

   stop
end
