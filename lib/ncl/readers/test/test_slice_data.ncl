load "$SysE/lib/ncl/helper_libs.ncl"
load "$SysE/lib/ncl/readers/SysE_DB_get.ncl"

sopt = True
sopt@DataRoot = getenv("SysE_DB")
sopt@DataSource = "NOAA"
sopt@DataSource = "NCEPR1"
sopt@DataFreq = "Monthly"
;sopt@DataFreq = "Daily"
sopt@DataType = "Climatology"
sopt@Statistic = "stddev"
sopt@Lat = (/-50,40/)
sopt@vname = "hgt"
;sopt@vname = "olr"
sopt@Time = (/"01Aug1999","01Sep1999"/)
sopt@Lev = (/1000/)
;sopt@LocalFile = "olr.nc"
sopt@months=(/8,10/)
;sopt@months=(/"Aug","Oct"/)
sopt@ddmmm=(/"15Aug","16Aug"/)
var = slice_data(sopt)
info(var)
exit
ntim = dimsizes(var&time)

var@map=True
var@shaded=True
DebugPlot(var(0,:,:))
DebugPlot(var(ntim-1,:,:))

