external HYB2PRES "$SysE/lib/ncl/ccsm/fortran/shared/hybrid2press.so"
external WRF_INT_FILE "$SysE/lib/ncl/ccsm/fortran/shared/write_intermediate_file.so"

function hyb2pres(var,nt,nz_WRF,nx,ny,nz,ps,p_new,log_p_new,log_p)
begin
  outvar = new( (/nt,nz_WRF,ny,nx/), typeof(var) )
  add_dimensions(outvar,(/"time","lev","lat","lon"/))
  lon=var&lon
  lon!0="lon"
  lon&lon=lon
  lat=var&lat
  lat!0="lat"
  lat@lat=lat
  outvar&time = var&time
  outvar&lat = lat
  outvar&lon = lon
  outvar&lev = p_new
  outvar@units = var@units
  outvar@name=var@name
  outvar@long_name=var@long_name
  tmp= new( (/nz_WRF,ny,nx/), typeof(var))
 do itim=0,nt-1
   HYB2PRES::interpolate_to_pressure_levels(nz_WRF, \
    nx,ny,nz,\
    ps(itim,:,:), p_new, log_p_new, log_p(itim,:,:,:), \
    var(itim,:,:,:), tmp)
    outvar(itim,:,:,:) = (/ tmp/)
 end do
 if var@name .eq. "RH10"
   outvar = where(outvar.lt.0, 0.0, outvar)
 end if
 return(outvar) 
end

function construct_date_fnam(spec_time,fprefix)
  local hdat
begin
  tdate=ut_calendar(spec_time,-5)
  tyr=sprinti("%0.4i", tdate(:,0))
  tmo=sprinti("%0.2i", tdate(:,1))
  tdy=sprinti("%0.2i", tdate(:,2))
  thr=sprinti("%0.2i", tdate(:,3))
  tmn=sprinti("%0.2i", tdate(:,4))
  tsc=sprinti("%0.2i", tdate(:,5))
  hdat=(tyr+"-"+tmo+"-"+tdy+"_"+thr+":"+tmn+":"+tsc)
  fdat=(fprefix+":"+tyr+"-"+tmo+"-"+tdy+"_"+thr)
  hdat@fname=fdat
  return(hdat)
end


procedure write_3d_field(funit,hdate,volume,lat,lon,ny,nx,p_new,nzWRF,debug)
begin
  xfcst=0.0
  map_src=   "CCSM3"
  field=      volume@name
  units=      volume@units
  desc=       volume@long_name
  iproj=4
  IFV=5
  startloc="SWCORNER"
  startlat=doubletofloat(lat(0))
  startlon=doubletofloat(lon(1))
  nlats=ny/2
  dlon=doubletofloat(lon(2)-lon(1))
  erad=6367470.0*0.001

  ; dummy vars
  dlat=doubletofloat(lat(2)-lat(1))
  dx=1.0
  dy=1.0
  xlonc=1.0
  truelat1=doubletofloat(lat(0))
  truelat2=doubletofloat(lat(0))

  do k = 1,nzWRF-1
    xlvl=       p_new(k)

   WRF_INT_FILE::write_intermediate_file(funit,hdate, startloc,\   ; 3
        field, units,  desc, map_src, xlvl, nx, ny,\      ; 10
        iproj, startlat, startlon, dlat, dlon,\           ; 15
        dx, dy, xlonc, truelat1, truelat2, nlats, volume(k,:,:),debug)
  end do
  return
end

procedure write_2d_field(funit,hdate,slab,lat,lon,ny,nx,iflag,debug)
begin
  xfcst=0.0
  map_src=   "CCSM3"
  field=      slab@name
  units=      slab@units
  desc=       slab@long_name
  iproj=4
  IFV=5
  startloc="SWCORNER"
  startlat=doubletofloat(lat(0))
  startlon=doubletofloat(lon(1))
  nlats=ny/2
  dlon=doubletofloat(lon(2)-lon(1))
  erad=6367470.0*0.001

  ; dummy vars
  dlat=doubletofloat(lat(2)-lat(1))
  dx=1.0
  dy=1.0
  xlonc=1.0
  truelat1=doubletofloat(lat(0))
  truelat2=doubletofloat(lat(0))

  xlvl   = 200100.0
  if iflag
    xlvl = 201300.0
  end if

  WRF_INT_FILE::write_intermediate_file(funit,hdate, startloc,\
        field, units,  desc, map_src, xlvl, nx, ny,\
        iproj, startlat, startlon, dlat, dlon,\
        dx, dy, xlonc, truelat1, truelat2, nlats, slab,debug)
  return
end
