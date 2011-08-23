external HAR "$SysE/lib/ncl/data_analysis/fortran/shared/ann_cycle.so"

procedure find_t1t2(y1,m1,d1,y2,m2,d2,time,t1,t2)
local y1,y2,m1,m2,d1,d2,time,t1,t2,tunits,tim1,tim2
; input to this procedure is the two end points
; of a time range. The end points are provided in
; terms of year, month and day
; The procedure expects to be given a unit of time
; for example "days since 1900-01-01"
; The procedure outputs the integer time values in the
; given unit corresponding to the two end points provided
begin
  tunits=time@units
  tim1=ut_inv_calendar(y1,m1,d1,0,0,0,tunits,0)
  tim2=ut_inv_calendar(y2,m2,d2,0,0,0,tunits,0)
  t1=ind(time.eq.tim1)
  t2=ind(time.eq.tim2)
  print("Time indices are - "+t1+" and "+t2)
end

function constructed_anncycle(ssta, nhar)
; provide the input data with co-ordinates named and ordered time, lat and lon
; this function returns the annual cycle of the data
; the annual cycle is constructed from the specified number of harmonics
; the annual harmonics are calculated using an external fortran
; routine
local ntims,nlon,nlat,sst1,indx,nmd,sst2,ilen,nxdim \
      , sst3, low, ssta
begin
  ntims = dimsizes(ssta&time)
  nlon=dimsizes(ssta&lon)
  nlat=dimsizes(ssta&lat)

  sst1=ndtooned(ssta); Collapse sst into a 1-D array
  indx=ind(.not.ismissing(sst1)) ; collect indices of valid data
  nmd=dimsizes(indx)

  sst2=new(nmd,typeof(ssta)) ; 1-D array
  sst2=sst1(indx)           ; with valid data

  ilen=366
  nxdim=nmd/ntims
  sst3=new((/ilen,nxdim/),typeof(sst2))
  low=sst3

  HAR::ann_harm(nhar,sst2,nmd,sst3,low,ntims,nxdim,ilen)
  sst1(indx)=sst2
  ssta=onedtond(sst1,(/ntims,nlat,nlon/))

  return (ssta)
end
