load "$SysE/lib/ncl/ccsm/csm_write_helper.ncl"
external BinaryWriter "$SysE/lib/ncl/writers/fortran/shared/binary_write_helper.so"

begin

  ccsm_dir="/fs4/saji/APCC/210.98.49.14/apccdata03/drsaji/6-hour/CCSM.T85.1987/ENS3/"
  ccsm_history="CCSM.T85.1987_3.cam2.h1.1987-12-05-21600.nc"

  ccsm_history=ccsm_dir+"/"+ccsm_history

  fcsm = fopen_read(ccsm_history)

  p_new = (/200100,100000,97500,95000,92500,90000,85000,80000 \
       ,75000,70000,65000,60000,55000,50000,45000,40000,35000 \
       ,30000,25000,20000,15000,10000,7000,5000,3000,2000,1000/)*1.0

  ; Read in data needed for input to WRF
  ;-------------------

  ; 3D Vars ----------

  t  = fcsm->T
  rh = fcsm->RELHUM
  u  = fcsm->U
  v  = fcsm->V
  geop  = fcsm->Z3

  ; 2D vars --------
  
  ps = fcsm->PS
  psl = fcsm->PSL
  ;land_frac = fcsm->LANDFRAC
  ; don't have land_frac and soil moist/temp
  ts        = fcsm->TS
  t2m    = fcsm->TREFHT

  ; Pressure variables

  p0   = fcsm->P0
  hyam = fcsm->hyam
  hybm = fcsm->hybm  

  nzWRF = dimsizes(p_new)
  ndims  = dimsizes(t)
  nt     = ndims(0)
  nz     = ndims(1)
  ny     = ndims(2)
  nx     = ndims(3)


  ; Extrapolate 3 field to surface for unavailable fields
  u10  = fcsm->UBOT  ;u(nz-1,:,:)
  v10  = fcsm->VBOT ; v(nz-1,:,:)
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
  ; we input landmask later on

  ; Calculate 3d pressure field from sigma co-ordinates
  ; ------------------
  p = pres_hybrid_ccm(ps,p0,hyam,hybm) 

  log_p = log10(p)
  log_p_new = log10(p_new)

  UU=hyb2pres(u,nt,nzWRF,nx,ny,nz,ps,p_new,log_p_new,log_p)
  VV=hyb2pres(v,nt,nzWRF,nx,ny,nz,ps,p_new,log_p_new,log_p)
  TT=hyb2pres(t,nt,nzWRF,nx,ny,nz,ps,p_new,log_p_new,log_p)
  RH=hyb2pres(rh,nt,nzWRF,nx,ny,nz,ps,p_new,log_p_new,log_p)
  GHT=hyb2pres(geop,nt,nzWRF,nx,ny,nz,ps,p_new,log_p_new,log_p)

  lat=UU&lat
  lon=UU&lon
  time=UU&time
  
  
  funit=10
  iflag=True
  do itim = 0,nt-1
    file_tim=time(itim)
    hdat=construct_date(file_tim)
    hdate=(/hdat/)
    fname=hdat@fname
    BinaryWriter::open_file_littleendian(funit,fname)
    write_3d_field(funit,hdate,UU(itim,:,:,:),lat,lon,ny,nx,p_new,nzWRF)
    write_3d_field(funit,hdate,VV(itim,:,:,:),lat,lon,ny,nx,p_new,nzWRF)
    write_3d_field(funit,hdate,TT(itim,:,:,:),lat,lon,ny,nx,p_new,nzWRF)
    write_3d_field(funit,hdate,RH(itim,:,:,:),lat,lon,ny,nx,p_new,nzWRF)
    write_3d_field(funit,hdate,GHT(itim,:,:,:),lat,lon,ny,nx,p_new,nzWRF)

    write_2d_field(funit,hdate,psl(itim,:,:),lat,lon,ny,nx,iflag)
    iflag=False
    write_2d_field(funit,hdate,ps(itim,:,:),lat,lon,ny,nx,iflag)
    write_2d_field(funit,hdate,ts(itim,:,:),lat,lon,ny,nx,iflag)
    write_2d_field(funit,hdate,t2m(itim,:,:),lat,lon,ny,nx,iflag)
    write_2d_field(funit,hdate,rh2m(itim,:,:),lat,lon,ny,nx,iflag)
    write_2d_field(funit,hdate,u10(itim,:,:),lat,lon,ny,nx,iflag)
    write_2d_field(funit,hdate,v10(itim,:,:),lat,lon,ny,nx,iflag)

    BinaryWriter::close_file(funit)
  end do
end
