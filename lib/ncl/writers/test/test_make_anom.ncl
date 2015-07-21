load "$SysE/lib/ncl/helper_libs.ncl"
load "$SysE/lib/ncl/writers/syse_put_data.ncl"

src = "NCEPR1"
vname = "omega"
lat = True
lon = True
time = (/"01Jan1948","31Dec1948"/)
opt = True
opt@months = (/"jun","sep"/)
opt@DataRoot="./"
opt@overwrite=True
opt@COARDS=True
opt@Lev=1000
var=syse_put_mon_anom(src,vname,lat,lon,time,opt)
