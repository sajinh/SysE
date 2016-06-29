; subroutines to add data to the CMS Database
; use custom functions to calculate climatology
; these will calculate climatology and write
; appropriate information and also calculate
; std dev or  other appropriate measures
load "$SysE/lib/ncl/writers/writem.ncl"
load "$SysE/lib/ncl/data_analysis_helpers.ncl"

function pooled_variance(v1,v2,av1,av2,nn,nyr)
local n, n1, n2, ix, i1, d12, naive, form1
begin
  n  = dimsizes(nn)
  n1 = nyr*sum(nn(:n-2))
  n2 = nyr*nn(n-1)
  ix = ind(.not.(ismissing(ndtooned(av1))))
  i1 = ix(0)
  nv1 = ndtooned(v1)
  nv2 = ndtooned(v2)
  nav1 = ndtooned(av1)
  nav2 = ndtooned(av2)
  print("Finding pooled variance for two samples")
  print("Sample sizes are : "+n1+" and "+n2)
  print("Sample variances are : "+nv1(i1)+" and "+nv2(i1))
  print("Sample means are : "+nav1(i1)+" and "+nav2(i1))
  d12 = (av2-av1)*(av2-av1)
  naive = ((n1-1)*v1 + (n2-1)*v2)/(n1+n2-2)
  ; need to check if form1 is suitable for this purpose
  form1 = (n1*n1*v1)+(n2*n2*v2)-(n2*v1)-(n2*v2)-(n1*v1)-(n1*v2)
  form1 = form1 + (n1*n2*v1)+(n1*n2*v2)+(n1*n2*d12)
  form1 = form1/( (n1+n2-1)*(n1+n2))
  nform1 = ndtooned(form1)
  nnaive = ndtooned(naive)
  print("Naive pooled variance : "+nnaive(i1))
  print("Better pooled variance : "+nform1(i1))
  return(form1)
end

; + - + 
;procedure remove_unnecessary_attribute_of(var,att)
;begin
; if isatt(var,att)
;   delete(var@$att$)
; end if
;end

procedure check_rank_of(var)
local var
begin
  ; Check if we can process the variable using this module
  nrank=dimsizes(dimsizes(var))
  if nrank.lt.3 .or. nrank.gt.4
    print("This module cannot process your order : please check manual")
    print("The rank of the variable is : "+nrank)
    printVarSummary(var)
    print("eXit")
    exit
  end if
  var@nrank=nrank
end

function create_outdir(darray)
local outdir
begin
  darray@join="/"
return(array_to_string(darray))
end

procedure remove_xtra_slashes_of(aString)
local aString
begin
  tmp=aString
  aString=systemfunc("echo "+tmp+" | tr -s '//' '/'")
end

function name_of_outfil(outdir,vname)
begin
  outfil=outdir+"/"+vname+".nc"
return(outfil)
end
; ++++
function create_file_if_not_exists(outdir,vname)
local outdir,vname,outfil
begin
  outfil = name_of_outfil(outdir,vname)
  print("Checking existence of :"+outfil)
  if isfilepresent(outfil)
    print("Output file exists : eXit")
    TerminateProgram
  end if
return(outfil)
end
; ++++
procedure check_time(var)
begin
  dims=getvardims(var)
  ndims=dimsizes(dims)
  do i = 0,ndims-1
    if ismissing(dims(i))
      continue
    end if
    if dims(i).eq."time"
      var@_tindx=i
      return(i)
    end if
  end do
terminate_program("sorry, your data has no time dimension")
end
; ++++
procedure check_lev(var)
begin
  dims=getvardims(var)
  ndims=dimsizes(dims)
  do i = 0,ndims-1
    if ismissing(dims(i))
      continue
    end if
    if dims(i).eq."level"
      var@_lindx=i
      return(i)
    end if
  end do
terminate_program("sorry, your data has no level dimension")
end
; ++++
procedure check_time_object_of(var)
local time
begin
  check_time(var)
  time=var&time
  if .not. isatt(time,"units")
    terminate_program("time object does not have time units")
  end if
  if .not. isatt(time,"calendar")
    terminate_program("please specify a calendar type for time, e.g: standard")
  end if
end
; ++++
function make_standard_time_axis_for(var)
local time, ntim, D1, D2, y1, y2, m1, m2, d1, d2, tim1, tim2
begin
  time=var&time
  ntim=dimsizes(time)
  D1=get_yr_mo_dy(time(0))
  D2=get_yr_mo_dy(time(ntim-1))
;  tim2=to_std_time(time)
; add code to write time depending on data frequency
; all monthly time to written on mid-month
  tunits="days since 1900-01-01"

  y1=D1@year
  y2=D2@year
  m1=D1@month
  m2=D2@month
  d1=D1@day
  d2=D2@day

  if var@DataFreq.eq."Monthly"
    tim2=make_monthly_time(y1,m1,15,y2,m2,15,tunits,ntim)
  end if

  if var@DataFreq.eq."Daily"
    tim2=make_daily_time(y1,m1,d1,y2,m2,d2,tunits,ntim)
  end if


  delete(var&time)
  tindx=var@_tindx
  var!tindx="time"
  var&time=tim2
  delete(var@_tindx)
  print(D1)
  if isatt(var,"time1")
    delete(var@time1)
    delete(var@time2)
  end if
  var@time1=D1
  var@time2=D2
  return(var)
end
; + +
procedure update_or_new(var,vname)
begin
  vname@_update=False
  if isatt(var,"update")
    vname@_update=var@update
  end if
end
; + +
procedure var_update(outdir,var_name,vname,var1)
begin
; 1. open the existing file (outdir/vname.nc)
; 2. find last time of var1 in existing file
; 3. if current time is consistent with last time, append new data
  ;printVarSummary(var1)
  remove_unnecessary_attribute_of(vname,"_update")
  outfil=name_of_outfil(outdir,var_name)
  fin1  = addfile(outfil,"r")
  tim   = fin1->time
  ntim0 = dimsizes(tim)
  tim1  = tim(ntim0-1)
  if var1@DataFreq .eq. "Monthly"
    next_time = next_month_of(tim1)
  end if
  if var1@DataFreq .eq. "Daily"
    next_time = next_day_of(tim1)
  end if
  delete(tim)
  delete(tim1)
  tim   = var1&time
  ntim1 = dimsizes(tim)
  tim1  = tim(0)
  delete(tim)
  if (tim1.eq.next_time) then
    print(tim1+"::"+next_time+" : End times match")
    print("Cat the updated data with the original data")
    var0 = fin1->$vname$
    nlat = dimsizes(var0&lat)
    nlon = dimsizes(var0&lon)
    var2 = new( (/ntim0+ntim1,nlat,nlon/), typeof(var0) )
    var2!0 = "time"
    newtime           = new( ntim0+ntim1, typeof(var0&time) )
    newtime(:ntim0-1)  = var0&time
    newtime(ntim0:)    = var1&time
    var2&time         = newtime
    var2(:ntim0-1,:,:) = var0
    var2(ntim0:,:,:)   = var1
    print("Deleting old file")
    system("rm "+outfil)
    print("Adding new file with updated data")
    fout      = addfile(outfil,"c")
    write_TLL(fout,vname,var2)
  else
    print("What is wrong ?")
    terminate_program(tim1+"::"+next_time+" : End times do not match")
  end if
  delete(tim1)
  delete(next_time)
end
; +++
procedure write_4D_data(var,outdir,tim1,tim2)
begin
  vname     = var@vnam
  levs      = var&level
  nlev     = dimsizes(levs)
  remove_unnecessary_attribute_of(var,"_lindx")
  do ilev   = 0, nlev-1
    var1=var({time|tim1:tim2},level|ilev,lat|:,lon|:)
    var_name  = vname+"_"+levs(ilev)
    update_or_new(var1,vname)   ; check if output file is to be updated
    remove_unnecessary_attribute_of(var1,"update")
    remove_unnecessary_attribute_of(var1,"vnam")
    if vname@_update
      var_update(outdir,var_name,vname,var1)
    else                       ; start a new file
      remove_unnecessary_attribute_of(vname,"_update")
      outfil    = create_file_if_not_exists(outdir,var_name)
      fout      = addfile(outfil,"c")
      write_TLL(fout,vname,var1)
    end if
    delete(var1)
  end do
end

procedure write_3D_data(var,outdir,tim1,tim2)
begin
  var1=var({time|tim1:tim2},lat|:,lon|:)
  vname     = var@vnam
  remove_unnecessary_attribute_of(var1,"_lindx")
  remove_unnecessary_attribute_of(var1,"vnam")
  if isatt(var,"filNam")
    var_name=var@filNam
    remove_unnecessary_attribute_of(var1,"filNam")
  else
    var_name=vname
  end if
  update_or_new(var1,vname)   ; check if output file is to be updated
    remove_unnecessary_attribute_of(var1,"update")
    remove_unnecessary_attribute_of(var1,"vnam")
  if vname@_update
    var_update(outdir,var_name,vname,var1)
    remove_unnecessary_attribute_of(var,"update")
    remove_unnecessary_attribute_of(vname,"_update")
  else                       ; start a new file
    remove_unnecessary_attribute_of(vname,"_update")
 
    outfil    = create_file_if_not_exists(outdir,var_name)
    fout      = addfile(outfil,"c")
    write_TLL(fout,vname,var1)
  end if
end

procedure write_data_for_each_year(var,var_name,yr1,yr2,outdir)
local nrank, nyr, outdir0, tunits, year, i
begin
  nrank     = var@nrank
  nyr       = yr2-yr1+1
  outdir0   = outdir
  tunits    = var&time@units
  do i = 1,nyr
    var@vnam  = var_name
    year=yr1+i-1
    outdir1    = create_outdir((/outdir0,numeral_to_string(year)/))
    mkdir_p(outdir1)
    start_time=ut_inv_calendar(year,1,\
                       1,0,0,0,tunits,0)
    end_time =ut_inv_calendar(year,12,\
                       31,0,0,0,tunits,0)
    remove_unnecessary_attribute_of(var,"nrank")
    remove_unnecessary_attribute_of(var,"time1")
    remove_unnecessary_attribute_of(var,"time2")
    print("Output the standardized data for "+year)
    if nrank.eq.4
      write_4D_data(var,outdir1,start_time,end_time)
    else
      write_3D_data(var,outdir1,start_time,end_time)
    end if
  end do
end

procedure CMS_Write(var,var_name,dataRoot,
           dataSrc,dataFrq,dataTyp)
begin
;  init_write_library()
  check_rank_of(var) 
  check_time_object_of(var)
  if var@nrank.eq.4  
    check_lev(var)
  end if
  dataFrq   = capitalize(dataFrq)
  var@DataFreq = dataFrq
  var=make_standard_time_axis_for(var)

  dataSrc   = str_upper(dataSrc)
  dataTyp   = capitalize(dataTyp)
  outdir    = create_outdir((/dataRoot,dataSrc,dataFrq,dataTyp/))
  remove_xtra_slashes_of(outdir)

  D1        = var@time1
  D2        = var@time2
  y1        = floattointeger(D1(0,0))
  y2        = floattointeger(D2(0,0))
  pp("Writing "+var_name+" to database")
  write_data_for_each_year(var,var_name,y1,y2,outdir)
end

function SysE_FillGaps(var,fill_req)
local ndim, idim
begin

  ndim=dimsizes(fill_req)
  do idim = 0,ndim-1
    dim=fill_req(idim)
    print("Filling data gaps in "+ dim)
    if (dim .eq. "time")
      fillup_along_time(var)
    end if
    if (dim .eq. "lat")
      fillup_along_lat(var)
    end if
    if (dim .eq. "lon")
      fillup_along_lon(var)
    end if
  end do
return(var)
end

function CMS_Anom(var,vclim,y1,y2)
local var1, iyr, tim1, tim2, tindx
begin
  vanom=var
  tunits=var&time@units
  t0=0
  do iyr=y1,y2  
    tim1=ut_inv_calendar(iyr,1,1,0,0,0,tunits,0)
    tim2 =ut_inv_calendar(iyr,12,31,0,0,0,tunits,0)
    var1 = var({tim1:tim2},:,:)

  ; Find day of year for the daily data set
  ; From time variable calculate year, month and day
    time=var1&time
    tarray=ut_calendar(time,0)

    if var@DataFreq.eq."Monthly"
      tindx=floattoint(tarray(:,1))
    end if
    if var@DataFreq.eq."Daily"
      ; Below is a bug discovered 2 Sep 2014
      ;tindx=floattoint(tarray(:,2))
      ; Bug is corrected as follows (new code for tindx)
      yarr=floattoint(tarray(:,0))
      marr=floattoint(tarray(:,1))
      darr=floattoint(tarray(:,2))
      tindx = day_of_year(yarr,marr,darr)
      delete(yarr)
      delete(marr)
      delete(darr)
    end if
    tindx=tindx-1

    time!0="time"
    time&time=time
    vtims=time({tim1:tim2})
    nvtims=dimsizes(vtims)
    ntindx = dimsizes(tindx)
    if ntindx.eq.1
      vanom(t0:t0+nvtims-1,:,:) = var1- (/ vclim(tindx:tindx,:,:) /)
    else
      vanom(t0:t0+nvtims-1,:,:) = var1- (/ vclim(tindx,:,:) /)
    end if
    t0=t0+nvtims

    delete(var1)
    delete(time)
    delete(tarray)
    delete(vtims)
    delete(tindx)
  end do
return(vanom)
end

procedure Make_CMS_Anomaly(opt)
local opt
begin
  allowed_freq=(/"Monthly","Daily"/)
  if .not.any(allowed_freq.eq.opt@DataFreq)
    terminate_program(opt@DataFreq+" anomaly not supported")
  end if

  ;cr=integertochar(10) ; already defined
  if opt@DataFreq.eq."Daily"
    if .not. isatt(opt,"NumHarmonics")
      msg="You need to specify the number of harmonics to smooth the data"
      msg=msg+cr+"        Please use opt@NumHarmonics=(1, 2 or 3)"
      terminate_program(msg)
    end if
  end if

  print("Retrieving requested data for anomaly construction")
  opt@DataType="Mean"
  var=slice_data(opt)
  ;printVarSummary(var)
  print("Retrieving climatology data")
  opt@DataType="Climatology"
  opt@Statistic="mean"
  vclim=slice_data(opt)

  time=var&time
  ntim=dimsizes(time)
  D1=get_yr_mo_dy(time(0))
  D2=get_yr_mo_dy(time(ntim-1))
  y1=D1@year
  y2=D2@year
  m1=D1@month
  m2=D2@month
  d1=D1@day
  d2=D2@day

  dataFrq   = capitalize(opt@DataFreq)
  opt@DataFreq=dataFrq ; for some reason after capitalization, this option
                       ; is downcased
  var@DataFreq=dataFrq
  if dataFrq.eq."Monthly"
    ;vanom=calcMonAnomTLL (var,vclim)
    vanom=CMS_Anom (var,vclim,y1,y2)
  end if
  if dataFrq.eq."Daily"
    ddd      = day_of_year(y1, m1, d1)
    yyyyddd  = y1*1000 + ddd
    ;vclim_sm = smthClmDayTLL(vclim, opt@NumHarmonics) 
    ; smthClmDayTLL does not work with SST or SSH (missing value data)
    ; switch to constructed_anncycle on Sep 2, 2014 NHS
    vclim_sm = constructed_anncycle(vclim, opt@NumHarmonics) 
    ;vanom    = calcDayAnomTLL (var, yyyyddd, vclim_sm)
    vanom=CMS_Anom (var,vclim_sm,y1,y2)
  end if

  dataSrc   = str_upper(opt@DataSource)
  dataTyp   = "Anomaly"
  outdir    = create_outdir((/opt@DataRoot,dataSrc,dataFrq,dataTyp/))
  remove_xtra_slashes_of(outdir)

  delete(var)
  delete(vclim)
  var=vanom
  delete(vanom)
  var_name=opt@vname
  if isatt(opt,"Lev")
   var_fil=var_name+"_"+opt@Lev
   var@filNam=var_fil
  end if
  
  check_rank_of(var) 
  if isatt(opt,"update")
    var@update=opt@update
  end if
  if isatt(opt,"FillGaps")
    var=SysE_FillGaps(var,opt@FillGaps)
  end if
  write_data_for_each_year(var,var_name,y1,y2,outdir)
end

procedure SysE_timeerror(tv,tsiz)
begin
  if tsiz.lt.8 .or. tsiz.gt.9
    print("Error in Time specification")
    print("Time to be specified as ddMONyyyy, e.g. 20Jan2006")
    print("However current time is provided as "+tv)
    print("eXiT")
    exit
  end if
end
procedure SysE_timeparser(tvals,yr1,yr2,mo1,mo2,dy1,dy2)
local tv1, tv2, tsiz, tim1, tim2
begin
  tv1=tvals(0)
  tv2=tvals(1)
  tim1 = stringtochar(tv1)
  tim2 = stringtochar(tv2)
  tsiz =  sizeof(tim1)-1
  SysE_timeerror(tv1,tsiz)
  yr1=(chartostring(tim1(tsiz-4:tsiz-1)))
  mo1=chartostring(tim1(tsiz-7:tsiz-5))
  dy1=(chartostring(tim1(:tsiz-8)))

  tsiz =  sizeof(tim2)-1
  SysE_timeerror(tv2,tsiz)
  yr2=(chartostring(tim2(tsiz-4:tsiz-1)))
  mo2=chartostring(tim2(tsiz-7:tsiz-5))
  dy2=(chartostring(tim2(:tsiz-8)))
end
function SysE_year_chunks(nyr, nslices, yr1)
local year0, year1, nyr_chunk, i
begin
  if nyr .lt. nslices
    terminate_program("opt@NumSlices more than number of years")
  end if
  year0=new(nslices, integer)
  year1=new(nslices, integer)
  nyr_chunk = nyr/nslices
  rem_chunk = nyr%nslices
  if nyr_chunk .lt. 2
    terminate_program("there should be at least 2 years in a chunk")
  end if
  do i = 0,nslices-1
    year0(i) = stringtointeger(yr1)+i*nyr_chunk
  end do
  year1 = year0+nyr_chunk-1
  weights=year1*1.0
  weights=1.0*nyr_chunk/nyr
  year1(nslices-1) = year1(nslices-1)+rem_chunk
  weights(nslices-1) = 1.0*(nyr_chunk+rem_chunk)/nyr
  if sum(weights) .ne. 1
    pp(array_join(weights," : "))
    terminate_program("Error in calculating weights for chunks")
  end if
  year0@end_year=year1
  year0@weights=weights
  return(year0)
end
procedure Make_CMS_Climatology(opt)
local opt0
begin
  opt0 = opt
  allowed_freq=(/"Monthly","Daily"/)

  if .not.any(allowed_freq.eq.opt@DataFreq)
    terminate_program(opt@DataFreq+" climatology not supported")
  end if

  ;cr=integertochar(10)
  if .not. isatt(opt,"ClimPeriod")
    msg="You need to specify the period for climatology calculation"
    msg=msg+cr+"        Please use the opt@ClimPeriod=(/period1,period2/)"
    terminate_program(msg)
  end if

  opt@Time=opt@ClimPeriod
  num_slices=1  ; To reduce RAM requirement for climatological calculations
  if isatt(opt,"NumSlices")
    num_slices = opt@NumSlices 
  end if
  __tvals = opt@Time
  __tv1 = __tvals(0)
  __tv2 = __tvals(1)
  pp(__tv1)
  pp(__tv2)
  __yr1="0"
  __mo1="0"
  __dy1="0"
  __yr2="0"
  __mo2="0"
  __dy2="0"

  SysE_timeparser(__tvals,__yr1,__yr2,__mo1,__mo2,__dy1,__dy2)
  pp(__yr1+"-"+__mo1+"-"+__dy1)
  pp(__yr2+"-"+__mo2+"-"+__dy2)
  __nyr = stringtoint(__yr2)-stringtoint(__yr1)+1

  nchunks=SysE_year_chunks(__nyr, num_slices, __yr1)
  nchunke=nchunks@end_year
  chunk_wgt=nchunks@weights
  pp(array_join(nchunks,"->"))
  pp(array_join(nchunks@end_year,"->"))
  last_day="31Dec"
  do irpt = 0,num_slices-1
    if irpt.eq.num_slices-1
      last_day = __dy2+__mo2
    end if
    clim_period = (/__dy1+__mo1+nchunks(irpt), last_day+nchunke(irpt)/)
    pp("Retrieving requested data for climate construction")
    pp(".............getting subset "+array_join(clim_period,"->"))
    
    delete(opt@Time)
    opt@Time=clim_period
    var=slice_data(opt)
    tunits="days since 1900-01-01"

    if opt@DataFreq.eq."Monthly"
      print("Make Monthly Climatology")
      clim = clmMonTLL(var)
      std  = stdMonTLL(var)
      ntim=12
      if irpt.eq.0
        clim_time=make_monthly_time(1904,1,15,1904,12,15,tunits,ntim)
      end if
    end if

    if opt@DataFreq.eq."Daily" 
      print("Make Daily Climatology")
      time    = var&time
      TIME    = ut_calendar(time, 0)          ; type float 
      delete(time)
      year    = floattointeger( TIME(:,0) )
      month   = floattointeger( TIME(:,1) )
      day     = floattointeger( TIME(:,2) ) 
      ddd     = day_of_year(year, month, day) 
      yyyyddd = year*1000 + ddd
      clim=clmDayTLL(var,yyyyddd) 
      std=stdDayTLL(var,yyyyddd) 
      delete(TIME)
      delete(year)
      delete(month)
      delete(day)
      delete(ddd)
      delete(yyyyddd)
      ntim=366
      if irpt.eq.0
        clim_time=make_daily_time(1904,1,1,1904,12,31,tunits,ntim)
      end if
       
    end if
    if irpt.eq.0
      slc_clim = clim
      slc_std = std
      slc_clim= (/ clim*chunk_wgt(irpt) /)
      ;slc_std= (/ std*chunk_wgt(irpt) /)
      ; we need sample variance for pooled variance calculation
      ; hence it is not weighted
      ; in case of climatology, write unweighted mean to a new variable old_clim
      slc_std= (/ std*std /)
      old_clim = clim
    else
      ;slc_std= (/ slc_std+(std*chunk_wgt(irpt)) /)
      slc_std= (/pooled_variance(slc_std,std*std,old_clim,clim,chunk_wgt(:irpt),__nyr)/)
      slc_clim= (/ slc_clim+(clim*chunk_wgt(irpt)) /)
      old_clim = clim
    end if
    delete(clim)
    delete(std)
    delete(var)
  end do
  clim = slc_clim
  std = (/ sqrt(slc_std)/)
  delete(slc_clim)
  delete(slc_std)
  CPeriod=opt0@ClimPeriod
  CPeriod@join=" "
  clim@ClimPeriod=array_to_string(CPeriod)

  dataSrc   = str_upper(opt0@DataSource)
  dataFrq   = capitalize(opt0@DataFreq)
  dataTyp   = "Climatology"
  outdir    = create_outdir((/opt0@DataRoot,dataSrc,dataFrq,dataTyp/))
  remove_xtra_slashes_of(outdir)
  print(outdir)
  dims=dimsizes(clim)
  ntim=dims(0)
  nlat=dims(1)
  nlon=dims(2)
  nlev=2
  clim2=new( (/ntim,nlev,nlat,nlon/), typeof(clim) )
  clim2(:,0,:,:)=clim
  clim2(:,1,:,:)= (/ std /) ; std dev code for TLL
  delete(clim2&$clim2!0$)
  printVarSummary(clim2)
  clim2!0="time"
  clim2&time=clim_time
  clim2!1="level"
  clim2&level=ispan(1,nlev,1)
  clim2&level@description="climatology"
  if isatt(opt0,"COARDS") ; make level to appear as depth
    clim2&level@long_name="depth"
    clim2&level@units="m"
  end if
  vname=opt0@vname
  var_name=vname
  if isatt(opt0,"Lev")
   var_name=var_name+"_"+opt0@Lev
  end if
  if isatt(opt0,"lev")
   var_name=var_name+"_"+opt0@lev
  end if
  mkdir_p(outdir)
  outfil    = create_file_if_not_exists(outdir,var_name)
  fout      = addfile(outfil,"c")
  remove_unnecessary_attribute_of(clim2,"nrank")
  remove_unnecessary_attribute_of(clim2,"time1")
  remove_unnecessary_attribute_of(clim2,"time2")
  remove_unnecessary_attribute_of(clim2,"vnam")
  remove_unnecessary_attribute_of(clim2,"info")
  remove_unnecessary_attribute_of(clim2,"time_op_ncl")
  remove_unnecessary_attribute_of(clim2,"valid_range")
  remove_unnecessary_attribute_of(clim2,"actual_range")
  remove_unnecessary_attribute_of(clim2,"precision")
  if isatt(opt0,"FillGaps")
    clim2=SysE_FillGaps(clim2,opt0@FillGaps)
  end if
  print("Write Climatology to DataBase")
  write_TLLL(fout,vname,clim2)
end
function make_cms_trend(vname,root,src,yr_range,lev)
local var,opt
begin
  pp("Retrieving requested data for trend construction")
  opt=True
  opt@vname=vname
  opt@DataRoot=root
  opt@DataSource=src
  opt@Time=(/"01Jan"+yr_range(0),"31Dec"+yr_range(1)/)
  opt@DataFreq="Monthly"
  opt@DataType="Anomaly"
  if lev
    opt@Lev=lev
    if dimsizes(lev) .gt.1
      abort("Only one level can be provided at a time")
    end if
  end if
  ;opt@Lat=(/-60,0/)
  ;opt@Lon=(/190,240/)
  ;opt@LatAve=True
  ;opt@LonAve=True
  var=slice_data(opt)
  ;DebugGraph(var)
  time=var&time
  ntim=dimsizes(time)
  nyr=ntim/12
  years=ispan(1,nyr,1)*1.0d0
  nave = 3
  nlat = dimsizes(var&lat)
  nlon = dimsizes(var&lon)
  nstn = nlat*nlon
  vann = new((/nstn,13,nyr/),typeof(var))
  ;1 a 13 element array is used, the
  ; first 12 stores trends for each month/3-mon season
  ; the 13th element stores an annual trend
  vopt=False
  v2d = reduce_to_2D(var(lat|:,lon|:,time|:),vopt)
  v2d = runave(v2d,nave,1)
  is = 0
  do iyr=0,nyr-1
    ie = is+11
    vann(:,12,iyr) = dim_avg(v2d(:,is:ie))
    do imo = 0,11
      vann(:,imo,iyr) = v2d(:,(is+imo))
    end do
    is = is+12
  end do

  trend2d=regCoef(years,vann)
  trend2d=trend2d*10 ; time is in units of days - this changes
                  ; trend from vunits/day to vunits/year
  trend=onedtond(trend2d,(/nlat,nlon,13/))
  add_dimensions(trend,(/"lat","lon","season"/))
  trend&lat=var&lat
  trend&lon=var&lon
  trend&season=ispan(1,13,1)
  trend@long_name="trend based on linear regression"
  trend@units=var@units+"/decade"
  trend@yr_range=yr_range
  
  delete(var)
  delete(opt)
  delete(time)
  delete(vann)
  delete(v2d)
  return(trend(season|:,lat|:,lon|:))
end
function write_cms_trend(vname,root,src,var)
begin
  outdir    = create_outdir((/root,src,"Monthly","Climatology"/))
  remove_xtra_slashes_of(outdir)
  print(outdir)
  dims=dimsizes(var)
  ntim=dims(0)
  nlat=dims(1)
  nlon=dims(2)
  nlev=1
  var2=new( (/ntim,nlev,nlat,nlon/), typeof(var) )
  var2(:,0,:,:)=var
  season=var2&season
  delete(var2&$var2!0$)
  printVarSummary(var2)
  var2!0="time"
  var2&time=season
  var2&time@units="months since 1900-01-01"
  var2&time@desc="twelve 3-month season plus annual trend"
  var2!1="level"
  var2&level=1
  var2&level@description="dummy co-ordinate"
  var2&level@long_name="depth"
  var2&level@units="m"

  mkdir_p(outdir)
  tvnam = "t_"+vname
  outfil    = create_file_if_not_exists(outdir,tvnam)
  fout      = addfile(outfil,"c")
  print("Write Trend to DataBase")
  write_TLLL(fout,tvnam,var2)
  return(True)
end
