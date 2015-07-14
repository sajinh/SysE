load "$SysE/lib/ncl/helper_libs.ncl"

fname="test.nc"
fin = fopen_read(fname)
fopt=fin->opt
;atts=getfilevaratts(fin,"opt")
atts=getvaratts(fopt)
opt=True
opt@fin=1
opt@chai=(/-90,90/)
opt@sst=1
oatts=getvaratts(opt)
noatts=dimsizes(oatts)
check=new(noatts,"logical")
do i = 0,noatts-1
  check(i) = all((fopt@$oatts(i)$) .eq. (opt@$oatts(i)$)) 
end do
pp(check)

