load "$SysE/lib/ncl/helper_libs.ncl"
load "$SysE/lib/ncl/writers/syse_put_data.ncl"

src = "WRF-NMM-UPDSST"
vname = "rain"
lat = True
lon = True
time = (/"01Jun1999","30Sep2005"/)
opt = True
opt@months = (/"jun","sep"/)
opt@overwrite=True
opt@COARDS=True
opt@NumHarmonics=3
var=syse_put_dly_anom(src,vname,lat,lon,time,opt)
