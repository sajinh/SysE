function syse_make_comp_anom(src,vnm,lat,lon,yrs,opt)
; Assumptions: 
;      1. Monthly anomalies are requested
;      2. Data is available in syse_db
begin
  sopt = True
  months = (/1,12/)
  ; By default, data from Jan to Dec is returned, but you can ask
  ; for more or less as needed by using opt@months
  if isatt(opt,"months")
    months = opt@months
  end if

  smon = months(0)
  emon = months(1)
  if emon .gt. 12
    rem = mod(emon,12)
    emon = rem
    if rem .eq. 0
      emon = 12
    end if
  end if
  tim0 = (/"01"+integer_to_month(smon),"15"+integer_to_month(emon)/)

  nyr = dimsizes(yrs)
  do iyr = 0,nyr-1
    yr = yrs(iyr)
      tim = tim0+yr
    if months(1) .gt. 12
      yadd = toint(floor((months(1)-1)/12))
      pp(yadd)
      tim = (/ tim0(0)+yr, tim0(1)+(yr+yadd) /)
    end if
    var = syse_get_mon_anom(src,vnm,lat,lon,tim,sopt)
    if (iyr .eq. 0)
      var_cmp = var
    else
      var_cmp = (/ var_cmp + var /)
    end if
  end do

  var_cmp = (/var_cmp/nyr*1.0/)
  return(var_cmp)
end
