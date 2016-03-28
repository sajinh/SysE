load "$SysE/lib/ncl/helper_libs.ncl"
load "$SysE/lib/ncl/readers/syse_get_data.ncl"

src = "WRF-NMM-UPDSST"
vnm = "rain"
src = "NOAA"
vnm = "olr"
lat = True
lon = True
time = (/"01Jun1997","30Sep1999"/)
opt = True
;opt@months = (/"jun","jun"/)
opt@ddmmm = (/"21Dec","01Jan"/)
var=syse_get_dly_mean(src,vnm,lat,lon,time,opt)
info(var)
exit
var@shaded=True
var@map=True
DebugPlot(var(0,:,:))
