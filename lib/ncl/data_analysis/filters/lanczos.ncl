procedure lcz_message(nwt,fil_typ)
begin
  pp("Creating "+nwt+" weights for a "+fil_typ+"pass Lanczos filter")
end
function lcz(nwt,ihp,fca,fcb,nsigma)
begin
  return(filwgts_lanczos(nwt,ihp,fca,fcb,nsigma))
end

function lcz_high(nwt,fc,nsigma)
begin
  return(lcz(nwt,1,fc,-999.,nsigma))
end
function lcz_low(nwt,fc,nsigma)
begin
  return(lcz(nwt,0,fc,-999.,nsigma))
end
function lcz_band(nwt,fca,fcb,nsigma)
begin
  return(lcz(nwt,2,fca,fcb,nsigma))
end

function band_filter(low,hig,dt,opt)
begin
  ; low = low cutoff in the units of the time coordinate
  ; hig = hig cutoff in the units of the time coordinate
  ; dt = no of time units per time interval
  fca = dt/low
  fcb = dt/hig
  ; need to check the following and implement
  ;if (1.0/fca .le. low) .or. (1.0/fcb .ge. hig)
  ;  pp(low+">="+(1.0/dt))
  ;  pp(hig+"<="+(1.0/fcb))
  ;  abort("Modify the cutoff points and try again")
  ;end if
  nsigma = 1
  if fca .gt. fcb
    tmp = fca
    fca = fcb
    fcb = tmp
  end if
  nwt = toint(1.0/fca)
  if isatt(opt,"xwt")
    nwt = nwt*opt@xwt
  end if
  if is_even(nwt)
    nwt=nwt+1
  end if
  lcz_message(nwt,"band")
  return(lcz_band(nwt,fca,fcb,nsigma))
end
function low_filter(low,dt,opt)
begin
  ; low = low cutoff in the units of the time coordinate
  ; hig = hig cutoff in the units of the time coordinate
  ; dt = no of time units per time interval
  fca = dt/low
  nsigma = 1
  nwt = toint(1.0/fca)
  if isatt(opt,"xwt")
    nwt = nwt*opt@xwt
  end if
  if is_even(nwt)
    nwt=nwt+1
  end if
  lcz_message(nwt,"low")
  return(lcz_low(nwt,fca,nsigma))
end
function hig_filter(hig,dt,opt)
begin
  ; low = low cutoff in the units of the time coordinate
  ; hig = hig cutoff in the units of the time coordinate
  ; dt = no of time units per time interval
  fcb = dt/hig
  nsigma = 1
  nwt = toint(1.0/fcb)
  if isatt(opt,"xwt")
    nwt = toint(nwt*opt@xwt)
  end if
  if is_even(nwt)
    nwt=nwt+1
  end if
  lcz_message(nwt,"high")
  return(lcz_high(nwt,fcb,nsigma))
end
