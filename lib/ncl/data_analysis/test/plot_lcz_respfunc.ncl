function plot_resp(wks,lcz_fil,dt,res,opt)
begin
  lcz_res = lcz_fil@resp(1:)
  lcz_per = dt/(lcz_fil@freq(1:))
  res@tmXUseBottom  = False
  res@trXMinF       = min(lcz_per)
  res@tmXTOn = True
  res@tmXTMode = "Explicit"
  res@tmXTValues = opt@top_val
  res@tmXTLabels    = opt@top_lab
  res@tmXTLabelsOn = True

  res@gsnYRefLine = 0.5
  plot=gsn_csm_xy(wks,lcz_per,lcz_res,res)
  return(plot)
end
