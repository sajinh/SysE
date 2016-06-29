function SysE_DB_tunits()
begin
  return("days since 1900-01-01")
end

function findCurrentTime()
begin
  cyr=stringtoint(systemfunc("date +%Y"))
  cmo=stringtoint(systemfunc("date +%m"))
  cdy=stringtoint(systemfunc("date +%d"))
  return( (/cyr,cmo,cdy/) )
end

function months_to_cut(dFreq,dmonths,yr)
local  d1, d2, m1, m2, tims, ntim, im, nmon
begin
  m1 = toint(dmonths(0))
  m2 = toint(dmonths(1))
  nmon = m2-m1+1
  tims = new(nmon,double)
  if dFreq .eq. "Monthly"
    d1 = ut_inv_calendar(yr,m1,15,0,0,0,SysE_DB_tunits,0)
    d2 = ut_inv_calendar(yr,m2,15,0,0,0,SysE_DB_tunits,0)
    ret = (/d1,d2/)
    ntim = (m2-m1)+1
    ret@ntim = ntim
    tims(0) = d1
    tims(nmon-1) = d2
    do im=1,nmon-2
      tims(im) = ut_inv_calendar(yr,(m1+im),15,0,0,0,SysE_DB_tunits,0) 
    end do
    ret@tims = tims
    return(ret)
  end if
  if dFreq .eq. "Daily"
    d1 = ut_inv_calendar(yr,m1,1,0,0,0,SysE_DB_tunits,0)
    d2 = ut_inv_calendar(yr,m2,days_in_month(yr,m2),0,0,0,SysE_DB_tunits,0)
pp(d2+" "+yr)
    ret = (/d1,d2/)
    ntim = toint((d2-d1)+1)
    ret@ntim = ntim
    ret@tims = fspan(d1,d2,ntim)
    return(ret)
  end if
  return(False)
end

function ddmmm_to_cut(dFreq,ddmmm,yr)
local ntim, t1, t2, m1, m2, d1, d2, dt1, dt2
begin
  if dFreq .eq. "Monthly"
    abort("opt@ddmmm is not supported for monthly resolution; USE opt@months")
  end if
  if dFreq .eq. "Daily"
    t1 = ddmmm(0)
    t2 = ddmmm(1)
    m1 = integer_value_of_month(str_get_cols(t1,2,4))
    m2 = integer_value_of_month(str_get_cols(t2,2,4))
    d1 = toint(str_get_cols(t1,0,1))
    d2 = toint(str_get_cols(t2,0,1))
    dt1 = ut_inv_calendar(yr,m1,d1,0,0,0,SysE_DB_tunits,0)
    dt2 = ut_inv_calendar(yr,m2,d2,0,0,0,SysE_DB_tunits,0)
    ; Thanks to cd_inv_calendar even "2010-01-40" makes sense
    ret = (/dt1,dt2/)
    ntim = toint(dt2-dt1+1)
    ret@ntim = ntim
    ret@tims=fspan(dt1,dt2,ntim)
    return(ret)
  end if
  return(False)
end

function cut_data(DataDir,vname,yrs,tim,lat,lon)
local ntim,nlat,nlon,lat1,lat2,tim1,tim2,lon1,lon2,cut_tim
begin
  nlat=dimsizes(lat)
  nlon=dimsizes(lon)
  nyrs=dimsizes(yrs)
  _datFreq = DataDir@dFreq
  ntim=0
  cut_tim = new((/2,nyrs/), "double")
  cut_ntim = new(nyrs,"integer")
  tim_axs = NewList("fifo")
  do iyr = 0,nyrs-1
    if (iyr.eq.0)
      mon1=tim@mo1
      day1=tim@dy1
    else
      mon1=1
      day1=1
    end if
    if (iyr.eq.nyrs-1)
      mon2=tim@mo2
      day2=tim@dy2
    else
      mon2=12
      day2=31
    end if
    if isatt(tim,"months")
      tmp_cut_tim = months_to_cut(_datFreq,tim@months,yrs(iyr))
    else
      tmp_cut_tim = months_to_cut(_datFreq,(/mon1,mon2/),yrs(iyr))
    end if
    if (_datFreq .eq. "Daily")
      if .not. isatt(tim,"months")
        if isatt(tim,"ddmmm")
          tmp_cut_tim = ddmmm_to_cut(_datFreq,tim@ddmmm,yrs(iyr))
        else
          t1=sprinti("%0.2i",day1)+""+integer_to_month(mon1)
          t2=sprinti("%0.2i",day2)+""+integer_to_month(mon2)
          tmp_cut_tim = ddmmm_to_cut(_datFreq,(/t1,t2/),yrs(iyr))
        end if
      end if
    end if
    cut_tim(:,iyr) = tmp_cut_tim
    ntim=ntim+toint(tmp_cut_tim@ntim)
    cut_ntim(iyr) = tmp_cut_tim@ntim
    ListPush(tim_axs, tmp_cut_tim@tims)
    delete(tmp_cut_tim)
  end do
  var2=new((/ntim,nlat,nlon/),"float")
  v2tm=new(ntim,"double")
  ibeg=0
  do i=0,nyrs-1
    iend=ibeg+cut_ntim(i)-1
    v2tm(ibeg:iend) = ListPop(tim_axs)
    ibeg=iend+1
  end do
  add_dimensions(var2,(/"time","lat","lon"/))
  var2&lat=lat
  var2&lon=lon
  var2&time=ndtooned(v2tm)
  var2&time@units=SysE_DB_tunits()
  ntim_per_yr = ntim/nyrs
  lat1=lat(0)
  lon1=lon(0)

  lat2=lat(nlat-1)
  lon2=lon(nlon-1)

  t0=0
  do iyr=0,nyrs-1
    DataDir_yr=DataDir+yrs(iyr)+"/"+vname+".nc"
    fin=addfile(DataDir_yr,"r")
    ct1 = cut_tim(0,iyr)
    ct2 = cut_tim(1,iyr)
    var1=fin->$vname$({ct1:ct2},{lat1:lat2},{lon1:lon2})
    nvtims = dimsizes(var1&time)
    if nvtims .ne. ntim_per_yr
      do it=0,nvtims-1
        itim = ind(var1&time(it) .eq. var2&time)
        var2(itim,:,:) = var1(it,:,:)
        pp(yrs(iyr)+" ... doing the loopy")
     end do
    else
      var2({ct1:ct2},:,:) = var1
    end if
    delete(var1)
    t0=t0+nvtims
  end do

  var_dims=(/ntim,nlat,nlon/)
  dim_names=(/"time","lat","lon"/)
  new_indcs=ind(var_dims.gt.1) ; chose indices of the
			     ; the input array for
                             ; which dimsize > 1
  newdims=var_dims(new_indcs)
  new_dimnames=(dim_names(new_indcs))
  ndims=dimsizes(newdims)
  newvar=new(newdims,"float")
  newvar=var2
  do i=0,ndims-1
    newvar!i=new_dimnames(i)
  end do
  if isatt(newvar,"cut_ntim")
    delete(newvar@cut_ntim)
  end if
  newvar@cut_ntim=cut_ntim
return(newvar)
end

function cut_level_data(DataDir,vname,yrs,tim,lev,lat,lon)
local ntim,nlev,nlat,nlon,lat1,lat2,tim1,tim2,lon1,lon2,nstat
begin
  nlev=dimsizes(lev)
  nlat=dimsizes(lat)
  nlon=dimsizes(lon)
  _datFreq = DataDir@dFreq
  nyrs=dimsizes(yrs)
  if (typeof(yrs) .eq. "string")
    years=(/1904/)
  else
    years=yrs
  end if
  cut_tim = new((/2,nyrs/), "double")
  cut_ntim = new(nyrs,"integer")  
  tim_axs = NewList("fifo")
  ntim=0
  do iyr = 0,nyrs-1
    if (iyr.eq.0)
      mon1=tim@mo1
      day1=tim@dy1
    else
      mon1=1
      day1=1
    end if
    if (iyr.eq.nyrs-1)
      mon2=tim@mo2
      day2=tim@dy2
    else
      mon2=12
      day2=31
    end if
    if isatt(tim,"months")
      tmp_cut_tim = months_to_cut(_datFreq,tim@months,years(iyr))
    else
      tmp_cut_tim = months_to_cut(_datFreq,(/mon1,mon2/),years(iyr))
    end if
    if (_datFreq .eq. "Daily")
      if .not. isatt(tim,"months")
        if isatt(tim,"ddmmm")
          tmp_cut_tim = ddmmm_to_cut(_datFreq,tim@ddmmm,years(iyr))
        else
          t1=sprinti("%0.2i",day1)+""+integer_to_month(mon1)
          t2=sprinti("%0.2i",day2)+""+integer_to_month(mon2)
          tmp_cut_tim = ddmmm_to_cut(_datFreq,(/t1,t2/),years(iyr))
        end if
      end if
    end if
    cut_tim(:,iyr) = tmp_cut_tim
    ntim=ntim+toint(tmp_cut_tim@ntim)
    cut_ntim(iyr) = tmp_cut_tim@ntim
    ListPush(tim_axs, tmp_cut_tim@tims)
    delete(tmp_cut_tim)
  end do
  var2=new((/ntim,nlev,nlat,nlon/),"float")
  v2tm=new(ntim,"double")
  ibeg=0
  do i=0,nyrs-1
    iend=ibeg+cut_ntim(i)-1
    v2tm(ibeg:iend) = ListPop(tim_axs)
    ibeg=iend+1
  end do
  add_dimensions(var2,(/"time","level","lat","lon"/))
  var2&lat=lat
  var2&lon=lon
  var2&time=ndtooned(v2tm)
  var2&time@units=SysE_DB_tunits()
  ntim_per_yr = ntim/nyrs

  lat1=lat(0)
  lon1=lon(0)

  lat2=lat(nlat-1)
  lon2=lon(nlon-1)

  t0=0
  do iyr=0,nyrs-1
    ct1 = cut_tim(0,iyr)
    ct2 = cut_tim(1,iyr)
   
    if typeof(yrs).eq."string"
      DataDir_yr=DataDir+"/"+vname+"_"
      nstat=vname@nstat
    else
      DataDir_yr=DataDir+yrs(iyr)+"/"+vname+"_"
     print("Now processing "+yrs(iyr)+" from "+DataDir_yr)
    end if
    do ilev=0,nlev-1
      fin=addfile(DataDir_yr+lev(ilev)+".nc","r")
      if typeof(yrs).eq."string"
        var1=fin->$vname$({ct1:ct2},nstat,{lat1:lat2},{lon1:lon2})
      else
        var1=fin->$vname$({ct1:ct2},{lat1:lat2},{lon1:lon2})
      end if
      nvtims = dimsizes(var1&time)
      if nvtims .ne. ntim_per_yr
        do it=0,nvtims-1
          itim = ind(var1&time(it) .eq. var2&time)
          var2(itim,ilev,:,:) = var1(it,:,:)
          pp("doing the loopy")
        end do
      else
        var2({ct1:ct2},ilev,:,:) = var1
      end if
    delete(var1)
    end do
  end do

  var_dims=(/ntim,nlev,nlat,nlon/)
  dim_names=(/"time","level","lat","lon"/)
  new_indcs=ind(var_dims.gt.1) ; chose indices of the
			     ; the input array for
                             ; which dimsize > 1
  newdims=var_dims(new_indcs)
  new_dimnames=(dim_names(new_indcs))
  ndims=dimsizes(newdims)
  newvar=new(newdims,"float")
  newvar=var2
  do i=0,ndims-1
    newvar!i=new_dimnames(i)
  end do
  if isdim(newvar,"level")
    newvar&level=lev ; nhs sep 5 - was not adding level info
    newvar&level@long_name="level" ; nhs sep 5
    newvar&level@units="depends"    ; nhs sep 5
  end if
  if isatt(newvar,"cut_ntim")
    delete(newvar@cut_ntim)
  end if
  newvar@cut_ntim=cut_ntim
return(newvar)
end

function retrieve_lats(fin,lat1,lat2)
begin
  lat=fin&lat
  lat!0="lat"
  lat&lat=lat
  tmp_lat=lat({lat1:lat2})
  return(tmp_lat)
end

function retrieve_lons(fin,lon1,lon2)
begin
  lon=fin&lon
  lon!0="lon"
  lon&lon=lon
  tmp_lon=lon({lon1:lon2})
  return(tmp_lon)
end

function retrieve_tims(fin)
begin
  return(fin&time)
end

function find_datalevs(DataDir,vname,lev1,lev2)
begin
  CMD="ls "+DataDir+vname+"_*.nc "
  CMD=CMD+" | awk -F"+DataDir+vname+"_ '{print $2}'"
  CMD=CMD+" | awk -F. '{print $1}'"
  file_levs=stringtofloat(systemfunc(CMD))
  qsort(file_levs)
  file_levs!0="levs"
  file_levs&levs=file_levs
  my_levs=file_levs({lev1:lev2})
  return(my_levs)
end

procedure check_timespecs(fin1,fin2,start_time,end_time)
begin
  time_of_first_data=fin1&time(0)
  tmp_time=fin2&time
  time_of_last_data=tmp_time(dimsizes(tmp_time)-1)
  if time_of_last_data.lt.end_time
    print("Data request exceeds data collection :")
    print("Last date available is  "+ut_calendar(time_of_last_data,-2))
    print("You requested data upto "+ut_calendar(end_time,-2))
    print("Please revise request and try again : eXiT")
    exit
  end if

  if time_of_first_data.gt.start_time
    print("Data request exceeds data collection :")
    print("First date available is  "+ut_calendar(time_of_first_data,-2))
    print("You requested data from  "+ut_calendar(start_time,-2))
    print("Please revise request and try again : eXiT")
    exit
  end if
end


function CMS_RetrieveData(org_DataDir,vname,domain)
begin
  DataDir=org_DataDir

  ; The default settings.
  ; We discover the ranges of these 4 dimensions
  ; by parsing the user requests.

  nlat=0
  nlon=0
  nlev=0
  nyrs=0

  if isatt(domain,"lat1")
    lat1=domain@lat1
    lat2=domain@lat2
    if lat1.eq.lat2
      nlat=1 ; if nlat=0 exit; at least one latitude be specified
    else
      nlat=2
    end if
  end if

  if isatt(domain,"lon1")
    lon1=domain@lon1 ; nlon should not be zero, if zero we exit
    lon2=domain@lon2
    if lon1.eq.lon2
      nlon=1
    else
      nlon=2
    end if
  end if

  nlev=0 ; Default
  vnam2=vname
  if isatt(domain,"lev1")
    lev1=stringtofloat(domain@lev1)
    lev2=stringtofloat(domain@lev2)
    nlev=1 ; nlev can be zero, because some data do not have level info
    vnam2=vname+"_"+lev1
  end if

  DataDir=DataDir+"/"+domain@DataFreq+"/"+domain@DataType+"/"
  DataDir@dFreq=domain@DataFreq

  if .not. ncl_file_exists(DataDir)
    abort("The directory "+DataDir+" is not available")
  end if

  if domain@DataType.eq."Climatology"
    file_yrs="0"
    nstat=domain@nstat
  else
    file_yrs=stringtoint(systemfunc("ls "+DataDir))
  end if

    tim1=stringtochar(domain@tim1)
    tim2=stringtochar(domain@tim2)
    nsiz=sizeof(tim1)-1
    if nsiz.lt.8 .or. nsiz.gt.9
      print("Error in Time specification")
      print("Time to be specified as ddMONyyyy, e.g. 20Jan2006")
      print("However current time is provided as "+domain@tim1)
      print("eXiT")
      exit
    end if
    yr1=stringtoint(chartostring(tim1(nsiz-4:nsiz-1)))
    smo1=str_upper(chartostring(tim1(nsiz-7:nsiz-5)))
    dy1=stringtoint(chartostring(tim1(:nsiz-8)))

    nsiz=sizeof(tim2)-1
    yr2=stringtoint(chartostring(tim2(nsiz-4:nsiz-1)))
    smo2=str_upper(chartostring(tim2(nsiz-7:nsiz-5)))
    dy2=stringtoint(chartostring(tim2(:nsiz-8)))

    mo1=integer_value_of_month(smo1)
    mo2=integer_value_of_month(smo2)

    tunits=SysE_DB_tunits() 

  if typeof(file_yrs).eq."integer"  ; except for climatology

    if yr1.lt. min(file_yrs) .or. yr2.gt.max(file_yrs)
      print("Prescribed Year not in Data Base")
      print("This could be either "+yr1+" or "+yr2)
      exit
    else
      nyrs=yr2-yr1+1
      my_yrs=yr1+nyrs-1
    end if

; Check for consistent specification

    if nlat.eq.0 .or. nlon.eq.0 .or. nyrs.eq.0
      print("At least one latitude, longitude and time point to be specified")
      print("Current specs are given below: ")
      printVarSummary(domain)
      exit
    end if
  end if

  if nlat.eq.0 .or. nlon.eq.0 
    print("At least one latitude and longitude point to be specified")
    print("Current specs are given below: ")
    printVarSummary(domain)
    exit
  end if

  _datFreq=domain@DataFreq
  allowed_data_freqs=(/"Daily","Monthly","Yearly"/)

  ; we define monthly data to be located at mid-month
  if _datFreq.eq."Monthly"
    dy1=15
    dy2=15
  end if

  if typeof(file_yrs).eq."integer" ; true except for climatology
    start_time=ut_inv_calendar(yr1,mo1,dy1,0,0,0,tunits,0)
    end_time=ut_inv_calendar(yr2,mo2,dy2,0,0,0,tunits,0)

    data_tim = True
    data_tim@mo1=mo1
    data_tim@mo2=mo2
    data_tim@dy1=dy1
    data_tim@dy2=dy2

    if .not.any(allowed_data_freqs.eq._datFreq)
      terminate_program("DataFreq of "+_datFreq+" not allowed")
    end if

    if isatt(domain,"months")
      data_tim@months=domain@months
    end if
    if isatt(domain,"ddmmm")
      data_tim@ddmmm=domain@ddmmm
    end if
  else ; this is for climatology file
    if (nlev .eq. 0)
      if isatt(domain,"months")
        cut_tim = months_to_cut(_datFreq,domain@months,1904)
      else
        cut_tim = months_to_cut(_datFreq,(/1,12/),1904)
      end if
      if (_datFreq .eq. "Daily")
        if .not. isatt(domain,"months")
          if isatt(domain,"ddmmm")
            cut_tim = ddmmm_to_cut(_datFreq,domain@ddmmm,1904)
          else
            cut_tim = ddmmm_to_cut(_datFreq,(/"01Jan","31Dec"/),1904)
          end if
        end if
      end if
    end if
  end if
  ; Parse the time and find starting and ending time
 
  if typeof(file_yrs).eq."integer"
    DataDir_y1=DataDir+yr1+"/"
  else
    DataDir_y1=DataDir+"/"
  end if

  if nlev.ge.1  		; we are looking at Level Data
    ; Find if data for specified level is available
    data_lev=find_datalevs(DataDir_y1,vname,lev1,lev2)
    ;nlev=dimsizes(data_lev)
  
    if typeof(file_yrs).eq."integer"
      fin1=addfile(DataDir+yr1+"/"+vname+"_"+data_lev(0)+".nc","r")
      fin2=addfile(DataDir+yr2+"/"+vname+"_"+data_lev(0)+".nc","r")
      check_timespecs(fin1,fin2,start_time,end_time)
    else
      fin1=addfile(DataDir+"/"+vname+"_"+data_lev(0)+".nc","r")
    end if

    data_lat=retrieve_lats(fin1,lat1,lat2)
    data_lon=retrieve_lons(fin1,lon1,lon2)
    nlat=dimsizes(data_lat)
    nlon=dimsizes(data_lon)

    if typeof(file_yrs).eq."integer"
      years=ispan(yr1,yr2,1)
      var=cut_level_data(DataDir,vname,years,data_tim,data_lev,data_lat,data_lon)
    else ; this is for climatology, put years=1904
      data_tim= True ;retrieve_tims(fin1)
      if isatt(domain,"months")
        data_tim@months=domain@months
      end if
      if isatt(domain,"ddmmm")
        data_tim@ddmmm=domain@ddmmm
      end if

      data_tim@mo1=mo1
      data_tim@mo2=mo2
      data_tim@dy1=dy1
      data_tim@dy2=dy2

      years="null"
      vname@nstat=nstat
      var=cut_level_data(DataDir,vname,years,data_tim,data_lev,data_lat,data_lon)
    end if
  else
    if typeof(file_yrs).eq."integer"
      fin1=addfile(DataDir+yr1+"/"+vname+".nc","r")
      fin2=addfile(DataDir+yr2+"/"+vname+".nc","r")
      check_timespecs(fin1,fin2,start_time,end_time)
    else
      fin1=addfile(DataDir+"/"+vname+".nc","r")
    end if
    data_lat=retrieve_lats(fin1,lat1,lat2)
    data_lon=retrieve_lons(fin1,lon1,lon2)
    nlat=dimsizes(data_lat)
    nlon=dimsizes(data_lon)

    if typeof(file_yrs).eq."integer"
      years=ispan(yr1,yr2,1)
      var=cut_data(DataDir,vname,years,data_tim,data_lat,data_lon)
    else
      var=fin1->$vname$({cut_tim(0):cut_tim(1)},nstat,{lat1:lat2},{lon1:lon2})
    end if
  end if
  return(var)
end
 
procedure space_remover(val)
; remove empty spaces from a string
begin
  tmp=val
  val=systemfunc("echo "+tmp+" | tr -d [:blank:]")
end

procedure CMS_subsetter(val1,val2,vals)
; subroutine that will map a 2-element
; domain array specification into 
; the two domain boundaries
begin
  nvals=dimsizes(vals)
  val1=vals(0)
  if nvals.eq.1
  val2=val1
  else
  val2=vals(1)
  end if

  if typeof(vals).eq."string"
  space_remover(val1)
  space_remover(val2)
  end if

  if  isatt(vals,"DEBUG")
    print(val1+" -- "+val2)
  end if
end

procedure debug_checker(opt,vals)
begin
  if isatt(opt,"DEBUG")
    vals@DEBUG=True
  else
    vals@DEBUG=False
  end if
end



function CMS_getdata(opt)

; Plotting routine requests data through this
; interface.
; The routine can specify
; Data Source, Data period, Data type , Data domain etc. as
; attributes to a logical variable.

; Sample usage:
; opt@Lat=(/-30,30/) ; we need domain specs because we may plot
; opt@Lon=(/40,120/) ; hovmoeller diagrams and it will be efficient
; opt@Lev=(/300,500/); to retrieve subsets instead of huge domains
; opt@Time=(/19Jan2006,20Mar2007/)
; opt@DataSource="TMI"
; opt@Variable="sst"
; opt@DataType="interannual anomalies" ; band-passed anoms at a particular day
; opt@DataType="intraseasonal anomalies"; band-passed anoms at a particular day
; opt@DataType="monthly anomalies"; raw anomalies averaged for the requested period
; opt@DataType="seasonal anomalies"; raw anomalies averaged for requested period
; opt@DataType="weekly anomalies"; raw anomalies averaged for requested period
; opt@DataType="climatology"; climatology averaged for requested period


; Our maps are 7-day, monthly and 90-day
begin

   domain=True
   ;anomaly_types=(/"monthly","seasonal","weekly"/)+"anomalies"

; Determine which DataType to use
; Account for inconsistencies of user input related to case
; and spaces.

  domain@DataType="Anomaly" ; default data type 
                          ; defaulted to if nothing is specified
                          ; or opt@DataType is any of
                          ; monthly weekly or seasonal anomalies
  domain@DataFreq=str_capital(str_lower(opt@DataFreq))

  if isatt(opt,"DataType")
    opt@DataType=str_lower(opt@DataType)
    space_remover(opt@DataType)

    if opt@DataType.eq."mean"
      domain@DataType="Mean"
    end if

    if opt@DataType.eq."intraseasonalanomalies"
      domain@DataType="ISV"
    end if

    if opt@DataType.eq."climatology"
      domain@DataType="Climatology"
      ostat=opt@Statistic
      ostat=str_lower(ostat)
      if ostat.eq."mean"
        domain@nstat=0
      end if
      if ostat.eq."stddev"
        domain@nstat=1
      end if
    end if

    if opt@DataType.eq."lanom"
      domain@DataType="LAnom"
    end if

    if opt@DataType.eq."intanom"
      domain@DataType="Intanom"
    end if
  end if

  if isatt(opt,"months")
    if (typeof(opt@months) .eq. "string")
      domain@months=(month_to_int(opt@months))
    else
      domain@months=(opt@months)
    end if
  end if
  if isatt(opt,"ddmmm")
    if typeof(opt@ddmmm) .ne. "string"
      abort("opt@ddmm should be a string, e.g, opt@ddmmm=(/'01Jan','15Feb'/)")
    end if
    domain@ddmmm = opt@ddmmm
  end if

  if (opt.and.isatt(opt,"Lat")) then
    lats=opt@Lat
    debug_checker(opt,lats)
    domain@lat1=1.0
    domain@lat2=1.0
    CMS_subsetter(domain@lat1,domain@lat2,lats)
  end if

  if (opt.and.isatt(opt,"Lon")) then
    lons=opt@Lon
    domain@lon1=1.0
    domain@lon2=1.0
    debug_checker(opt,lons)
    CMS_subsetter(domain@lon1,domain@lon2,lons)
  end if

  if (opt.and.isatt(opt,"Time")) then
    tims=opt@Time
    domain@tim1="1"
    domain@tim2="1"
    debug_checker(opt,tims)
    CMS_subsetter(domain@tim1,domain@tim2,tims)
  end if

  if (opt.and.(isatt(opt,"Lev") .or. isatt(opt,"lev"))) then
    levs=opt@Lev
    domain@lev1="1"
    domain@lev2="1"
    debug_checker(opt,levs)
    CMS_subsetter(domain@lev1,domain@lev2,levs)
  end if

  opt@DataSource=str_upper(opt@DataSource)
  vname=str_lower(opt@Variable)
  vname@Access="Local"
  if isatt(opt,"Lev") 
    vname@Lev=opt@Lev
  end if 

  DataDir=opt@DataBaseDir+"/"+opt@DataSource+"/"
  var=CMS_RetrieveData(DataDir,vname,domain) ; opens all the directories
  return(var)
end

function slice_data(sopt)
begin
  opt=True
  opt@Variable=sopt@vname
  opt@DataSource=sopt@DataSource
  if isatt(sopt,"Time")
    opt@Time=sopt@Time
  end if
  if isatt(sopt,"Lat")
    opt@Lat=sopt@Lat
  else
    opt@Lat=(/-90,90/)
  end if
  if isatt(sopt,"Lon")
    opt@Lon=sopt@Lon
  else
    opt@Lon=(/0,360/)
  end if

; Optional Parameters
  if isatt(sopt,"Lev")
    opt@Lev=sopt@Lev
  end if
  if isatt(sopt,"lev")
    opt@Lev=sopt@lev
  end if

  if isatt(sopt,"months")
    opt@months=sopt@months
  end if
  if isatt(sopt,"ddmmm")
    if isatt(sopt,"months")
      delete(opt@months)
    end if
    opt@ddmmm=sopt@ddmmm
  end if
  
  if isatt(sopt,"DataType")
    opt@DataType=sopt@DataType
    if opt@DataType.eq."Climatology"
      if isatt(sopt,"Statistic")
        opt@Statistic=sopt@Statistic
      else
        opt@Statistic="Mean"
      end if
    end if
  else
    opt@DataType="Anomalies"
  end if

  if isatt(sopt,"DataFreq")
    opt@DataFreq=sopt@DataFreq
  else
    opt@DataFreq="Daily"
  end if

  if isatt(sopt,"DataRoot")
    opt@DataBaseDir=sopt@DataRoot
  end if


; Data is retrieved using a complex algorithm
  vdat=CMS_getdata(opt)

; Find no of dimensions to average
nave=0
dstring=""

if isatt(sopt,"TimAve")
  if sopt@TimAve
    nave=nave+1
    dstring=dstring+"tim"
  end if
end if
if isatt(sopt,"tim_ave")
  if sopt@tim_ave
    nave=nave+1
    dstring=dstring+"tim"
  end if
end if

if isatt(sopt,"LevAve")
  if sopt@LevAve
    nave=nave+1
    dstring=dstring+"lev"
  end if
end if

if isatt(sopt,"LatAve")
  if sopt@LatAve
    nave=nave+1
    dstring=dstring+"lat"
  end if
end if

if isatt(sopt,"LonAve")
  if sopt@LonAve
    nave=nave+1
    dstring=dstring+"lon"
  end if
end if


; Strategy 1: Assume that the request is correct 
;             a - Find the dimensions to average
;             b - Find the number of dimensions of retrieved data
;             c - create a string array to hold the re-ordered dimensions
;             d - at the end of the new array, put the dimensions we have to 
;                 average
;             e - for the other positions, do an iterative search


;Find the dimensions we have to average

; dstring consists of dimension names
; specified as 3-letter words, such as lev, lat, lon and tim

if nave.gt.0
  cdstring=stringtochar(dstring)
  ndstring=nave ; no of dimensions to average


  my_dstring=new(ndstring,"string")

  ; create an array my_dstring to sort out the dimensions
  ; in the right order
  ik=0
  do is=0,ndstring-1
  my_dstring(is)=chartostring(cdstring(ik:ik+2))
  ik=ik+3
  end do

  Std_dimensions=(/"time","level","lat","lon"/)
  Abr_dimensions=(/"tim","lev","lat","lon"/)


  DimsToAve=new(ndstring,string) ; Map into real dimension names

  do is=0,ndstring-1
    do ks=0,3
       DimsToAve(is)=Std_dimensions(ks)
       if Abr_dimensions(ks).eq.my_dstring(is)
         break
       end if
    end do
  end do

;  print(DimsToAve)


; Find the dimensions of the retrieved data
  data_dims=getvardims(vdat)
  nrank=dimsizes(data_dims)

ndiff=nrank-nave
if ndiff.le.0
print("You are asking for the ridiculous : eXiT")
exit
end if

ReorderedDims=new(nrank,"string")
ReorderedDims(nrank-ndstring:)=DimsToAve


; Now fill up the remaining of the ReorderedDims with
; the appropriate dimensions

ncount=ndiff
do it=0,ndiff-1
  do is=0,nrank-1
       if any( data_dims(is).eq.ReorderedDims(ncount:) )
       continue
       end if
       ReorderedDims(ncount-1)=data_dims(is)
  end do
ncount=ncount-1
end do


;if ndiff.lt.1 .or. ndiff.gt.2 
;  print("We need either 2-D or 1-D data")
;  print("The resulting dimension will be "+ndiff)
;  print("eXiT")
;  exit
;end if


; How to re-order co-ordinate variables
; and then to use the right averaging routine
; if nave=1, use dim_avg
; if nave=2, use wgt_areaave
; if nave=3, use wgt_volave
; dims=(/"time","lat","lon"/)
; var=vdat($dims(1)$|:,$dims(2)$|:,$dims(0)$|:)
; printVarSummary(var)

  dims=ReorderedDims
  if nrank.eq.4
  var1=vdat($dims(0)$|:,$dims(1)$|:,$dims(2)$|:,$dims(3)$|:)
  end if

  if nrank.eq.3
  var1=vdat($dims(0)$|:,$dims(1)$|:,$dims(2)$|:)
  end if

  if nrank.eq.2
  var1=vdat($dims(0)$|:,$dims(1)$|:)
  end if

  if nrank.eq.1
  var=vdat
  end if

    if nave.eq.3
    var=wgt_volave(var1,1,1,1,0)
    end if

    if nave.eq.2
    var=wgt_areaave_Wrap(var1,1,1,0)
    end if

    if nave.eq.1
    var=dim_avg_Wrap(var1)
    end if
 
else
var=vdat
end if

return(var)
end

function get_from_file(fname)
begin
  fin=fopen_read(fname)
  return(fin->var)
end
procedure write_to_file(var,fname)
begin
  fot=fopen_write(fname)
  if isatt(fname,"vname")
   vnm = fname@vname
   fot->$vnm$ = var
  else
    fot->var=var
  end if
end
function write_meta_to_file(options,fname)
local fopt,opts
begin
  fopt=1
  opts = getvaratts(options)
  nopt = dimsizes(opts)
  do i = 0,nopt-1
    tmp = options@$opts(i)$
    if typeof(tmp) .eq. "string" .and. (dimsizes(tmp) .ge. 2)
      fopt@$opts(i)$ = array_join(tmp,",")
    else
      fopt@$opts(i)$ = tmp
    end if
    delete(tmp)
  end do
  fname@vname="fopt"
  write_to_file(fopt,fname)
  return(True)
end

function check_cache_status(fnam,opt)
begin
  fin   = fopen_read(fnam)
  fopt  = fin->fopt
  atts  = getvaratts(opt)
  natt  = dimsizes(atts)
  fatts = getvaratts(fopt)
  nfatt = dimsizes(fatts)
  ; First check - number of atts should match
  if (nfatt .ne. natt)
    return(False)
  else  
    pp("Cache_Check :: Number of attributes match")
  end if
  ; Second check - the att names should be the same
  check2 = new(nfatt,logical)
  do i = 0,nfatt-1
    check2(i) = any(atts .eq. fatts(i))
  end do
  if (all(check2))
    pp("Cache_Check :: Attribute names match")
  else
    pp("Cache_Check :: Attribute names do not match with cached version")
    return(False)
  end if
  ; Final check - att values should match
  check3 = new(nfatt,logical)
  do i = 0,nfatt-1
    tmp = opt@$fatts(i)$
    if typeof(tmp) .eq. "string" .and. (dimsizes(tmp) .ge. 2)
      topts = array_join(tmp,",")
    else
      topts = tmp
    end if
    check3(i) = all(topts .eq. fopt@$fatts(i)$)
    delete(tmp)
    delete(topts)
  end do
  if (all(check3))
    pp("Cache_Check :: Final check passed")
  else
    pp("Cache_Check :: Attribute values do not match with cached version")
    return(False)
  end if
  return(True)
end
function cache_clean(fnam,mfnam,opt)
local cache_status
begin
  cache_status=False
  if (isfilepresent(fnam) .and. isfilepresent(mfnam))
    cache_status = check_cache_status(mfnam,opt)
  else
    pp("Cache_Check :: will get from SysE_DB")
  end if
  return(cache_status)
end
function slice_data_cached(sopt)
local fname, fout
begin
  if .not. isatt(sopt,"LocalFile")
    terminate_program("This needs an option - LocalFile (name of local file)")
  end if
  fname=sopt@LocalFile
  mfname=".syse_meta/"+fname
  system("mkdir -p .syse_meta")
  if cache_clean(fname,mfname,sopt)
    pp("Getting data from cache "+fname)
    var=get_from_file(fname)
  else
    var=slice_data(sopt)
    pp("Writing to cache "+fname)
    rm_file_if_present(fname)
    write_to_file(var,fname)
    pp("Storing metadata")
    rm_file_if_present(mfname)
    res=write_meta_to_file(sopt,mfname)
  end if
  return(var)
end

function findFirstTimeOfCollection(DataDir)
begin
  years=systemfunc("ls "+DataDir)
  year=stringtoint(years(0))
  ;print("The year "+year+" is the first year")

  MeanDir=DataDir+"/"+year
  files=systemfunc("ls "+MeanDir+"/*.nc")
  fin=addfile(files(0),"r")
  torig=fin->time
  ntim0=dimsizes(torig)
  tfirst=torig(0)
  tnarr=ut_calendar(tfirst,0)
  y0=floattoint ( tnarr(0,0) )
  m0=floattoint ( tnarr(0,1) )
  d0=floattoint ( tnarr(0,2) )
  firstTime=(/y0,m0,d0/)
  firstTime@join=","
  return(array_to_string(firstTime))
end
function findLastTimeOfCollection(DataDir)
begin
  years=systemfunc("ls "+DataDir)
  nyrs = dimsizes(years)
  year=stringtoint(years(nyrs-1))
  ;print("The year "+year+" is the last year")

  MeanDir=DataDir+"/"+year
  files=systemfunc("ls "+MeanDir+"/*.nc")
  fin=addfile(files(0),"r")
  torig=fin->time
  ntim0=dimsizes(torig)
  tlast=torig(ntim0-1)

  tnarr=ut_calendar(tlast,0)
  y0=floattoint ( tnarr(0,0) )
  m0=floattoint ( tnarr(0,1) )
  d0=floattoint ( tnarr(0,2) )
  lastTime=(/y0,m0,d0/)
  lastTime@join=","
  return(array_to_string(lastTime))
end

function cms_read_trend(root,src,vname)
begin
  opt=True
  opt@vname="t_"+vname
  opt@DataRoot=root
  opt@DataSource=src
  opt@DataFreq="Monthly"
  opt@DataType="Climatology"
  opt@Statistic="mean"
  v_trend=slice_data(opt)
  return(v_trend)
end
