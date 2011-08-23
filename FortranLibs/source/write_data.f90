subroutine open_file(funit,fname)
  implicit none
  character(len=*) :: fname
  integer :: funit

  open(funit,file=fname,status="unknown",form="formatted")

  return 
end

subroutine write_header(funit,header)
  implicit none
  integer funit
  character(len=*) :: header

  write(funit,*) header

  return
end

subroutine write_data(funit,var,nmon)
  implicit none
  integer funit
  integer nmon
  real var(nmon)
  character :: cfmt*15
  
  write(cfmt,'(a1,i4,a6)')'(',nmon,'f8.2)'
  write(funit,cfmt) var
  return
end

subroutine close_file(funit)
  implicit none
  integer funit

  close(funit)

  return
end
