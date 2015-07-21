load "$SysE/lib/ncl/helper_libs.ncl"
load "$SysE/lib/ncl/writers/syse_put_data.ncl"

src = "WRF-NMM-UPDSST"
vnm = "rain"
lat = True  ; set to True to choose the full available range
lon = True  ; to select a particular range specify (/lat1,lat2/)
tim = (/"01Jun1999","30Sep2005"/)
opt = True
opt@months = (/"jun","sep"/)
var=syse_get_mon_anom(src,vnm,lat,lon,tim,opt)
info(var)

