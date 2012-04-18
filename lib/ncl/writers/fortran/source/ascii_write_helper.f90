subroutine open_file(funit,fname)
  implicit none
  character(len=*) :: fname
  integer :: funit

  open(funit,file=fname,status="unknown",form="formatted")

  return 
end

subroutine write_string(funit,line)
  implicit none
  integer funit
  character(len=*) :: line
  write(funit,*) line
  return
end

subroutine write_int_array(funit,iarray,ilen)
  implicit none
  integer funit
  integer :: ilen
  integer :: iarray(ilen)
  write(funit,*) iarray
  return
end

subroutine write_real_array(funit,rarray,ilen)
  implicit none
  integer funit
  integer :: ilen
  real :: rarray(ilen)
  write(funit,*) rarray
  return
end

subroutine close_file(funit)
  implicit none
  integer funit

  close(funit)

  return
end
