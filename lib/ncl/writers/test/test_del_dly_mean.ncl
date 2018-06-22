load "$SysE/lib/ncl/helper_libs.ncl"
load "$SysE/lib/ncl/writers/syse_put_data.ncl"
load "$SysE/lib/ncl/writers/syse_del_data.ncl"

src = "WRF-NMM-OML50M"
vnm = "tml"
yrs = (/1999,2005/)
opt = True
res = syse_del_dly_mean(src,vnm,yrs,opt)
