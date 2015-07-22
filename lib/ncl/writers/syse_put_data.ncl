load "$SysE/lib/ncl/readers/syse_get_data.ncl"
load "$SysE/lib/ncl/writers/SysE_DB_put.ncl"

function make_new_clmarr(var,ntim,sopt)
begin
  lat = var&lat
  lon = var&lon
  nlon = dimsizes(lon)
  nlat = dimsizes(lat)
  nlev = 2 ; one for clim and another for std
  clmarr =(new( (/ntim,nlev,nlat,nlon/), typeof(var)))
  clmarr!0 = "time"
  clmarr!1 = "level"
  tunits="days since 1900-01-01"
  m1 = ntim@m1
  m2 = ntim@m2
  if (sopt@dataFreq .eq. "Monthly")
    clmarr&time = make_monthly_time(1904,m1,15,1904,m2,15,tunits,ntim)
  else
    d1 = ntim@d1
    d2 = ntim@d2
    clmarr&time = make_daily_time(1904,m1,d1,1904,m2,d2,tunits,ntim)
  end if
  clmarr&level = ispan(1,nlev,1)
  clmarr&level@description = "climatology"
  if .not. isatt(sopt,"COARDS")
    sopt@COARDS=True
  end if
  if sopt@COARDS ; make level to appear as depth
    clmarr&level@long_name="depth"
    clmarr&level@units="m"
  end if
  return(clmarr)
end

function write_out_climatology(vclm,vnm,src,frq,sopt)
begin
  if isatt(vclm,"cut_ntim")
    pp("found a cut_ntim")
    delete(vclm@cut_ntim)
  end if
  if isatt(sopt,"FillGaps")
    vclm=SysE_FillGaps(vclm,sopt@FillGaps)
  end if
  dataSrc   = str_upper(src)
  dataFrq   = frq
  dataTyp   = "Climatology"
  if .not. isatt(sopt, "DataRoot")
    DataRoot = getenv("SysE_DB")
  end if
  outdir    = create_outdir((/DataRoot,dataSrc,dataFrq,dataTyp/))
  remove_xtra_slashes_of(outdir)
  mkdir_p(outdir)
  ovnm=vnm
  if isatt(sopt,"Lev")
    ovnm=ovnm+"_"+sopt@Lev(0)
  end if
  if (isatt(sopt,"overwrite") .and. sopt@overwrite)
    rm_file_if_present(name_of_outfil(outdir,ovnm))
  end if
  outfil    = create_file_if_not_exists(outdir,ovnm)
  fout      = fopen_write(outfil)
  print("Write Climatology to DataBase")
  write_TLLL(fout,vnm,vclm)
  return(True)
end

function sopt_to_months(opt)
local sopt
begin
  sopt=opt
  if isatt(sopt,"months")
    if (typeof(sopt@months) .eq. "string")
      months=(month_to_int(sopt@months))
    else
      months = sopt@months
    end if
  end if
  return(months)
end


function syse_write_mon_clim(src,vnm,lat,lon,tim,opt)
local sopt, nmon
begin
  sopt=opt
  var = syse_get_mon_mean(src,vnm,lat,lon,tim,sopt)
  months=sopt_to_months(sopt)
  smonths = ispan(months(0),months(1),1)
  nmon   = dimsizes(smonths)
  nmon@m1 = months(0)
  nmon@m2 = months(1)
  sopt@dataFreq="Monthly"
  do i = 0,nmon-1
    tmn = dim_avg_n_Wrap(var(i::nmon,:,:),0) ; how to do this for daily clim?
    tsd = dim_stddev_n_Wrap(var(i::nmon,:,:),0)
    if (i.eq.0)
      vclm=make_new_clmarr(tmn,nmon,sopt)
    end if
    vclm(i,0,:,:) = tmn
    vclm(i,1,:,:) = tsd
  end do
  return(write_out_climatology(vclm,vnm,src,"Monthly",sopt))
end

function syse_write_dly_clim(src,vnm,lat,lon,tim,opt)
local sopt, opt_ddmmm, opt_months 
begin
  sopt=opt
  var = syse_get_dly_mean(src,vnm,lat,lon,tim,sopt)
  dims = dimsizes(var)
  cut_ntim = var@cut_ntim
  y1 = toint(str_get_cols(tim(0),5,8))
  y2 = toint(str_get_cols(tim(1),5,8))
  nyr = y2-y1+1
  if isatt(sopt,"ddmmm")
    opt_ddmmm = sopt@ddmmm
    d1 = toint(str_get_cols(opt_ddmmm(0),0,1))
    d2 = toint(str_get_cols(opt_ddmmm(1),0,1))
    m1 = integer_value_of_month(str_get_cols(opt_ddmmm(0),2,4))
    m2 = integer_value_of_month(str_get_cols(opt_ddmmm(1),2,4))
  else
    opt_months = sopt_to_months(sopt)
    m1 = opt_months(0)
    m2 = opt_months(1)
    d1 = 1
    d2 = days_in_month(1904,m2)
  end if
  cd1=day_of_year(1904,m1,d1)
  cd2=day_of_year(1904,m2,d2)
  ncday = cd2-cd1+1
  sopt@dataFreq="Daily"
  if all(cut_ntim .eq. ncday)
    var2 = var
  else
    ; we make new var2 where all years have same no of days
    var2 = new( (/nyr*ncday,dims(1),dims(2)/), typeof(var))
    ic = 0
    do iyr = 0,nyr-1
      ndiy = cut_ntim(iyr)
      var2(ic:ndiy-1,:,:) = var(ic:ndiy-1,:,:)
      if ndiy .ne. ncday
        var2(ic:ndiy,:,:) = var2(ic:ndiy-1,:,:)
      end if
      ic = ic+ncday
    end do
  end if
  delete(var)
  ntim = ncday
  ntim@m1 = m1
  ntim@m2 = m2
  ntim@d1 = d1
  ntim@d2 = d2
  do i=0,ncday-1
    tmn = dim_avg_n_Wrap(var2(i::ncday,:,:),0) 
    tsd = dim_stddev_n_Wrap(var2(i::ncday,:,:),0)
    if (i.eq.0)
      vclm=make_new_clmarr(tmn,ntim,sopt)
    end if
    vclm(i,0,:,:) = tmn
    vclm(i,1,:,:) = tsd
  end do
  return(write_out_climatology(vclm,vnm,src,"Daily",sopt))
  ; there is no existing function, so we do climatology ourselves
  ; make array to store climatology
  ; cut data for each year
  ;    - two cases
  ;    - no leap month : equal division among years
  ;    - leap month present : divide inequally allow for extra day in feb
end

function syse_write_mon_anom(src,vnm,lat,lon,tim,opt)
begin
  ; get clim data
  ; year by year :do
  ;   get mean data
  ;   cal anom
  ;   wrt anom
  ; end
  sopt=opt
  yr1 = toint(str_get_cols(tim(0),5,8))
  yr2 = toint(str_get_cols(tim(1),5,8))
  yrs = ispan(yr1,yr2,1)
  nyr = dimsizes(yrs)
  mos = sopt@months
  if (typeof(mos) .eq. "integer")
    mo1 = integer_to_month(mos(0))
    mo2 = integer_to_month(mos(1))
  else
    mo1 = mos(0)
    mo2 = mos(1)
  end if
  vclm = syse_get_mon_clim(src,vnm,lat,lon,tim,sopt)
  do iyr=0,nyr-1
    tims = (/"01"+mo1+yrs(iyr),"01"+mo2+yrs(iyr)/)
    var = syse_get_mon_mean(src,vnm,lat,lon,tims,sopt)
    var = (/ var - vclm /)
    dataSrc   = str_upper(src)
    dataFrq   = "Monthly"
    dataTyp   = "Anomaly"
    if  isatt(sopt, "DataRoot")
      DataRoot = sopt@DataRoot
    else
      DataRoot = getenv("SysE_DB")
    end if
    outdir    = create_outdir((/DataRoot,dataSrc,dataFrq,dataTyp,""+yrs(iyr)/))
    remove_xtra_slashes_of(outdir)
    mkdir_p(outdir)
    ovnm = vnm
    if isatt(sopt,"Lev")
      ovnm=ovnm+"_"+sopt@Lev(0)
    end if
    if isatt(var,"cut_ntim")
      pp("found a cut_ntim")
      delete(var@cut_ntim)
    end if
    outfil = name_of_outfil(outdir,ovnm)
    if (isatt(sopt,"overwrite") .and. sopt@overwrite)
      rm_file_if_present(outfil)
    end if
    outfil    = create_file_if_not_exists(outdir,ovnm)
    fout      = fopen_write(outfil)
    print("Write Anomaly of "+yrs(iyr)+" to DataBase")
    if (rank_of(var) .eq. 4)
      write_TLLL(fout,vnm,var)
    end if
    if (rank_of(var) .eq. 3)
      write_TLL(fout,vnm,var)
    end if
  end do
  return(True)
end

function syse_write_dly_anom(src,vnm,lat,lon,tim,opt)
begin
  ; get clim data
  ; year by year :do
  ;   get mean data
  ;   cal anom
  ;   wrt anom
  ; end
  sopt=opt
  yr1 = toint(str_get_cols(tim(0),5,8))
  yr2 = toint(str_get_cols(tim(1),5,8))
  yrs = ispan(yr1,yr2,1)
  nyr = dimsizes(yrs)
  if isatt(sopt,"ddmmm")
    opt_ddmmm = sopt@ddmmm
    d1 = toint(str_get_cols(opt_ddmmm(0),0,1))
    d2 = toint(str_get_cols(opt_ddmmm(1),0,1))
    m1 = integer_value_of_month(str_get_cols(opt_ddmmm(0),2,4))
    m2 = integer_value_of_month(str_get_cols(opt_ddmmm(1),2,4))
  else
    opt_months = sopt_to_months(sopt)
    m1 = opt_months(0)
    m2 = opt_months(1)
    d1 = 1
    d2 = days_in_month(1904,m2)
  end if
  vclm = syse_get_dly_clim(src,vnm,lat,lon,tim,sopt)
  ntim = dimsizes(vclm&time)
  do iyr=0,nyr-1
    da1 = sprinti("%0.2i",d1)
    mo1 = integer_to_month(m1)
    mo2 = integer_to_month(m2)
    if ((.not. isleapyear(yrs(iyr))) .and. (m2 .eq. 2))
      da2 = sprinti("%0.2i",d2-1)
    else
      da2 = sprinti("%0.2i",d2)
    end if
    tims = (/da1+mo1+yrs(iyr),da2+mo2+yrs(iyr)/)
    var = syse_get_dly_mean(src,vnm,lat,lon,tims,sopt)
    nvtim = dimsizes(var&time)
    if (ntim .ne. nvtim)
      var = (/ var - vclm(:ntim-2,:,:) /)
    else
      var = (/ var - vclm /)
    end if
    dataSrc   = str_upper(src)
    dataFrq   = "Daily"
    dataTyp   = "Anomaly"
    if  isatt(sopt, "DataRoot")
      DataRoot = sopt@DataRoot
    else
      DataRoot = getenv("SysE_DB")
    end if
    outdir    = create_outdir((/DataRoot,dataSrc,dataFrq,dataTyp,""+yrs(iyr)/))
    remove_xtra_slashes_of(outdir)
    mkdir_p(outdir)
    ovnm = vnm
    if isatt(sopt,"Lev")
      ovnm=ovnm+"_"+sopt@Lev(0)
    end if
    outfil = name_of_outfil(outdir,ovnm)
    if (isatt(sopt,"overwrite") .and. sopt@overwrite)
      rm_file_if_present(outfil)
    end if
    if isatt(var,"cut_ntim")
      pp("found a cut_ntim")
      delete(var@cut_ntim)
    end if
    outfil    = create_file_if_not_exists(outdir,ovnm)
    fout      = fopen_write(outfil)
    print("Write Anomaly of "+yrs(iyr)+" to DataBase")
    if (rank_of(var) .eq. 4)
      write_TLLL(fout,vnm,var)
    end if
    if (rank_of(var) .eq. 3)
      write_TLL(fout,vnm,var)
    end if
    delete(var)
  end do
  return(True)
end

procedure pass_to_old_syse_writer(src,vname,lat,lon,time,opt,type,freq)
begin
  sopt=opt
  if .not. isatt(sopt, "DataRoot")
    sopt@DataRoot = getenv("SysE_DB")
  end if
  sopt@DataSource=src
  sopt@vname=vname
  sopt@Time=time
  if dimsizes(lat) .eq. 2
    sopt@Lat=lat
  end if
  if dimsizes(lon) .eq. 2
    sopt@Lon=lon
  end if
  sopt@DataFreq = str_capital(str_lower(freq))
  sopt@DataType = "Mean"
  if (type .eq. "anomaly")
    Make_CMS_Anomaly(sopt)
  end if
  if (type .eq. "climatology")
    sopt@ClimPeriod = time
    Make_CMS_Climatology(sopt)
  end if
end

function syse_put_mon_clim(src,vname,lat,lon,time,opt)
begin
  if isatt(opt,"Lev")
    if dimsizes(opt@Lev) .gt. 1
      abort("You can only pass one level at a time")
    end if
  end if
  if isatt(opt,"months")
    return(syse_write_mon_clim(src,vname,lat,lon,time,opt))
  else
    pass_to_old_syse_writer(src,vname,lat,lon,time,opt,"climatology","monthly")
  end if 
  return(False)
end

function syse_put_mon_anom(src,vname,lat,lon,time,opt)
begin
  if isatt(opt,"Lev")
    if dimsizes(opt@Lev) .gt. 1
      abort("You can only pass one level at a time")
    end if
  end if
  if isatt(opt,"months")
    return(syse_write_mon_anom(src,vname,lat,lon,time,opt))
  else
    pass_to_old_syse_writer(src,vname,lat,lon,time,opt,"anomaly","monthly")
  end if 
  return(False)
end

function syse_put_dly_clim(src,vname,lat,lon,time,opt)
begin
  if isatt(opt,"Lev")
    if dimsizes(opt@Lev) .gt. 1
      abort("You can only pass one level at a time")
    end if
  end if
  if isatt(opt,"months") .or. isatt(opt,"ddmmm")
    return(syse_write_dly_clim(src,vname,lat,lon,time,opt))
  else
    pass_to_old_syse_writer(src,vname,lat,lon,time,opt,"climatology","daily")
  end if 
  return(False)
end

function syse_put_dly_anom(src,vname,lat,lon,time,opt)
begin
  if isatt(opt,"Lev")
    if dimsizes(opt@Lev) .gt. 1
      abort("You can only pass one level at a time")
    end if
  end if
  if isatt(opt,"months") .or. isatt(opt,"ddmmm")
    return(syse_write_dly_anom(src,vname,lat,lon,time,opt))
  else
    pass_to_old_syse_writer(src,vname,lat,lon,time,opt,"anomaly","daily")
  end if 
  return(False)
end

