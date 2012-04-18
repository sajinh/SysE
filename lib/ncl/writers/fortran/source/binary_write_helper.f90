subroutine open_file_bigendian(funit,fname)
  implicit none
  character(len=*) :: fname
  integer :: funit
  open(funit,file=fname,form="unformatted",convert="big_endian")
  return
end

subroutine open_file_littleendian(funit,fname)
  implicit none
  character(len=*) :: fname
  integer :: funit
  open(funit,file=fname,form="unformatted",convert="little_endian")
  return
end

subroutine close_file(funit)
  implicit none
  integer funit
  close(funit)
  return
end


