load "$SysE/lib/ncl/helper_libs.ncl"
load "$SysE/lib/ncl/readers/SysE_DB_get.ncl"

sopt = True
sopt@DataRoot = getenv("SysE_DB")
sopt@DataSource = "NOAA"
sopt@DataFreq = "Monthly"
sopt@DataType = "Mean"
sopt@Lat = (/-50,40/)
sopt@vname = "olr"
sopt@Time = (/"01Jan2006","01Dec2006"/)
sopt@LocalFile = "olr.nc"
var = slice_data_cached(sopt)

var@map=True
var@shaded=True
DebugPlot(var(0,:,:))

