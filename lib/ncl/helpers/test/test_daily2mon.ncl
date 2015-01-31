load "$SysE/lib/ncl/helper_libs.ncl"
load "$SysE/lib/ncl/readers/CMS_Retrieve3.ncl"
load "$SysE/lib/ncl/writers/CMS_Deposit4.ncl"

function get_it()
begin
  vname = "olr"
  opt = True
  opt@DataRoot=getenv("SysE_DB")
  opt@DataSource="NOAA"
  opt@DataFreq="Daily"
  opt@DataType="Climatology"
  opt@vname=vname
  var=slice_data(opt)
  return(var)
end

var = get_it
info(var)
time=var&time
sten=daily_to_monthly(time)
stim=sten[0]
etim=sten[1]
nmon=dimsizes(stim)
lon = var&lon
lat = var&lat
mvar = new( (/nmon, dimsizes(lat), dimsizes(lon)/), typeof(var))
mvar(0,:,:) = var(0,:,:) ; just a trick to transfer metadata from var to mvar
do imon=0,nmon-1
  m1 = stim(imon)
  m2 = etim(imon)
  mvar(imon,:,:) = dim_avg_n(var({m1:m2},:,:),0)
end do
tunits=sten@tunits
yr1=sten@yr1
yr2=sten@yr2
mo1=sten@mo1
mo2=sten@mo2
dy1=sten@dy1
dy2=sten@dy2

mtime = make_monthly_time(yr1,mo1,15,yr2,mo2,15,tunits,nmon)
mtime!0="time"
mtime&time=mtime
mvar&time=mtime

outfil="month_olr.nc"
rm_file_if_present(outfil)
fout=fopen_write(outfil)
fout->olr=mvar
