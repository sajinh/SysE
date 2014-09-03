function fopen_read(fname)
begin
  return(addfile(fname,"r"))
end
function fopen_write(fname)
begin
  return(addfile(fname,"c"))
end
procedure rm_file_if_present(filnam)
begin
  if (isfilepresent(filnam))
    system("rm "+filnam)
  end if
end
function file_exists(fname)
begin
  return(systemfunc("test -f "+fname+"; echo $?") .eq. 0)
end
