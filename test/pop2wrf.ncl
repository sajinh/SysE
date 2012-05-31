load "$SysE/lib/ncl/helper_libs.ncl"
load "$SysE/lib/ncl/ccsm/ccsm2wrf.ncl"

begin
  ccsm_dir="/fs4/saji/APCC"
  ccsm_history="CCSM.T85.1987_3.cam2.h1.1987-11-05-21600.nc"
  ccsm_history=ccsm_dir+"/"+ccsm_history
  fcsm=fopen_read(ccsm_history)
  debug=False
  ierr=pop2wrf(fcsm,debug)
end
