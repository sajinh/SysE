undef("stdDayTLL")
function stdDayTLL (x[*][*][*]:numeric, yyyyddd:integer)   
;
; calculate the standard deviation of the Annual Cycle from daily data. 
; The return array will gave the raw standard deviation at each grid point
;
;              x(time,lat,lon)  <==== input dimension order
;              x!0 = "time"     <==== time is in days
;              x!1 = "lat"
;              x!2 = "lon"
;
;    non-Leap  yyyyddd
;              1905001 =>  Jan  1, 1905
;              1905032 =>  Feb  1, 1905
;              1905059 =>  Feb 28, 1905
;              1905060 =>  Mar  1, 1905
;              1905365 =>  Dec 31, 1905
;
;    Leap
;              1908001 =>  Jan  1, 1908]
;              1908032 =>  Feb  1, 1908]
;              1908059 =>  Feb 28, 1908]
;              1908060 =>  Feb 29, 1908]
;              1908061 =>  Mar  1, 1908]
;              1908366 =>  Dec 31, 1908]
;
; Usage:  xStdDay = stdDAY_TLL (x, yyyyddd)
; -------

local dimx, ntim, nlat, mlon, ndys, days, stdDay, ndy, indx, year_day, nFill
begin

   dimx  = dimsizes (x)

   ntim  = dimx(0)
   nlat  = dimx(1)
   mlon  = dimx(2)
   ndys  = 366                                     ; allow for leap year

   days  = yyyyddd - (yyyyddd/1000)*1000           ; strip year info [yyyy]

   stdDay= new((/ndys,nlat,mlon/),typeof(x), getFillValue(x) ) ; daily standard deviation
;
; Compute averages for each sequential day of the year. 
; This uses dimension swapping.
;
   do ndy=0,ndys-2                                 ; ndy=0->364 ==> day of year 1->365       
      indx = ind( days.eq.(ndy+1) )                ; indx:indx Mar 2012, handle 1 element
      if (.not.ismissing(indx(0))) then
          nindx = dimsizes(indx)
        if (nindx.eq.1) then                       ; force 3rd dimension
         ;stdDay(ndy,:,:) = dim_stddev(x(lat|:,lon|:,time|indx:indx))
          stdDay(ndy,:,:) = dim_stddev_n(x(indx:indx,:,:), 0) ; 5 Nov 2009 => dim_avg_n
        else
         ;stdDay(ndy,:,:) = dim_stddev(x(lat|:,lon|:,time|indx))
          stdDay(ndy,:,:) = dim_stddev_n(x(indx,:,:), 0)  ; 5 Nov 2009 => dim_avg_n
        end if
      end if
      delete(indx)                  
   end do
                                                   ; nominal day 366 
                                                   ; ave(31 Dec + 1 Jan)=leap
   stdDay(ndys-1,:,:) = (stdDay(0,:,:) + stdDay(ndys-2,:,:))*0.5

   nFill = num(ismissing(stdDay))
   if (nFill.eq.0) then
       delete(stdDay@_FillValue)
   end if

   stdDay@long_name   = "Daily Standard deviation"
   if (isatt(x,"long_name")) then
       stdDay@long_name = stdDay@long_name +": "+x@long_name
   end if
   if (isatt(x,"units")) then
       stdDay@units     = x@units
   end if
   stdDay@information = "Raw daily standard deviation across all years"
   stdDay@smoothing   = "None"

   year_day           = ispan(1,ndys,1)
   year_day@long_name = "day of year"
   year_day@units     = "ddd"

   stdDay!0           = "year_day"
   stdDay&year_day    =  year_day
   
   copy_VarCoords(x(0,:,:), stdDay(0,:,:))   ; trick
   delete(stdDay@year_day)                   ; clean up
 
   return (stdDay)
end

; =====================================
