load "$SysE/lib/ncl/helper_libs.ncl"

vname="sst"

opt=1
opt@fin=1
opt@chai=(/-90,90/)
opt@$vname$=1

atts=getvaratts(opt)
natt=dimsizes(atts)
fname="test.nc"
rm_file_if_present(fname)
fout=fopen_write(fname)
fout->opt=opt
