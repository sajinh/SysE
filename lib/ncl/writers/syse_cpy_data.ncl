function syse_cpy_data(frm,to,src,vnm,vfrq,vtyp,yrs,opt)
local sopt, d_root
begin
  sopt=opt
  path = file_join((/str_upper(src),vfrq,vtyp/))
  if typeof(yrs) .eq. "logical"
    if vtyp .eq. "Climatology"
      frm_path = file_join((/frm,path,vnm+".nc"/))
      to_path = file_join((/to,path,vnm+".nc"/))
      if file_exists(frm_path)
        system("cp "+frm_path+" "+to_path)
      end if
      return(True)
    else
      return(False)
    end if
  end if
  do iyr = yrs(0), yrs(1)
    frm_path = file_join((/frm,path,""+iyr,vnm+".nc"/))
    to_path = file_join((/to,path,""+iyr,vnm+".nc"/))
    if file_exists(frm_path)
      system("cp "+frm_path+" "+to_path)
    end if
  end do
  return(True)
end

function syse_cpy_dly_mean(frm,to,src,vnm,yrs,opt)
begin
  return(syse_cpy_data(frm,to,src,vnm,"Daily","Mean",yrs,opt))
end

function syse_cpy_mon_mean(frm,to,src,vnm,yrs,opt)
begin
  return(syse_cpy_data(frm,to,src,vnm,"Monthly","Mean",yrs,opt))
end

function syse_cpy_mon_clim(frm,to,src,vnm,opt)
begin
  return(syse_cpy_data(frm,to,src,vnm,"Monthly","Climatology",False,opt))
end
