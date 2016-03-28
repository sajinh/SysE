subroutine open_file(funit,fname)
  implicit none
  character(len=*) :: fname
  integer :: funit
  open(funit,file=fname,form="unformatted")
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

subroutine read_char16_arr(funit,val,nchar)
  implicit none
  integer, intent(in)::funit,nchar
  character ::val(nchar)*16
  read(funit) val
  return 
end

