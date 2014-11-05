load "$SysE/lib/ncl/helper_libs.ncl"
load "$SysE/lib/ncl/data_analysis/filters/lanczos.ncl"
load "./plot_lcz_respfunc.ncl"

fopt=True
fopt@xwt=2
; Assume yearly data and filter cutoffs expressed in years
; hence dt=1/1.0

dt = 1.0/1.0 ; no of years per time step
dec1_fil = low_filter(18,dt,fopt)
dec2_fil = band_filter(5,20,dt,fopt)
int_fil = band_filter(2,10,dt,fopt)

PTYP="x11"
PNAM="test_lanczos"
colormap="rainbow"
wks=open_wks(PTYP,PNAM,colormap)
res=True
opt=True
nodraw(res)
noframe(res)
res@trXLog              = True  
opt@top_lab = (/40,20,10,7,5,3,2,1/)
opt@top_val = opt@top_lab


plot1=plot_resp(wks,dec1_fil,dt,res,opt)
plot2=plot_resp(wks,dec2_fil,dt,res,opt)
plot3=plot_resp(wks,int_fil,dt,res,opt)

gsn_panel(wks,(/plot1,plot2,plot3/),(/3,1/),True)
