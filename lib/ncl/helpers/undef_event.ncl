function undef_event(var,fdat,ldat)
; given an event identified as a variation
; between two specified time points
; this function undefines the variable during
; the specified time interval
; e.g. fdat = (/2006,6,1/)
;      ldat = (/2007,3,1/)
begin
  ans = reorder_or_not(var)
  if ans
    new_var = ensure_first_dim(var,"time")
  else
    new_var = var
  end if
  time=var&time
  tunits=time@units
  date_template=time(0)
  sdat=inject_to_date_template(fdat,date_template)
  edat=inject_to_date_template(ldat,date_template)
  slice=daterange_to_timerange(sdat,edat,tunits)
  vrnk = rank_of(var)
  if vrnk .eq. 1
    new_var({slice(0):slice(1)}) = var@_FillValue
  end if
  if vrnk .eq. 2
    new_var({slice(0):slice(1)},:)=var@_FillValue
  end if
  if vrnk .eq. 3
    new_var({slice(0):slice(1)},:,:)=var@_FillValue
  end if
  if vrnk .eq. 4
    new_var({slice(0):slice(1)},:,:,:)=var@_FillValue
  end if
  if ans
    return(reorder_dims_as_in_template(var,new_var))
  else
    return(new_var)
  end if
end
