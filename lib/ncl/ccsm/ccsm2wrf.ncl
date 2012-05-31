load "$SysE/lib/ncl/ccsm/csm_write_helper.ncl"
external BinaryWriter "$SysE/lib/ncl/writers/fortran/shared/binary_write_helper.so"

function wrf_pressure_levels()
begin
  return((/200100,100000,97500,95000,92500,90000,85000,80000 \
       ,75000,70000,65000,60000,55000,50000,45000,40000,35000 \
       ,30000,25000,20000,15000,10000,7000,5000,3000,2000,1000/)*1.0)
end

  
function cam2intermediate_file(UU, VV, TT, RH, GHT, \
                    psl, ps, ts, t2m, rh2m, u10, v10, \
                    time, p_wrf, lat, lon,            \
                      nt, nzWRF, ny,  nx,             \
                       funit,debug)
                   
begin
  iflag=True
  fprefix="FILE"
  pp("Writing intermediate files")
  do itim = 0,nt-1
    file_tim=time(itim)
    hdat=construct_date_fnam(file_tim, fprefix)
    hdate=(/hdat/)
    fname=hdat@fname
    pp("Writing out "+fname)
    BinaryWriter::open_file_littleendian(funit,fname)
    write_3d_field(funit,hdate,UU(itim,:,:,:),lat,lon,ny,nx,p_wrf,nzWRF,debug)
    write_3d_field(funit,hdate,VV(itim,:,:,:),lat,lon,ny,nx,p_wrf,nzWRF,debug)
    write_3d_field(funit,hdate,TT(itim,:,:,:),lat,lon,ny,nx,p_wrf,nzWRF,debug)
    write_3d_field(funit,hdate,RH(itim,:,:,:),lat,lon,ny,nx,p_wrf,nzWRF,debug)
    write_3d_field(funit,hdate,GHT(itim,:,:,:),lat,lon,ny,nx,p_wrf,nzWRF,debug)

    write_2d_field(funit,hdate,psl(itim,:,:),lat,lon,ny,nx,iflag,debug)
    iflag=False
    write_2d_field(funit,hdate,ps(itim,:,:),lat,lon,ny,nx,iflag,debug)
    write_2d_field(funit,hdate,ts(itim,:,:),lat,lon,ny,nx,iflag,debug)
    write_2d_field(funit,hdate,t2m(itim,:,:),lat,lon,ny,nx,iflag,debug)
    write_2d_field(funit,hdate,rh2m(itim,:,:),lat,lon,ny,nx,iflag,debug)
    write_2d_field(funit,hdate,u10(itim,:,:),lat,lon,ny,nx,iflag,debug)
    write_2d_field(funit,hdate,v10(itim,:,:),lat,lon,ny,nx,iflag,debug)

    BinaryWriter::close_file(funit)
  end do
  ierr=0
  return(ierr)
end

function cam2wrf(fcsm,p_wrf,land_frac,debug)
begin
  ierr=0

  pp("Reading history file data")
  ; Read 3D Vars 
  t     = fcsm->T
  rh    = fcsm->RELHUM
  u     = fcsm->U
  v     = fcsm->V
  geop  = fcsm->Z3
  pp("Read 3D vars")

  ; 2D vars --------
  
  ps    = fcsm->PS
  psl   = fcsm->PSL
  ts    = fcsm->TS
  t2m   = fcsm->TREFHT
  u10   = fcsm->UBOT
  v10   = fcsm->VBOT
  pp("Read 2D vars")

  ; Pressure variables
  p0    = fcsm->P0
  hyam  = fcsm->hyam
  hybm  = fcsm->hybm  

  nzWRF = dimsizes(p_wrf)
  ndims = dimsizes(t)
  nt    = ndims(0)
  nz    = ndims(1)
  ny    = ndims(2)
  nx    = ndims(3)

  ; We need to figure out what to do with
  ; soil moisture and temperatures

  ; Extrapolate 3 field to surface for unavailable fields
  rh2m = rh(:,nz-1,:,:)
  
  t@name="TT"
  u@name="UU"
  v@name="VV"
  rh@name="RH"
  geop@name="GHT"

  ; -- 2D names
  ps@name="PSFC"
  psl@name="PMSL"
  ts@name="SKINTEMP"
  t2m@name="TT"
  rh2m@name="RH"
  u10@name="UU"
  v10@name="VV"

  ; Calculate 3d pressure field from sigma co-ordinates
  ; ------------------
  pp("Calculate 3D pressure")
  p = pres_hybrid_ccm(ps,p0,hyam,hybm) 
  log_p = log10(p)
  log_p_wrf = log10(p_wrf)

  pp("Convert from hybrid to pressure co-ordinates")
  UU=hyb2pres(u,nt,nzWRF,nx,ny,nz,ps,p_wrf,log_p_wrf,log_p)
  VV=hyb2pres(v,nt,nzWRF,nx,ny,nz,ps,p_wrf,log_p_wrf,log_p)
  TT=hyb2pres(t,nt,nzWRF,nx,ny,nz,ps,p_wrf,log_p_wrf,log_p)
  RH=hyb2pres(rh,nt,nzWRF,nx,ny,nz,ps,p_wrf,log_p_wrf,log_p)
  GHT=hyb2pres(geop,nt,nzWRF,nx,ny,nz,ps,p_wrf,log_p_wrf,log_p)

  lat=UU&lat
  lon=UU&lon
  time=UU&time
  
  funit=10
  ierr= cam2intermediate_file(UU, VV, TT, RH, GHT, \
                    psl, ps, ts, t2m, rh2m, u10, v10, \
                    time, p_wrf, lat, lon,            \
                      nt, nzWRF, ny,  nx,             \
                      funit,debug)
  return(ierr)
end

function pop2intermediate_file(sst, \
                    time,  lat, lon,            \
                      nt,  ny,  nx,             \
                       funit,debug)
begin
  iflag=False
  fprefix="SST"
  pp("Writing intermediate files")
  do itim = 0,nt-1
    file_tim=time(itim)
    hdat=construct_date_fnam(file_tim, fprefix)
    hdate=(/hdat/)
    fname=hdat@fname
    pp("Writing out "+fname)
    BinaryWriter::open_file_littleendian(funit,fname)
    write_2d_field(funit,hdate,sst(itim,:,:),lat,lon,ny,nx,iflag,debug)
    BinaryWriter::close_file(funit)
  end do
  ierr=0
  return(ierr)
end 

function pop2wrf(fcsm,debug)
begin
  ierr=0
  pp("Reading history file data")
  sst    = fcsm->SST
  pp("Read 2D vars")
  ndims = dimsizes(sst)
  nt    = ndims(0)
  ny    = ndims(1)
  nx    = ndims(2)
  sst@name="SST"
  lat=sst&lat
  lon=sst&lon
  time=sst&time

  fill_value = -999.99
  ; Interpolate SST
  sst = where( (sst.le.0.0), fill_value , sst)
  sst@missing_value = fill_value
  sst@_FillValue    = fill_value

;-----------------------------------------------------------------
; Set the poisson_grid_fill variables
; Global grid: Fill in over land             
;-----------------------------------------------------------------
  nscan = 1500             ; usually *much* fewer
  eps   = 0.001            ; variable depended
  gtype = True             ; Cyclic in longitude [global]
  guess = 1                ; use zonal means
  relc  = 0.6              ; standard relaxation coef
  opt   = 0
 
  if (debug)
    sst@shaded = True
    sst@map = True
    pp("Before poisson fill")
    DebugPlot(sst(0,:,:))
  end if

  pp("Start poison grid fill")
  poisson_grid_fill( sst, gtype, guess, nscan, eps, relc, opt)

  if (debug)
    pp("After Poisson fill")
    DebugPlot(sst(0,:,:))
  end if
  funit=10
  ierr= pop2intermediate_file(sst, \
                    time,  lat, lon,            \
                      nt,  ny,  nx,             \
                      funit,debug)
  return(ierr)
end
