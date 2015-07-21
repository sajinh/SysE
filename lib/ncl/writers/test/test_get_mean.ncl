load "$SysE/lib/ncl/helper_libs.ncl"
load "$SysE/lib/ncl/readers/syse_get_data.ncl"

src = "WRF-NMM-UPDSST"
vname = "rain"
lat = True
lon = True
time = (/"01Jun1999","30Sep2005"/)
opt = True
opt@months = (/"jul","sep"/)
var=syse_get_dly_mean(src,vname,lat,lon,time,opt)
info(var)
exit
var@shaded=True
var@map=True
DebugPlot(var(0,:,:))
