subroutine open_file(funit,fname)
  implicit none
  character(len=*) :: fname
  integer :: funit

  open(funit,file=fname,status="unknown",form="formatted")

  return 
end

subroutine read_string(funit,line)
  implicit none
  integer funit
  character(len=*) :: line
  read(funit,*) line
  return
end

subroutine read_array(funit,val,nrow,ncol)
  implicit none
  integer, intent(in)::funit,nrow,ncol
  real, intent(out)  ::val(ncol,nrow)
  integer            ::i,j

  do j=1,nrow
   read(funit,*)(val(i,j),i=1,ncol)
  enddo
  return
end

subroutine close_file(funit)
  implicit none
  integer funit

  close(funit)

  return
end
