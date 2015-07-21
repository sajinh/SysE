load "$SysE/lib/ncl/helper_libs.ncl"
load "$SysE/lib/ncl/readers/syse_get_data.ncl"

src = "WRF-NMM-UPDSST"
vname = "rain"
lat = True
lon = True
time = (/"01Jun1999","30Sep1999"/)
opt = True
opt@months = (/"jun","jun"/)
opt@ddmmm = (/"01Jun","05Jun"/)
var=syse_get_dly_cstd(src,vname,lat,lon,time,opt)
info(var)
var@shaded=True
var@map=True
DebugPlot(var(1,:,:))
