subroutine open_file(funit,fname)
  implicit none
  character(len=*) :: fname
  integer :: funit
  open(funit,file=fname,form="unformatted",convert="big_endian")
  return
end

subroutine read_head(funit)
  implicit none
  integer, intent(in)::funit
  character head( 64 )*16
  read(funit) head
  !print *, head
  return
end

subroutine read_arr(funit,val,narr)
  implicit none
  integer, intent(in)::funit,narr
  real, intent(out)  ::val(narr)

  read(funit) val
  return
end

subroutine close_file(funit)
  implicit none
  integer funit

  close(funit)
  return
end

