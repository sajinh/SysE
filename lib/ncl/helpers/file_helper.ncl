function ncl_version()
begin
  ver = stringtochar(get_ncl_version)
  ver@maj = tointeger(chartostring(ver(0))) 
  ver@mnr = tointeger(chartostring(ver(2))) 
  ver@sub = tointeger(chartostring(ver(4))) 
  return(ver)
end
function ncl_file_exists(arg)
begin
  nclv= ncl_version
  if (nclv@maj .gt. 6)
    return(fileexists(arg))
  end if
  if nclv@maj .eq. 6
    if nclv@mnr .gt. 2
      return(fileexists(arg))
    end if
    if nclv@mnr .eq. 2
      if nclv@sub .ge. 1
        return(fileexists(arg))
      end if
    end if
  end if
  return(isfilepresent(arg))
end
function unx_file_exists(arg)
begin
  return(ncl_file_exists(arg))
end
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
  if (ncl_file_exists(filnam))
    pp("removing "+filnam)
    system("rm "+filnam)
  end if
end
function file_exists(fname)
begin
  return(systemfunc("test -f "+fname+"; echo $?") .eq. 0)
end
procedure make_the_dir(dirName)
local dirName
begin
  system("mkdir -p "+dirName)
end
procedure mkdir(dirName)
begin
  system("mkdir "+dirName)
end
procedure mkdir_p(dirName)
local root, dirs
begin
  root = str_get_cols(dirName,0,0)
  dirs = str_split(dirName,"/")
  ndir = dimsizes(dirs)
  dnm = ""+root
  do i=0,ndir-1
    dnm=dnm+"/"+dirs(i)
    if .not. unx_file_exists(dnm)
      pp("making "+dnm)
      mkdir(dnm)
    end if
  end do
end
