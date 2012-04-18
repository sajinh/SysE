load "$SysE/lib/ncl/helper_libs.ncl"
load "$SysE/lib/ncl/ccsm/ccsm2wrf.ncl"

begin
  ccsm_dir="/home/saji/home2/ResearchProjects/2011/SeasDownScl"
  ccsm_history="CCSM.T85.1983_1.cam2.h1.1984-05-22-64800.nc"
  ccsm_history=ccsm_dir+"/"+ccsm_history
  fcsm=fopen_read(ccsm_history)
  land_frac="not available"
  p_wrf=wrf_pressure_levels
  debug=False
  ierr=cam2wrf(fcsm,p_wrf,land_frac,debug)
end
