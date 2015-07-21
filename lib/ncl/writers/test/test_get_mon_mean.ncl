load "$SysE/lib/ncl/helper_libs.ncl"
load "$SysE/lib/ncl/readers/syse_get_data.ncl"

src = "WRF-NMM-UPDSST"
;src = "NCEPR1"
vname = "hgt"
lat = True
lon = True
time = (/"01Jun1999","30Sep1999"/)
opt = True
;opt@Lev=1000
opt@months = (/"mar","jun"/)
var=syse_get_mon_mean(src,vname,lat,lon,time,opt)
info(var)
exit
var@shaded=True
var@map=True
DebugPlot(var(0,:,:))
DebugPlot(var(5,:,:))
