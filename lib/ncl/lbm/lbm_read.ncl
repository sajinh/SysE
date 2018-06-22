external LBM_GT_READER "$SysE/lib/ncl/lbm/fortran/shared/gt.so"
external LBM_P2S "$SysE/lib/ncl/lbm/fortran/shared/p2s.so"

function lbm_get_data(fun,nvals)
begin
  val = new(nvals, "float")
  ; read data using fortran subroutine
  ; header is discarded
  LBM_GT_READER::read_head(fun)
  LBM_GT_READER::read_arr(fun,val,nvals)
  return(val)
end

function lbm_open_file(fin,fnm)
begin
  fhn = fin
  LBM_GT_READER::open_file(fin,fnm)
  return(fhn)
end

function lbm_close_file(fin)
begin
  LBM_GT_READER::close_file(fin)
  return(True)
end

function lbm_get_var(fnm,ntim,nlev,tres)
local nltln, nlat, nlon, var, val, ans, itim, fu1
begin
  nltln = gauss_xyres(tres)
  nlat  = nltln(0)
  nlon  = nltln(1)
  var   = new((/ntim,nlev,nlat,nlon/),"float")
  add_dimensions(var,(/"time","lev","lat","lon"/))
  lat = latGau(nlat,"lat", "latitude","degrees_north")
  lon = lonGlobeF(nlon, "lon", "longitude", "degrees_east")
  var&lat = lat(::-1)
  var&lon = lon

  ; open the file using a fortran subroutine
  fu1 = lbm_open_file(20,fnm)

  ; read u
  do itim = 0,ntim-1
    val = lbm_get_data(fu1,nlev*nlat*nlon)
    var(itim,:,:,:)   = onedtond(val, (/nlev,nlat,nlon/))
  end do
  ans = lbm_close_file(fu1)
  return(var)
end
