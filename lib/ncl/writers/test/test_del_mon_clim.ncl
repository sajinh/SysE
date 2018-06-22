load "$SysE/lib/ncl/helper_libs.ncl"
load "$SysE/lib/ncl/writers/syse_put_data.ncl"
load "$SysE/lib/ncl/writers/syse_del_data.ncl"

src = "WRF-NMM-OML50m"
vnm = "tml"
opt = True
res = syse_del_mon_clim(src,vnm,opt)
