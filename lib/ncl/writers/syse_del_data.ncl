
function syse_del_data(src,vnm,vfrq,vtyp,yrs,opt)
local sopt, d_root
begin
  sopt=opt
  if .not. isatt(sopt, "DataRoot")
    d_root = getenv("SysE_DB")
  else
    d_root = sopt@DataRoot
  end if
  path = file_join((/d_root,str_upper(src),vfrq,vtyp/))
  if typeof(yrs) .eq. "logical"
    if vtyp .eq. "Climatology"
      file_path = file_join((/path,vnm+".nc"/))
      system("rm "+file_path)
      return(True)
    else
      return(False)
    end if
  end if
  do iyr = yrs(0), yrs(1)
    file_path = file_join((/path,""+iyr,vnm+".nc"/))
    if file_exists(file_path)
      system("rm "+file_path)
    end if
  end do
  return(True)
end

function syse_del_dly_mean(src,vnm,yrs,opt)
begin
  return(syse_del_data(src,vnm,"Daily","Mean",yrs,opt))
end

function syse_del_mon_mean(src,vnm,yrs,opt)
begin
  return(syse_del_data(src,vnm,"Monthly","Mean",yrs,opt))
end

function syse_del_mon_clim(src,vnm,opt)
begin
  return(syse_del_data(src,vnm,"Monthly","Climatology",False,opt))
end
