program radiance_names
  use valid, only: load_base
  use bad_chan, only: open_bad_chan_file, write_bad_chan, close_bad_chan_file
  use low_count, only: open_low_count_file, write_low_count, close_low_count_file
  use bad_penalty, only: open_bad_penalty_file, write_bad_penalty, close_bad_penalty_file
  implicit none
  character(10) :: ftype(1), satype
  character(11) :: dplat
  character(22) :: satname
  character(26) :: output_name
  character(8) :: cycle
  character(40) :: region(1)
  character(80) :: ctl_file
  character(256) :: line
  integer :: channels(1), ios, i
  real :: values(1)

  ftype = 'count'
  region = 'global'
  channels = 1
  values = 1.0
  cycle = '00'
  do i = 1, 3
     if (i == 1) then
        satype = 'abcdefghij'
        dplat = '12345678901'
     else if (i == 2) then
        satype = 'mws'
        dplat = 'metop-sg-a1'
     else
        satype = 'amsua'
        dplat = 'metop-b'
     endif
     satname = trim(satype)//'_'//trim(dplat)
     output_name = trim(satname)//'_anl'

     ctl_file = 'time.ctl'
     call create_ctl_time(1,ftype,1,2026,1,1,0,0,6,ctl_file,20,-999., &
          output_name,satype,dplat,1,region,values,values,values,values, &
          channels,values,values,values,values,1)
     call check_ctl(ctl_file,output_name,dplat)
     ctl_file = 'angle.ctl'
     call create_ctl_angle(1,ftype,1,2026,1,1,0,6,ctl_file,20,-999., &
          output_name,satype,dplat,1,region,values,values,values,values, &
          channels,values,values,values,values,95,-49.312,1.049,1)
     call check_ctl(ctl_file,output_name,dplat)
     ctl_file = 'bcor.ctl'
     call create_ctl_bcor(1,ftype,1,2026,1,1,0,0,6,ctl_file,20,-999., &
          output_name,satype,dplat,1,region,values,values,values,values, &
          channels,values,values,values,values,1)
     call check_ctl(ctl_file,output_name,dplat)
     ctl_file = 'bcoef.ctl'
     call create_ctl_bcoef(1,ftype,1,2026,1,1,0,0,6,ctl_file,20,-999., &
          output_name,satype,dplat,channels,values,values,values,values,1)
     call check_ctl(ctl_file,output_name,dplat)
  enddo

  satname = 'abcdefghij_12345678901'
  open(21,file=trim(satname)//'.base',status='replace')
  write(21,*) trim(satname), ' ', '2026010100', 1, 1
  write(21,*) 1, 1, 10., 1., 5., 15., 2., 1., 1., 3.
  close(21)
  call load_base(satname,ios)
  if (ios /= 0) error stop 'long base filename not found'

  call open_bad_chan_file('20260101',cycle,ios)
  if (ios /= 0) error stop 'cannot open bad channel report'
  call write_bad_chan(satname,1)
  call close_bad_chan_file()
  open(21,file='bad_chan.2026010100',status='old')
  read(21,'(a)') line
  close(21)
  if (index(line,trim(satname)//' channel=') == 0) error stop 'truncated bad channel name'

  call open_low_count_file('20260101',cycle,ios)
  if (ios /= 0) error stop 'cannot open low count report'
  call write_low_count(satname,1,1,10.,20.)
  call close_low_count_file()
  open(21,file='low_count.2026010100',status='old')
  read(21,'(a)') line
  close(21)
  if (index(line,trim(satname)//' channel=') /= 1) error stop 'truncated low count name'

  call open_bad_penalty_file('20260101',cycle,ios)
  if (ios /= 0) error stop 'cannot open penalty report'
  call write_bad_penalty(satname,1,1,10.,20.)
  call close_bad_penalty_file()
  open(21,file='bad_pen.2026010100',status='old')
  read(21,'(a)') line
  close(21)
  if (index(line,trim(satname)//' channel=') /= 1) error stop 'truncated penalty name'

contains
  subroutine check_ctl(filename, name, platform)
    character(*), intent(in) :: filename, name, platform
    character(256) :: record
    integer :: status
    logical :: found_title

    open(21,file=filename,status='old')
    read(21,'(a)') record
    if (trim(record) /= 'dset ^'//trim(name)//'.%y4%m2%d2%h2.ieee_d') &
         error stop 'incorrect control dataset'
    found_title = .false.
    do
       read(21,'(a)',iostat=status) record
       if (status /= 0) exit
       if (index(record,'title ') == 1 .and. index(record,trim(platform)) > 0) found_title = .true.
    enddo
    close(21)
    if (.not. found_title) error stop 'truncated platform in control title'
  end subroutine check_ctl
end program radiance_names

subroutine w3movdat(offset, idate, jdate)
  real, intent(in) :: offset(5)
  integer, intent(in) :: idate(8)
  integer, intent(out) :: jdate(8)
  jdate = idate
end subroutine w3movdat
