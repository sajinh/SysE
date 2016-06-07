load "$SysE/lib/ncl/readers/SysE_DB_get.ncl"

function syse_get_data(src,vname,lat,lon,time,opt)
local sopt
begin
  sopt = opt
  if .not. isatt(sopt, "DataRoot")
    sopt@DataRoot = getenv("SysE_DB")
  end if
  if typeof(lat) .ne. "logical"
    sopt@Lat=lat
  end if
  if typeof(lon) .ne. "logical"
    sopt@Lon=lon
  end if
  sopt@Time=time
  sopt@DataSource=src
  sopt@vname=vname

  if isatt(sopt,"local_file")
    if .not. isatt(sopt,"LocalFile")
      sopt@LocalFile = sopt@local_file
    end if
  end if
  if isatt(sopt,"purge_local_file")
    if .not. isatt(sopt,"PurgeLocalFile")
      sopt@PurgeLocalFile = sopt@purge_local_file
    end if
  end if

  if isatt(sopt,"LocalFile")
    if isatt(sopt,"PurgeLocalFile")
      if sopt@PurgeLocalFile
        pp("purging "+sopt@LocalFile)
        rm_file_if_present(sopt@LocalFile)
      end if
    end if
    return(slice_data_cached(sopt))
  else
    return(slice_data(sopt))
  end if
end

function syse_get_mon_anom(src,vname,lat,lon,time,opt)
local sopt
begin
  sopt=opt
  sopt@DataFreq="Monthly"
  sopt@DataType="Anomaly"
  return(syse_get_data(src,vname,lat,lon,time,sopt))
end

function syse_get_mon_clim(src,vname,lat,lon,time,opt)
local sopt, tim2
begin
  sopt=opt
  sopt@DataFreq="Monthly"
  sopt@DataType="Climatology"
  sopt@Statistic="Mean"
  if typeof(time) .eq. "logical"
    if isatt(sopt,"months")
      tim2 =(/"01Jan1904","31Dec1904"/)
      return(syse_get_data(src,vname,lat,lon,tim2,sopt))
    else
      abort("Please provide option opt@months=(/start_month,end_month/)")
    end if
  end if
  return(syse_get_data(src,vname,lat,lon,time,sopt))
end

function syse_get_mon_cstd(src,vname,lat,lon,time,opt)
local sopt
begin
  sopt=opt
  sopt@DataFreq="Monthly"
  sopt@DataType="Climatology"
  sopt@Statistic="stddev"
  if typeof(time) .eq. "logical"
    if isatt(sopt,"months")
      tim2 =(/"01Jan1904","31Dec1904"/)
      return(syse_get_data(src,vname,lat,lon,tim2,sopt))
    else
      abort("Please provide option opt@months=(/start_month,end_month/)")
    end if
  end if

  return(syse_get_data(src,vname,lat,lon,time,sopt))
end

function syse_get_mon_mean(src,vname,lat,lon,time,opt)
local sopt
begin
  sopt=opt
  sopt@DataFreq="Monthly"
  sopt@DataType="Mean"
  return(syse_get_data(src,vname,lat,lon,time,sopt))
end

function syse_get_dly_anom(src,vname,lat,lon,time,opt)
local sopt
begin
  sopt=opt
  sopt@DataFreq="Daily"
  sopt@DataType="Anomaly"
  return(syse_get_data(src,vname,lat,lon,time,sopt))
end

function syse_get_dly_clim(src,vname,lat,lon,time,opt)
local sopt
begin
  sopt=opt
  sopt@DataFreq="Daily"
  sopt@DataType="Climatology"
  sopt@Statistic="mean"
  if typeof(time) .eq. "logical"
    if isatt(sopt,"months") .or. isatt(sopt,"ddmmm")
      tim2 =(/"01Jan1904","31Dec1904"/)
      return(syse_get_data(src,vname,lat,lon,tim2,sopt))
    else
      abort("Please provide option opt@months=(/start_month,end_month/) or opt@ddmmm=(/ddmmm,ddmmm/)")
    end if
  end if
  return(syse_get_data(src,vname,lat,lon,time,sopt))
end

function syse_get_dly_cstd(src,vname,lat,lon,time,opt)
local sopt
begin
  sopt=opt
  sopt@DataFreq="Daily"
  sopt@DataType="Climatology"
  sopt@Statistic="stddev"
  if typeof(time) .eq. "logical"
    if isatt(sopt,"months") .or. isatt(sopt,"ddmmm")
      tim2 =(/"01Jan1904","31Dec1904"/)
      return(syse_get_data(src,vname,lat,lon,tim2,sopt))
    else
      abort("Please provide option opt@months=(/start_month,end_month/) or opt@ddmmm=(/ddmmm,ddmmm/)")
    end if
  end if
  return(syse_get_data(src,vname,lat,lon,time,sopt))
end

function syse_get_dly_mean(src,vname,lat,lon,time,opt)
local sopt
begin
  sopt=opt
  sopt@DataFreq="Daily"
  sopt@DataType="Mean"
  return(syse_get_data(src,vname,lat,lon,time,sopt))
end
